import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/ai_action_proposal.dart';
import '../repositories/ai_history_repository.dart';

/// Persists a proposal card's new state (confirmed, dismissed, failed).
@injectable
class UpdateAiProposalStatus {
  const UpdateAiProposalStatus(this._repository);

  final AiHistoryRepository _repository;

  FutureResult<Unit> call({
    required String messageId,
    required String proposalId,
    required AiProposalStatus status,
  }) =>
      _repository.updateProposalStatus(
        messageId: messageId,
        proposalId: proposalId,
        status: status,
      );
}
