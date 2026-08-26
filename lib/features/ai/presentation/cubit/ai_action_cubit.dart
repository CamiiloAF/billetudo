import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/ai_action_proposal.dart';
import '../../domain/usecases/execute_ai_action.dart';
import '../../domain/usecases/update_ai_proposal_status.dart';
import 'ai_action_state.dart';

/// Executes a confirmed `AiProposalCard` (or a "Reintentar" after a failed
/// write) and persists its new `AiProposalStatus`.
///
/// The card's own state (pending/confirmed/dismissed/failed) always comes
/// from the message's persisted `AiActionProposal.status` — this cubit only
/// tracks which single card is mid-write right now.
@injectable
class AiActionCubit extends Cubit<AiActionState> {
  AiActionCubit(this._executeAiAction, this._updateAiProposalStatus)
      : super(const AiActionState());

  final ExecuteAiAction _executeAiAction;
  final UpdateAiProposalStatus _updateAiProposalStatus;

  /// Runs the write behind a pending/failed proposal card. Used for both the
  /// first "Confirmar" tap and a later "Reintentar" — the domain use case is
  /// the same either way.
  Future<void> confirm({
    required String messageId,
    required AiActionProposal proposal,
  }) async {
    emit(
      AiActionState(pendingProposalId: proposal.id),
    );
    final result = await _executeAiAction(proposal);
    if (isClosed) {
      return;
    }
    await result.fold(
      (failure) async {
        await _updateAiProposalStatus(
          messageId: messageId,
          proposalId: proposal.id,
          status: AiProposalStatus.failed,
        );
        if (!isClosed) {
          emit(AiActionState(failure: failure));
        }
      },
      (_) async {
        await _updateAiProposalStatus(
          messageId: messageId,
          proposalId: proposal.id,
          status: AiProposalStatus.confirmed,
        );
        if (!isClosed) {
          emit(const AiActionState());
        }
      },
    );
  }

  /// "Descartar": no write happens, only the card's status is persisted.
  Future<void> dismiss({
    required String messageId,
    required AiActionProposal proposal,
  }) async {
    await _updateAiProposalStatus(
      messageId: messageId,
      proposalId: proposal.id,
      status: AiProposalStatus.dismissed,
    );
  }
}
