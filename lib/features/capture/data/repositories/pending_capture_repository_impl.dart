import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../../transactions/data/models/transaction_mapper.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_draft.dart';
import '../../domain/entities/capture_ingestion.dart';
import '../../domain/entities/pending_capture.dart';
import '../../domain/repositories/pending_capture_repository.dart';
import '../datasources/pending_captures_local_datasource.dart';
import '../models/pending_capture_mapper.dart';

/// Drift implementation of [PendingCaptureRepository].
///
/// Owns this feature's cross-cutting write rules: `updatedAt` stamped on
/// every write, discarding as a status change (never `deletedAt`), purging as
/// a physical delete, and confirmation as a single database transaction so a
/// capture is never marked confirmed without the movement it produced.
@LazySingleton(as: PendingCaptureRepository)
class PendingCaptureRepositoryImpl implements PendingCaptureRepository {
  const PendingCaptureRepositoryImpl(this._local, this._crash);

  final PendingCapturesLocalDatasource _local;
  final CrashReporter _crash;

  @override
  Stream<Result<List<PendingCapture>>> watchPendingCaptures() => _guardStream(
        _local.watchPendingCaptures().map(
              (rows) => Right(rows.map(PendingCaptureMapper.toEntity).toList()),
            ),
      );

  @override
  Stream<Result<int>> watchPendingCaptureCount() => _guardStream(
        _local.watchPendingCaptureCount().map(Right.new),
      );

  @override
  FutureResult<List<PendingCapture>> ingestParsedCaptures(
    List<CaptureIngestion> captures,
  ) =>
      _guard(() async {
        final now = DateTime.now();
        final rows = await _local.insertCaptures([
          for (final capture in captures)
            PendingCaptureMapper.insertCompanion(capture, now: now),
        ]);
        return Right(rows.map(PendingCaptureMapper.toEntity).toList());
      });

  @override
  FutureResult<PendingCapture> getCapture(String id) => _guard(() async {
        final row = await _local.getCapture(id);
        if (row == null) {
          return Left(NotFoundFailure('capture "$id" does not exist'));
        }
        return Right(PendingCaptureMapper.toEntity(row));
      });

  @override
  FutureResult<Transaction> confirmCapture({
    required String captureId,
    required TransactionDraft draft,
  }) =>
      _guard(
        () => _local.runInTransaction(() async {
          final capture = await _local.getCapture(captureId);
          if (capture == null) {
            return Left(NotFoundFailure('capture "$captureId" does not exist'));
          }
          // Guards the double tap on "Confirmar": a capture already
          // confirmed must not produce a second transaction, which would
          // double the amount in the account with nothing to point at.
          if (capture.transactionId != null) {
            return const Left(
              ValidationFailure('this capture was already confirmed'),
            );
          }

          final now = DateTime.now();
          final created = await _local.insertTransaction(
            TransactionMapper.toInsertCompanion(draft, now: now),
          );
          await _local.updateCapture(
            captureId,
            PendingCaptureMapper.confirmCompanion(
              transactionId: created.id,
              now: now,
            ),
          );
          return Right(TransactionMapper.toEntity(created));
        }),
      );

  @override
  FutureResult<Unit> discardCapture(
    String id, {
    String? duplicateOfTransactionId,
  }) =>
      _guard(() async {
        final updated = await _local.updateCapture(
          id,
          PendingCaptureMapper.discardCompanion(
            now: DateTime.now(),
            duplicateOfTransactionId: duplicateOfTransactionId,
          ),
        );
        if (updated == null) {
          return Left(NotFoundFailure('capture "$id" does not exist'));
        }
        return const Right(unit);
      });

  @override
  FutureResult<Unit> restoreCapture(String id) => _guard(() async {
        final updated = await _local.updateCapture(
          id,
          PendingCaptureMapper.restoreCompanion(now: DateTime.now()),
        );
        if (updated == null) {
          return Left(NotFoundFailure('capture "$id" does not exist'));
        }
        return const Right(unit);
      });

  @override
  FutureResult<List<String>> discardCapturesBefore(DateTime postedBefore) =>
      _guard(
        () => _local.runInTransaction(() async {
          final now = DateTime.now();
          final targets = await _local.pendingCapturesBefore(postedBefore);
          for (final capture in targets) {
            await _local.updateCapture(
              capture.id,
              PendingCaptureMapper.discardCompanion(now: now),
            );
          }
          // Only the ids actually discarded, so the snackbar's undo restores
          // exactly those and never revives something discarded earlier.
          return Right(targets.map((capture) => capture.id).toList());
        }),
      );

  @override
  FutureResult<int> purgeDiscardedCaptures(DateTime discardedBefore) =>
      _guard(() async {
        final removed = await _local.deleteDiscardedBefore(discardedBefore);
        return Right(removed);
      });

  @override
  FutureResult<List<Transaction>> findMatchingTransactions({
    required int amountMinor,
    required String currency,
    required DateTime around,
    required Duration window,
  }) =>
      _guard(() async {
        final rows = await _local.findMatchingTransactions(
          amountMinor: amountMinor,
          currency: currency,
          from: around.subtract(window),
          to: around.add(window),
        );
        return Right(rows.map(TransactionMapper.toEntity).toList());
      });

  @override
  FutureResult<List<PendingCapture>> findMatchingCaptures({
    required String excludeId,
    required int amountMinor,
    required String currency,
    required DateTime around,
    required Duration window,
  }) =>
      _guard(() async {
        final rows = await _local.findMatchingCaptures(
          excludeId: excludeId,
          amountMinor: amountMinor,
          currency: currency,
          from: around.subtract(window),
          to: around.add(window),
        );
        return Right(rows.map(PendingCaptureMapper.toEntity).toList());
      });

  @override
  FutureResult<String?> findAccountIdByLast4(String hint) => _guard(() async {
        // `cardLast4` first: it is the physical card a purchase notification
        // quotes. `last4` (the account number) is the fallback.
        final byCard = await _local.accountsByCardLast4(hint);
        if (byCard.length == 1) {
          return Right(byCard.single.id);
        }
        if (byCard.length > 1) {
          // Two cards ending the same: guessing one of them would put the
          // movement in the wrong account. No suggestion is better.
          return const Right(null);
        }
        final byAccount = await _local.accountsByLast4(hint);
        return Right(byAccount.length == 1 ? byAccount.single.id : null);
      });

  @override
  FutureResult<Unit> deleteAllCaptures() => _guard(() async {
        await _local.deleteAllCaptures();
        return const Right(unit);
      });

  /// Turns any infrastructure exception into a `Failure`, so nothing escapes
  /// the data layer as a raw exception.
  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'capture inbox query');
      return Left(
        DatabaseFailure('capture inbox query failed', cause: e, stackTrace: st),
      );
    }
  }

  /// Same for streams: a query error becomes a `Left` **emission** instead of
  /// a stream error, so the inbox can render its error state without the
  /// subscription dying.
  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            unawaited(
              _crash.recordError(
                error,
                stackTrace,
                context: 'capture inbox stream',
              ),
            );
            sink.add(
              Left(
                DatabaseFailure(
                  'capture inbox stream failed',
                  cause: error,
                  stackTrace: stackTrace,
                ),
              ),
            );
          },
        ),
      );
}
