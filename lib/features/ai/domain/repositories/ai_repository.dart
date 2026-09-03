import '../../../../core/error/result.dart';
import '../entities/ai_access.dart';
import '../entities/ai_turn.dart';

/// The remote half of the assistant: one call to the `ai-chat` broker per
/// turn, plus the access gate.
///
/// Nothing here is cached locally. The function is stateless by design, and a
/// cached verdict on a server-side quota is exactly the client-side limit
/// `CLAUDE.md` forbids.
abstract class AiRepository {
  /// Sends one turn. A `Left` carries the mapped backend error (`403`
  /// `ai_not_enabled`, `413` `payload_too_large`, `429` `quota_exceeded`, …)
  /// so presentation can pick the right copy without parsing a message.
  FutureResult<AiTurnResponse> sendTurn(AiTurnRequest request);

  /// Whether this user may use the assistant right now. Fails closed: an
  /// unreadable gate is never an open gate.
  FutureResult<AiAccess> checkAccess();
}
