import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../features/categories/domain/usecases/seed_default_categories.dart';
import '../legal/domain/repositories/legal_documents_repository.dart';
import 'first_launch_offline_state.dart';

/// Drives the "Reintentar" button on the "Primer arranque — sin conexión"
/// screen (`KSkpO`/`zeAfp`, decisión #12 de `docs/requirements/fase-1/05-auth-sync.md`).
///
/// Same idle/loading pattern as `LoginCubit`, scoped to this one retry
/// button instead of a full attempt/error flow: a failed retry just returns
/// to `idle` so the user can tap again, with no error copy — network hiccups
/// on a first launch are not the user's fault.
@injectable
class FirstLaunchOfflineCubit extends Cubit<FirstLaunchOfflineState> {
  FirstLaunchOfflineCubit(this._seedDefaultCategories, this._legalDocuments)
      : super(const FirstLaunchOfflineState());

  final SeedDefaultCategories _seedDefaultCategories;
  final LegalDocumentsRepository _legalDocuments;

  Future<void> retry() async {
    emit(state.copyWith(status: FirstLaunchOfflineStatus.retrying));
    final result = await _seedDefaultCategories();
    if (isClosed) {
      return;
    }
    result.fold(
      (_) => emit(state.copyWith(status: FirstLaunchOfflineStatus.idle)),
      (_) {
        // A successful retry proves this device has connectivity now — piggy
        // back the legal manifest/documents background download on it, same
        // fire-and-forget posture as `bootstrap.dart`'s normal-path call: a
        // failure here must not affect this screen's own success state.
        unawaited(_legalDocuments.refreshFromRemote());
        emit(state.copyWith(status: FirstLaunchOfflineStatus.success));
      },
    );
  }
}
