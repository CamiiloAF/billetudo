import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/delete_account_scope.dart';
import '../../domain/entities/local_data_choice.dart';

enum DeleteAccountStep { confirm, localDataChoice, done }

enum DeleteAccountStatus { idle, loading, error }

/// State of the 3-step "Eliminar cuenta" flow (HU-07).
class DeleteAccountState extends Equatable {
  const DeleteAccountState({
    this.step = DeleteAccountStep.confirm,
    this.status = DeleteAccountStatus.idle,
    this.scope,
    this.choice,
    this.failure,
  });

  final DeleteAccountStep step;
  final DeleteAccountStatus status;

  /// What this run can actually delete (`GetDeleteAccountScope`). `null`
  /// until `DeleteAccountCubit.loadScope` resolves — the caller awaits that
  /// before showing paso 1, so every sheet can assume it is non-null once on
  /// screen.
  final DeleteAccountScope? scope;

  /// Paso 2's pick. `null` means the user hasn't chosen yet — the CTA there
  /// must stay disabled, never default to a choice (no dark pattern, HU-07).
  final LocalDataChoice? choice;
  final Failure? failure;

  bool get canContinueFromChoice => choice != null;

  /// Signed out, but this device signed in before: paso 1 must warn that
  /// continuing without signing back in only deletes local data, and paso
  /// 2/3's copy must not claim the cloud account was deleted.
  bool get isLocalOnlyAfterSignOut =>
      scope == DeleteAccountScope.localOnlySignedOut;

  /// This device has never completed a sign-in: there is no cloud account to
  /// mention, so paso 2's copy must not claim one was already deleted the
  /// way the default (signed-in) copy does.
  bool get isLocalOnlyNeverSignedIn =>
      scope == DeleteAccountScope.localOnlyNeverSignedIn;

  DeleteAccountState copyWith({
    DeleteAccountStep? step,
    DeleteAccountStatus? status,
    DeleteAccountScope? scope,
    LocalDataChoice? choice,
    Failure? failure,
  }) =>
      DeleteAccountState(
        step: step ?? this.step,
        status: status ?? this.status,
        scope: scope ?? this.scope,
        choice: choice ?? this.choice,
        failure: failure,
      );

  @override
  List<Object?> get props => [step, status, scope, choice, failure];
}
