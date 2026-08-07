import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/usecases/has_any_transaction.dart';
import '../../domain/entities/import_batch.dart';
import '../../domain/usecases/get_last_backup_saved_at.dart';
import '../../domain/usecases/watch_import_batches.dart';
import 'import_export_hub_state.dart';

/// Drives the Import/Export hub (`oSWz9`/`qDCvi`/`Am9cg`).
@injectable
class ImportExportHubCubit extends Cubit<ImportExportHubState> {
  ImportExportHubCubit(
    this._getLastBackupSavedAt,
    this._watchImportBatches,
    this._hasAnyTransaction,
  ) : super(const ImportExportHubState());

  final GetLastBackupSavedAt _getLastBackupSavedAt;
  final WatchImportBatches _watchImportBatches;
  final HasAnyTransaction _hasAnyTransaction;

  StreamSubscription<Result<List<ImportBatch>>>? _batchesSubscription;
  StreamSubscription<bool>? _hasAnyTransactionSubscription;

  /// Subscribes to [HasAnyTransaction] itself (rather than taking a one-shot
  /// value from the caller) so the hub flips out of `Am9cg` the moment an
  /// import writes the first transaction, without requiring the user to
  /// leave and re-enter the screen. Subscribing before the first `await`
  /// below means no emission can be missed while [_getLastBackupSavedAt]
  /// resolves.
  Future<void> start() async {
    await _batchesSubscription?.cancel();
    await _hasAnyTransactionSubscription?.cancel();
    emit(const ImportExportHubState());

    final hasAnyTransactionCompleter = Completer<bool>();
    _hasAnyTransactionSubscription = _hasAnyTransaction().listen((value) {
      if (!hasAnyTransactionCompleter.isCompleted) {
        hasAnyTransactionCompleter.complete(value);
      }
      if (isClosed || state.isLoading) {
        return;
      }
      emit(state.copyWith(hasAnyTransactions: value));
    });

    final savedAtResult = await _getLastBackupSavedAt();
    final hasAnyTransactions = await hasAnyTransactionCompleter.future;
    if (isClosed) {
      return;
    }
    emit(
      savedAtResult.fold(
        (failure) => state.copyWith(
          status: ImportExportHubStatus.failure,
          failure: failure,
          hasAnyTransactions: hasAnyTransactions,
        ),
        (savedAt) => state.copyWith(
          status: ImportExportHubStatus.ready,
          lastBackupSavedAt: savedAt,
          clearLastBackupSavedAt: savedAt == null,
          hasAnyTransactions: hasAnyTransactions,
        ),
      ),
    );

    _batchesSubscription = _watchImportBatches().listen(_onBatches);
  }

  void _onBatches(Result<List<ImportBatch>> result) {
    if (isClosed) {
      return;
    }
    if (result case Right(value: final batches)) {
      emit(
        batches.isEmpty
            ? state.copyWith(clearLatestBatch: true)
            : state.copyWith(latestBatch: batches.first),
      );
    }
  }

  /// Called right after `CreateFullBackup` succeeds, so the hero updates
  /// without waiting for a full [start] refresh.
  void markBackupJustSaved(DateTime savedAt) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(lastBackupSavedAt: savedAt));
  }

  @override
  Future<void> close() async {
    await _batchesSubscription?.cancel();
    await _hasAnyTransactionSubscription?.cancel();
    return super.close();
  }
}
