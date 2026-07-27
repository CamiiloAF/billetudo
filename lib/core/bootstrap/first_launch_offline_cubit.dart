import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../features/categories/domain/usecases/seed_default_categories.dart';
import 'first_launch_offline_state.dart';

/// Drives the "Reintentar" button on the "Primer arranque — sin conexión"
/// screen (`KSkpO`/`zeAfp`, decisión #12 de `docs/requirements/05-auth-sync.md`).
///
/// Same idle/loading pattern as `LoginCubit`, scoped to this one retry
/// button instead of a full attempt/error flow: a failed retry just returns
/// to `idle` so the user can tap again, with no error copy — network hiccups
/// on a first launch are not the user's fault.
@injectable
class FirstLaunchOfflineCubit extends Cubit<FirstLaunchOfflineState> {
  FirstLaunchOfflineCubit(this._seedDefaultCategories)
      : super(const FirstLaunchOfflineState());

  final SeedDefaultCategories _seedDefaultCategories;

  Future<void> retry() async {
    emit(state.copyWith(status: FirstLaunchOfflineStatus.retrying));
    final result = await _seedDefaultCategories();
    if (isClosed) {
      return;
    }
    result.fold(
      (_) => emit(state.copyWith(status: FirstLaunchOfflineStatus.idle)),
      (_) => emit(state.copyWith(status: FirstLaunchOfflineStatus.success)),
    );
  }
}
