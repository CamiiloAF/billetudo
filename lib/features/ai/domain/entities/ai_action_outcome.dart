import 'package:equatable/equatable.dart';

/// What kind of row a confirmed proposal produced.
enum AiActionEntity { budget, goal, category, transaction }

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

  /// UUID of the created row.
  final String entityId;

  @override
  List<Object?> get props => [proposalId, entity, entityId];
}
