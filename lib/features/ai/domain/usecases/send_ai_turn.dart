import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/ai_turn.dart';
import '../repositories/ai_repository.dart';

/// Sends one turn to the broker.
@injectable
class SendAiTurn {
  const SendAiTurn(this._repository);

  final AiRepository _repository;

  FutureResult<AiTurnResponse> call(AiTurnRequest request) =>
      _repository.sendTurn(request);
}
