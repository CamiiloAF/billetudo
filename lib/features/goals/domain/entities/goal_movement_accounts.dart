import 'package:equatable/equatable.dart';

/// The two account names a money-moving `GoalContribution` touched (`wJBMX`'s
/// "Cuenta de origen"/"Transferencia" rows in the movement detail sheet,
/// `N8Dv2e`). Resolved even when one of the accounts was since tombstoned —
/// the movement is historical fact and must keep naming it.
class GoalMovementAccounts extends Equatable {
  const GoalMovementAccounts({
    required this.originName,
    required this.destinationName,
  });

  final String originName;
  final String destinationName;

  @override
  List<Object?> get props => [originName, destinationName];
}
