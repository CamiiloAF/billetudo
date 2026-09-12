import 'package:equatable/equatable.dart';

/// What kind of row a confirmed proposal produced.
///
/// [debtLink] is the odd one out: it creates nothing. It reports a movement
/// that already existed now counting in a debt's balance, so the outcome's
/// entity id is the debt's — the only screen worth opening after that write.
enum AiActionEntity { budget, goal, category, transaction, debtLink }

/// The result of executing one proposal.
///
/// Carries the created row's id so the confirmation card can deep-link to it:
/// a proposal the user accepted has to be inspectable, otherwise "listo" is
/// the only proof the write happened.
class AiActionOutcome extends Equatable {
  const AiActionOutcome({
    required this.proposalId,
    required this.entity,
    required this.entityId,
  });

  final String proposalId;
  final AiActionEntity entity;

  /// UUID of the created row — or, for [AiActionEntity.debtLink], of the debt
  /// the movement was attributed to.
  final String entityId;

  @override
  List<Object?> get props => [proposalId, entity, entityId];
}
