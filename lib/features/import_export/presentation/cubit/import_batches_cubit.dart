import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/import_batch.dart';
import '../../domain/usecases/undo_import_batch.dart';
import '../../domain/usecases/watch_import_batches.dart';
import 'import_batches_state.dart';

/// Drives the "Importaciones" history and its "Deshacer" action (HU-08).
@injectable
class ImportBatchesCubit extends Cubit<ImportBatchesState> {
  ImportBatchesCubit(this._watchImportBatches, this._undoImportBatch)
      : super(const ImportBatchesState());

  final WatchImportBatches _watchImportBatches;
  final UndoImportBatch _undoImportBatch;

  StreamSubscription<Result<List<ImportBatch>>>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    emit(const ImportBatchesState());
    _subscription = _watchImportBatches().listen(_onBatches);
  }

  void _onBatches(Result<List<ImportBatch>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(status: ImportBatchesStatus.failure, failure: failure),
        (batches) => state.copyWith(status: ImportBatchesStatus.ready, batches: batches),
      ),
    );
  }

  /// HU-08: reverts [batchId]. The escalated confirmation itself already
  /// happened in `presentation/` by the time this runs.
  Future<bool> undo(String batchId) async {
    final result = await _undoImportBatch(batchId);
    if (isClosed) {
      return false;
    }
    return result.fold(
      (failure) {
        emit(state.copyWith(failure: failure));
        return false;
      },
      (summary) {
        emit(state.copyWith(lastUndoSummary: summary));
        return true;
      },
    );
  }

  void clearLastUndoSummary() =>
      emit(state.copyWith(clearLastUndoSummary: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
