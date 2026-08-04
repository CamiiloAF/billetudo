import 'package:injectable/injectable.dart';

import '../../domain/entities/sync_operation.dart';
import '../models/sync_retry_record.dart';
import 'sync_error_classifier.dart';
import 'sync_retry_ledger_store.dart';

/// What the watchdog decided about one failed operation.
class SyncRetryVerdict {
  const SyncRetryVerdict({
    required this.shouldQuarantine,
    required this.attempts,
    required this.stuckFor,
  });

  /// The failure was pure connectivity: nothing was counted, retry forever.
  const SyncRetryVerdict.notCounted()
      : shouldQuarantine = false,
        attempts = 0,
        stuckFor = Duration.zero;

  /// `true` when the operation has exhausted both gates and must leave the
  /// queue so the rest of the writes can move.
  final bool shouldQuarantine;

  /// Counted failures so far, including the one being judged.
  final int attempts;

  /// Time between the first counted failure and this one.
  final Duration stuckFor;

  /// Single-line summary for the log entry and the crash report.
  String describe() => '$attempts rejections over ${stuckFor.inHours}h';
}

/// Last line of defence for the upload queue: makes sure no operation can
/// block it indefinitely, whatever its error code.
///
/// `SyncErrorClassifier` closes the failure modes we know by name; unknown
/// codes stay transient, which is the right call for user data but keeps alive
/// the exact shape of the 2026-07-25 incident — a code nobody foresaw retried
/// forever, in silence, on a FIFO queue, for three days.
///
/// The rule is deliberately two-gated, because the naive "quarantine after N
/// retries" has a failure mode worse than the bug it fixes: a user offline, or
/// a backend down for an afternoon, would accumulate perfectly legitimate
/// retries and watch their writes moved to quarantine as if something were
/// broken. So:
///
///  1. Connectivity failures are not counted at all (see
///     [SyncErrorClassifier.isConnectivityFailure]). Being offline is free and
///     unlimited — the backend never judged the write.
///  2. What is counted is a *rejection*: the backend answered with something
///     we could not classify (5xx, 429, an unknown code). Those are the ones
///     that can be permanent while looking transient.
///  3. Quarantine needs **both** [maxAttempts] and [minStuckDuration]. Either
///     one alone is a false positive waiting to happen.
@lazySingleton
class SyncRetryWatchdog {
  const SyncRetryWatchdog(this._store);

  /// Counted rejections before an operation is even a candidate.
  ///
  /// PowerSync retries an aborted upload roughly every few seconds, so this is
  /// reached within minutes of continuous rejection. It is not the gate that
  /// carries the decision — [minStuckDuration] is — but it is what stops a
  /// single rejection from being escalated just because the app happened to be
  /// closed for a long time between two attempts.
  static const int maxAttempts = 20;

  /// How long the same operation must have been rejected before quarantining
  /// it is the lesser evil.
  ///
  /// 24 hours, chosen between the two anchors the incident gives us: a planned
  /// maintenance window or a provider outage lasts hours (a 503 for 20 minutes
  /// must not touch anything, and even a bad day at Supabase resolves well
  /// inside a day), while the real blockage lasted three days and cost 89
  /// records. One day of continuous, server-answered rejection is long past
  /// any outage we should keep waiting on, and cuts the worst case from days
  /// to a day — while a genuine outage never reaches this gate, because the
  /// clock only advances on failures the server itself produced.
  static const Duration minStuckDuration = Duration(hours: 24);

  /// The ledger is diagnostics, not history: keep it small enough that the
  /// file stays cheap to rewrite on every failed operation.
  static const int _maxTrackedOperations = 200;

  final SyncRetryLedgerStore _store;

  /// Records one failed upload and decides whether it may keep retrying.
  ///
  /// Never throws: it runs inside the upload path, where any exception would
  /// be read as a failed upload and would feed the very loop this prevents.
  Future<SyncRetryVerdict> registerFailure({
    required SyncOperation operation,
    required Object error,
  }) async {
    if (SyncErrorClassifier.isConnectivityFailure(error)) {
      return const SyncRetryVerdict.notCounted();
    }
    try {
      final now = DateTime.now();
      final key = SyncRetryRecord.keyOf(operation);
      final existing = _findOrNull(await _store.readAll(), key);
      final updated = existing?.bump(
            at: now,
            errorCode: SyncErrorClassifier.codeOf(error),
          ) ??
          SyncRetryRecord(
            key: key,
            attempts: 1,
            firstFailureAt: now,
            lastFailureAt: now,
            lastErrorCode: SyncErrorClassifier.codeOf(error),
          );
      await _store.upsert(updated);
      final verdict = SyncRetryVerdict(
        shouldQuarantine: updated.attempts >= maxAttempts &&
            updated.stuckFor >= minStuckDuration,
        attempts: updated.attempts,
        stuckFor: updated.stuckFor,
      );
      // Pruning is housekeeping, so it gets its own guard: inside the outer
      // `try` a failing `remove` (full disk, ledger over the cap) would jump to
      // the fail-open catch below and discard a quarantine verdict that was
      // already earned. Failing open on a verdict we could not *compute* is
      // right; silently dropping one we did compute is how a real stall stays
      // invisible — the exact mechanism behind the incident this class exists
      // to prevent (decision #22, docs/requirements/05-auth-sync.md).
      try {
        await _prune();
      } catch (_) {
        // Ledger stays over its cap until the next successful write.
      }
      return verdict;
    } catch (_) {
      // A ledger we cannot write is a watchdog we cannot trust — but failing
      // open (keep retrying) is the same behaviour as before this class
      // existed, and failing closed would quarantine on an I/O error.
      return const SyncRetryVerdict.notCounted();
    }
  }

  /// The operation finally went through (or left the queue by another route):
  /// its history is meaningless now.
  Future<void> forget(SyncOperation operation) async {
    try {
      await _store.remove(SyncRetryRecord.keyOf(operation));
    } catch (_) {
      // Same reason as above: bookkeeping must never break the upload path.
    }
  }

  SyncRetryRecord? _findOrNull(List<SyncRetryRecord> records, String key) {
    for (final record in records) {
      if (record.key == key) {
        return record;
      }
    }
    return null;
  }

  /// Evicts the least recently failing entries once the ledger grows past its
  /// bound. Anything close to quarantining has failed recently, so it survives.
  Future<void> _prune() async {
    final records = await _store.readAll();
    if (records.length <= _maxTrackedOperations) {
      return;
    }
    final sorted = List<SyncRetryRecord>.from(records)
      ..sort((a, b) => a.lastFailureAt.compareTo(b.lastFailureAt));
    for (final stale in sorted.take(records.length - _maxTrackedOperations)) {
      await _store.remove(stale.key);
    }
  }
}
