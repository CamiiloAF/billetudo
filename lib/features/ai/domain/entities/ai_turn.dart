import 'package:equatable/equatable.dart';

import 'ai_action_proposal.dart';
import 'ai_message.dart';
import 'ai_tool_call.dart';
import 'financial_snapshot.dart';

/// Why the model stopped.
///
/// `toolCalls` and [AiFinishReason.toolCalls] are equivalent by contract: the
/// list is non-empty exactly when the reason is that, and empty otherwise
/// (`supabase/functions/README.md`, "Invariante").
enum AiFinishReason {
  /// A finished reply, possibly with proposal cards attached.
  message,

  /// The model needs reads resolved on-device before it can answer.
  toolCalls,

  /// The tool-round budget ran out. The reply is whatever it could say
  /// without the missing data — shown as is, never retried silently.
  maxIterations,

  /// The provider's safety layer stopped the turn.
  blocked,
}

/// One request to the broker.
///
/// The device is the source of truth for the whole conversation: the function
/// keeps no transcript and no snapshot, so everything it needs travels here
/// each turn (`supabase/functions/README.md`).
///
/// Not `Equatable` on purpose — a request is a one-shot command, never
/// compared or held in a state.
class AiTurnRequest {
  const AiTurnRequest({
    required this.conversationId,
    required this.locale,
    required this.timezone,
    required this.clientVersion,
    required this.messages,
    this.snapshot,
    this.toolResults = const <AiToolResult>[],
  });

  /// Wire cap on [messages]. Going over is a `413 payload_too_large`, whose
  /// documented handling is to prune the local history and retry — so the
  /// pruning has to happen before the call, against this number.
  static const int maxMessages = 40;

  final String conversationId;

  /// BCP-47, e.g. `es-CO`. Drives the language the model answers in.
  final String locale;

  /// IANA zone, e.g. `America/Bogota`. Every date in the payload is unix
  /// seconds, so this is the only way the model can say "este mes".
  final String timezone;

  /// `1.12.0+134`. Logged server-side; also what makes an "actualiza la app"
  /// answer possible on a protocol bump.
  final String clientVersion;

  /// The thread so far, oldest first, user and assistant bubbles only.
  final List<AiMessage> messages;

  /// `null` when the snapshot could not be built at all. Omitting it is
  /// deliberately different from sending an empty one — see
  /// [FinancialSnapshot.toJson].
  final FinancialSnapshot? snapshot;

  /// Answers to the tool calls of the previous response. Non-empty only on the
  /// continuation turn that follows an [AiFinishReason.toolCalls] response.
  final List<AiToolResult> toolResults;
}

/// One response from the broker.
class AiTurnResponse extends Equatable {
  const AiTurnResponse({
    required this.finishReason,
    required this.content,
    this.proposals = const <AiActionProposal>[],
    this.toolCalls = const <AiToolCall>[],
  });

  final AiFinishReason finishReason;

  /// Text already fit for the bubble. May be empty when [finishReason] is
  /// [AiFinishReason.toolCalls] — the model asked for data instead of talking.
  final String content;

  /// Action cards. Anything whose `kind` this version does not know arrives
  /// here as an `UnsupportedProposal`, never dropped.
  final List<AiActionProposal> proposals;

  final List<AiToolCall> toolCalls;

  /// Whether the app must resolve reads and send another turn.
  bool get needsToolResolution =>
      finishReason == AiFinishReason.toolCalls && toolCalls.isNotEmpty;

  @override
  List<Object?> get props => [finishReason, content, proposals, toolCalls];
}
