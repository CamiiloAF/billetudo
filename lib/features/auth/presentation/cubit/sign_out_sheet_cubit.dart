import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/sync/domain/usecases/get_pending_upload_count.dart';
import 'sign_out_sheet_state.dart';

/// Drives the "Cerrar sesión" sheet (HU-06): holds the local-wipe opt-in and
/// reads the upload queue once, when the sheet opens.
///
/// A fresh instance per sheet (`@injectable`): the opt-in must never be
/// remembered between two sign-out attempts.
@injectable
class SignOutSheetCubit extends Cubit<SignOutSheetState> {
  SignOutSheetCubit(this._getPendingUploadCount)
      : super(const SignOutSheetState());

  final GetPendingUploadCount _getPendingUploadCount;

  /// Takes the photo of the upload queue. If it fails, the count stays at `0`
  /// and no warning is shown: wiping is never blocked by this (a stuck sync
  /// must not trap the user's own data — see decisión #17), so the sheet
  /// stays usable either way.
  Future<void> start() async {
    final result = await _getPendingUploadCount();
    if (isClosed) {
      return;
    }
    result.fold(
      (_) {},
      (count) => emit(state.copyWith(pendingUploadCount: count)),
    );
  }

  void toggleDeleteLocalData() =>
      emit(state.copyWith(deleteLocalData: !state.deleteLocalData));
}
