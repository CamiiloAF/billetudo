import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';

/// Per-card confirm/dismiss/retry state, keyed by proposal id.
///
/// One `AiActionCubit` instance is shared by the whole chat screen (provided
/// once, like `AiChatCubit`): a card's own persisted `AiProposalStatus`
/// (`AiActionProposal.status`, read from the message stream) already tells
/// `AiProposalCard` which of the four Pencil states to render — this only
/// tracks the **in-flight write** for the card the user just tapped, so its
/// button can show a spinner without a second tap racing the first.
class AiActionState extends Equatable {
  const AiActionState({
    this.pendingProposalId,
    this.failure,
  });

  /// The id of the proposal currently being confirmed, or `null` when no
  /// write is in flight.
  final String? pendingProposalId;

  final Failure? failure;

  bool isPending(String proposalId) => pendingProposalId == proposalId;

  AiActionState copyWith({
    String? pendingProposalId,
    bool clearPending = false,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      AiActionState(
        pendingProposalId:
            clearPending ? null : (pendingProposalId ?? this.pendingProposalId),
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [pendingProposalId, failure];
}
