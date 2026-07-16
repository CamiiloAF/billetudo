import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/local_data_choice.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/wipe_local_data.dart';
import 'delete_account_state.dart';

/// Drives the 3-step "Eliminar cuenta" flow (HU-07): irreversible cloud
/// deletion (paso 1), then an explicit, unpreselected choice about local
/// data (paso 2), then a neutral confirmation (paso 3).
///
/// A fresh instance per flow (`@injectable`, not a singleton) — unlike
/// `AuthCubit` there's no reason for this to outlive one run of the flow.
@injectable
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit(this._deleteAccount, this._wipeLocalData)
      : super(const DeleteAccountState());

  final DeleteAccount _deleteAccount;
  final WipeLocalData _wipeLocalData;

  /// Paso 1: deletes the cloud account. On success, advances to paso 2.
  Future<void> confirmDelete() async {
    emit(state.copyWith(status: DeleteAccountStatus.loading));
    try {
      final result = await _deleteAccount();
      if (isClosed) {
        return;
      }
      result.fold(
        (failure) => emit(state.copyWith(
            status: DeleteAccountStatus.error, failure: failure)),
        (_) => emit(
          state.copyWith(
            status: DeleteAccountStatus.idle,
            step: DeleteAccountStep.localDataChoice,
          ),
        ),
      );
    } catch (e, st) {
      if (isClosed) {
        return;
      }
      // Reached until PowerSync/Supabase are wired — see
      // AuthRepositoryImpl.deleteAccount.
      emit(
        state.copyWith(
          status: DeleteAccountStatus.error,
          failure: NetworkFailure(
            'auth backend not wired yet',
            cause: e,
            stackTrace: st,
          ),
        ),
      );
    }
  }

  /// Paso 1 error state's "Reintentar".
  Future<void> retryDelete() => confirmDelete();

  /// Paso 2: records the user's explicit pick. Never called with a default —
  /// the UI only calls this from an actual tap.
  void selectLocalDataChoice(LocalDataChoice choice) =>
      emit(state.copyWith(choice: choice));

  /// Paso 2's "Continuar". Wipes local data only if that's what was chosen;
  /// either way, advances to paso 3.
  Future<void> confirmLocalDataChoice() async {
    final choice = state.choice;
    if (choice == null) {
      return;
    }
    if (choice == LocalDataChoice.keep) {
      emit(state.copyWith(step: DeleteAccountStep.done));
      return;
    }

    emit(state.copyWith(status: DeleteAccountStatus.loading));
    final result = await _wipeLocalData();
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
          state.copyWith(status: DeleteAccountStatus.error, failure: failure)),
      (_) => emit(
        state.copyWith(
            status: DeleteAccountStatus.idle, step: DeleteAccountStep.done),
      ),
    );
  }
}
