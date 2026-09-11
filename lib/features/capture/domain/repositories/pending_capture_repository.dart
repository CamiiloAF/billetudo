import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_draft.dart';
import '../entities/capture_ingestion.dart';
import '../entities/pending_capture.dart';

/// Contract for the capture inbox (HU-04, HU-05, HU-07, HU-10). Implemented
/// in `data/` over Drift.
///
/// Every write stamps `updatedAt` in the implementation. Discarding is a
/// status change, not `deletedAt`: the row survives so the snackbar can undo
/// it, and `purgeDiscardedCaptures` then removes it **physically** — there is
/// no value in keeping the trace of something the user said was not theirs,
/// and there is a privacy cost.
abstract class PendingCaptureRepository {
  /// The inbox: `pending` captures, most recent [PendingCapture.postedAt]
  /// first. Never includes confirmed or discarded rows.
  Stream<Result<List<PendingCapture>>> watchPendingCaptures();

  /// `COUNT` of the exact same set, for the bell badge — so the badge and the
  /// screen it opens can never disagree.
  Stream<Result<int>> watchPendingCaptureCount();

  /// Persists already-parsed notifications as `pending` captures. Never
  /// creates a `Transaction`.
  FutureResult<List<PendingCapture>> ingestParsedCaptures(
    List<CaptureIngestion> captures,
  );

  FutureResult<PendingCapture> getCapture(String id);

  /// Creates the transaction described by [draft] and marks [captureId]
  /// `confirmed`, linking the two. Both writes happen together: a capture
  /// marked confirmed without its transaction would vanish from the inbox
  /// without ever becoming a movement.
  FutureResult<Transaction> confirmCapture({
    required String captureId,
    required TransactionDraft draft,
  });

  /// Marks the capture `discarded`. Creates nothing.
  /// [duplicateOfTransactionId] records which transaction the user said this
  /// was ("Es la misma", HU-07).
  FutureResult<Unit> discardCapture(
    String id, {
    String? duplicateOfTransactionId,
  });

  /// Undo of [discardCapture]: back to `pending`. Only valid while the row
  /// has not been purged.
  FutureResult<Unit> restoreCapture(String id);

  /// Batch discard of every `pending` capture posted strictly before
  /// [postedBefore] (HU-10). Returns the ids affected so the snackbar can
  /// undo exactly those and nothing else.
  FutureResult<List<String>> discardCapturesBefore(DateTime postedBefore);

  /// Physically deletes `discarded` captures whose `updatedAt` is older than
  /// [discardedBefore] — i.e. past the undo window. Returns how many rows
  /// were removed.
  FutureResult<int> purgeDiscardedCaptures(DateTime discardedBefore);

  /// Transactions that may be the same movement as a capture: same
  /// [amountMinor] and [currency], `date` within [window] of [around]
  /// (HU-07). Excludes trashed rows. Never mutates anything.
  FutureResult<List<Transaction>> findMatchingTransactions({
    required int amountMinor,
    required String currency,
    required DateTime around,
    required Duration window,
  });

  /// Other `pending` captures with the same [amountMinor] and [currency]
  /// whose `postedAt` is within [window] of [around], excluding [excludeId].
  /// Deliberately NOT filtered by issuer: the wallet + bank pair of one NFC
  /// payment comes from two different packages (HU-07).
  FutureResult<List<PendingCapture>> findMatchingCaptures({
    required String excludeId,
    required int amountMinor,
    required String currency,
    required DateTime around,
    required Duration window,
  });

  /// The account whose `cardLast4` — or, failing that, `last4` — equals
  /// [hint]. `cardLast4` wins: it is the physical card the notification
  /// mentions, while `last4` identifies the account number, and on a card
  /// account both often carry the same digits. `null` when nothing matches or
  /// when more than one account does (an ambiguous guess is not a guess).
  FutureResult<String?> findAccountIdByLast4(String hint);

  /// Physically deletes every capture row, whatever its status (HU-08).
  /// Confirmed transactions are NOT touched: those are the user's movements
  /// now, not capture data.
  FutureResult<Unit> deleteAllCaptures();
}
