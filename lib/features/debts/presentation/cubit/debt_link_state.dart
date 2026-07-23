import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debt.dart';

/// The state of Movimientos link mode (`g0x859`, HU-02): the debt being linked
/// to (for the banner) and whether a link is in flight or failed.
enum DebtLinkStatus { idle, linking, failure }

class DebtLinkState extends Equatable {
  const DebtLinkState({
    required this.debt,
    this.status = DebtLinkStatus.idle,
    this.failure,
  });

  final Debt debt;
  final DebtLinkStatus status;
  final Failure? failure;

  DebtLinkState copyWith({
    DebtLinkStatus? status,
    Failure? Function()? failure,
  }) =>
      DebtLinkState(
        debt: debt,
        status: status ?? this.status,
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props => [debt, status, failure];
}
