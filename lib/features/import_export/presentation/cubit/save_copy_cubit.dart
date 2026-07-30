import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/cancellation_token.dart';
import '../../domain/usecases/create_full_backup.dart';
import '../../domain/usecases/mark_backup_saved.dart';
import 'save_copy_state.dart';

/// Drives HU-03 "Guardar una copia": writes the full `.billetudo.json`,
/// remembers when for the hub's status row, and hands it to the share sheet.
@injectable
class SaveCopyCubit extends Cubit<SaveCopyState> {
  SaveCopyCubit(this._createFullBackup, this._markBackupSaved)
      : super(const SaveCopyState());

  final CreateFullBackup _createFullBackup;
  final MarkBackupSaved _markBackupSaved;

  CancellationToken? _cancellationToken;

  Future<void> start() async {
    final token = CancellationToken();
    _cancellationToken = token;
    emit(const SaveCopyState(status: SaveCopyStatus.running));

    final tempDir = await getTemporaryDirectory();
    final today = DateTime.now();
    final stamp =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final path = p.join(tempDir.path, 'billetudo-copia-$stamp.billetudo.json');

    final result = await _createFullBackup(
      outputPath: path,
      onProgress: (processed, total) {
        if (!isClosed) {
          emit(state.copyWith(processed: processed, total: total ?? 0));
        }
      },
      cancellationToken: token,
    );
    _cancellationToken = null;
    if (isClosed) {
      return;
    }
    await result.fold(
      (failure) async {
        final cancelled =
            failure is IoFailure && failure.reason == IoFailureReason.cancelled;
        emit(
          state.copyWith(
            status: cancelled ? SaveCopyStatus.cancelled : SaveCopyStatus.error,
            failure: cancelled ? null : failure,
          ),
        );
      },
      (header) async {
        await _markBackupSaved(header.createdAt);
        if (isClosed) {
          return;
        }
        emit(state.copyWith(status: SaveCopyStatus.done, resultFilePath: path));
      },
    );
  }

  /// Stops the running backup at the next table boundary (HU-03/HU-09): the
  /// partial file is deleted, and [SaveCopyState.status] becomes `cancelled`.
  void cancel() => _cancellationToken?.cancel();

  Future<void> shareResult(String path) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    if (!isClosed) {
      emit(state.copyWith(status: SaveCopyStatus.idle, clearResult: true));
    }
  }

  void dismissError() => emit(const SaveCopyState());
}
