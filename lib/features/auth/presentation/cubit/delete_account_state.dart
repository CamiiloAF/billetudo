import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/local_data_choice.dart';

enum DeleteAccountStep { confirm, localDataChoice, done }

enum DeleteAccountStatus { idle, loading, error }

/// State of the 3-step "Eliminar cuenta" flow (HU-07).
class DeleteAccountState extends Equatable {
  const DeleteAccountState({
    this.step = DeleteAccountStep.confirm,
    this.status = DeleteAccountStatus.idle,
    this.choice,
    this.failure,
  });

  final DeleteAccountStep step;
  final DeleteAccountStatus status;

  /// Paso 2's pick. `null` means the user hasn't chosen yet — the CTA there
  /// must stay disabled, never default to a choice (no dark pattern, HU-07).
  final LocalDataChoice? choice;
  final Failure? failure;

  bool get canContinueFromChoice => choice != null;

  DeleteAccountState copyWith({
    DeleteAccountStep? step,
    DeleteAccountStatus? status,
    LocalDataChoice? choice,
    Failure? failure,
  }) =>
      DeleteAccountState(
        step: step ?? this.step,
        status: status ?? this.status,
        choice: choice ?? this.choice,
        failure: failure,
      );

  @override
  List<Object?> get props => [step, status, choice, failure];
}
