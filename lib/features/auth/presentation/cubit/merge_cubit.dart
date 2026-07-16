import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/usecases/merge_local_data.dart';
import 'merge_state.dart';

/// Drives HU-04's "Tus datos están a salvo" screen: folds this device's
/// local data into the account that just signed in and reports the result.
@injectable
class MergeCubit extends Cubit<MergeState> {
  MergeCubit(this._mergeLocalData) : super(const MergeState());

  final MergeLocalData _mergeLocalData;

  Future<void> start() async {
    emit(const MergeState());
    try {
      final result = await _mergeLocalData();
      if (isClosed) {
        return;
      }
      result.fold(
        (failure) =>
            emit(state.copyWith(status: MergeStatus.failure, failure: failure)),
        (summary) =>
            emit(state.copyWith(status: MergeStatus.ready, summary: summary)),
      );
    } catch (e, st) {
      if (isClosed) {
        return;
      }
      // Reached until PowerSync/Supabase are wired — see
      // AuthRepositoryImpl.mergeLocalData.
      emit(
        state.copyWith(
          status: MergeStatus.failure,
          failure: NetworkFailure(
            'auth backend not wired yet',
            cause: e,
            stackTrace: st,
          ),
        ),
      );
    }
  }
}
