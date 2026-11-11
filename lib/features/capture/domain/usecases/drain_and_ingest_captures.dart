import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/parsed_capture.dart';
import '../entities/parsed_notification.dart';
import '../entities/pending_capture.dart';
import 'drain_native_captures.dart';
import 'ingest_parsed_captures.dart';

/// Pulls whatever the native listener buffered and persists it into the
/// review inbox in one step (HU-04).
///
/// This is the single entry point for "the phone captured something": the cold
/// start in `bootstrap`, opening Avisos, and the live doorbell fired while the
/// app is running all go through it. Keeping the mapping in one place is what
/// stops those three paths from drifting — the earlier duplication is how a
/// capture could be ingested when the app started but silently ignored when it
/// arrived live.
///
/// It never creates a `Transaction`: `IngestParsedCaptures` still applies the
/// issuer-switch and field-validation guards, and every row lands as
/// `pending`.
@injectable
class DrainAndIngestCaptures {
  const DrainAndIngestCaptures(this._drain, this._ingest);

  final DrainNativeCaptures _drain;
  final IngestParsedCaptures _ingest;

  FutureResult<List<PendingCapture>> call() async {
    final Result<List<ParsedNotification>> drained = await _drain();
    if (drained case Left(value: final failure)) {
      return Left(failure);
    }

    final List<ParsedNotification> notifications =
        drained.getOrElse((_) => const <ParsedNotification>[]);
    if (notifications.isEmpty) {
      return const Right(<PendingCapture>[]);
    }

    return _ingest(<ParsedCapture>[
      for (final capture in notifications)
        ParsedCapture(
          sourcePackage: capture.sourcePackage,
          sourceRuleId: capture.ruleId,
          postedAt: capture.postedAt,
          amountMinor: capture.amountMinor,
          currency: capture.currency,
          entryType: capture.entryType,
          merchantRaw: capture.merchantRaw,
          accountHint: capture.accountHint,
        ),
    ]);
  }
}
