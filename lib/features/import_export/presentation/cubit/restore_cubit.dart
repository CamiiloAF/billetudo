import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/cancellation_token.dart';
import '../../domain/entities/restore_mode.dart';
import '../../domain/usecases/parse_backup_header.dart';
import '../../domain/usecases/restore_backup.dart';
import 'restore_state.dart';

/// Drives HU-04: pick a `.billetudo.json`, validate its cabecera, show the
/// pre-restore summary, let the user choose fusionar/reemplazar (with an
/// escalated confirmation for the destructive mode) and run the restore.
@injectable
class RestoreCubit extends Cubit<RestoreState> {
  RestoreCubit(this._parseBackupHeader, this._restoreBackup)
      : super(const RestoreState());

  final ParseBackupHeader _parseBackupHeader;
  final RestoreBackup _restoreBackup;

  CancellationToken? _cancellationToken;

  void reset() => emit(const RestoreState());

  Future<void> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }
    emit(state.copyWith(step: RestoreStep.running, filePath: path));

    final headerResult = await _parseBackupHeader(path);
    if (isClosed) {
      return;
    }
    emit(
      headerResult.fold(
        (failure) => state.copyWith(step: RestoreStep.error, failure: failure),
        (header) => state.copyWith(step: RestoreStep.summary, header: header),
      ),
    );
  }

  void setMode(RestoreMode mode) => emit(
        state.copyWith(mode: mode, replaceAllAcknowledged: false),
      );

  void setReplaceAllAcknowledged({required bool value}) =>
      emit(state.copyWith(replaceAllAcknowledged: value));

  /// Moves to the escalated confirmation step for "Reemplazar todo"
  /// (`MjNwC`/`NY5o6`, HU-04) — its own screen in Pencil, not embedded in
  /// the summary step.
  void requestReplaceAllConfirm() {
    if (state.mode != RestoreMode.replaceAll) {
      return;
    }
    emit(state.copyWith(step: RestoreStep.replaceAllConfirm));
  }

  /// Backs out of the escalated confirmation without restoring anything —
  /// the acknowledgement resets, same as switching mode away and back.
  void cancelReplaceAllConfirm() => emit(
        state.copyWith(step: RestoreStep.summary, replaceAllAcknowledged: false),
      );

  Future<void> confirm() async {
    final filePath = state.filePath;
    if (filePath == null || !state.canConfirm) {
      return;
    }
    final token = CancellationToken();
    _cancellationToken = token;
    emit(state.copyWith(step: RestoreStep.running, processed: 0, total: 0));

    final result = await _restoreBackup(
      inputPath: filePath,
      mode: state.mode,
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
    emit(
      result.fold(
        (failure) {
          final cancelled =
              failure is IoFailure && failure.reason == IoFailureReason.cancelled;
          // HU-04/HU-09: cancelling rolls back the single restore
          // transaction (nothing was merged), so returning to the summary
          // step — not an error screen — lets the user just try again.
          return cancelled
              ? state.copyWith(step: RestoreStep.summary)
              : state.copyWith(step: RestoreStep.error, failure: failure);
        },
        (summary) => state.copyWith(step: RestoreStep.done, summary: summary),
      ),
    );
  }

  /// Stops the running restore at the next table boundary; because the whole
  /// restore is one Drift transaction, this rolls it back (HU-04: "o queda
  /// completa, o no queda nada").
  void cancel() => _cancellationToken?.cancel();

  void dismissError() => emit(state.copyWith(step: RestoreStep.pickFile));
}
