import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/import_batch.dart';
import '../../domain/usecases/get_last_backup_saved_at.dart';
import '../../domain/usecases/watch_import_batches.dart';
import 'import_export_hub_state.dart';

/// Drives the Import/Export hub (`oSWz9`/`qDCvi`/`Am9cg`).
@injectable
class ImportExportHubCubit extends Cubit<ImportExportHubState> {
  ImportExportHubCubit(this._getLastBackupSavedAt, this._watchImportBatches)
      : super(const ImportExportHubState());

  final GetLastBackupSavedAt _getLastBackupSavedAt;
  final WatchImportBatches _watchImportBatches;

  StreamSubscription<Result<List<ImportBatch>>>? _batchesSubscription;

  /// [hasAnyTransactions] comes from the caller (the router), which is the
  /// only layer allowed to reach into another feature's state — this
  /// feature's own domain stays free of a cross-feature dependency just to
  /// answer "does the user have any movement yet" (`Am9cg` empty state).
  Future<void> start({bool hasAnyTransactions = true}) async {
    await _batchesSubscription?.cancel();
    emit(
      ImportExportHubState(hasAnyTransactions: hasAnyTransactions),
    );

    final savedAtResult = await _getLastBackupSavedAt();
    if (isClosed) {
      return;
    }
    emit(
      savedAtResult.fold(
        (failure) => state.copyWith(
          status: ImportExportHubStatus.failure,
          failure: failure,
        ),
        (savedAt) => state.copyWith(
          status: ImportExportHubStatus.ready,
          lastBackupSavedAt: savedAt,
          clearLastBackupSavedAt: savedAt == null,
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
    return super.close();
  }
}
