import 'package:equatable/equatable.dart';

import 'ai_action_proposal.dart';

/// Who wrote a bubble. The `tool` role of the wire protocol is deliberately
/// absent: tool results are plumbing (`AiToolResult`), never a bubble, and
/// persisting them would put raw ledger rows in the transcript.
enum AiMessageRole { user, assistant }

/// Delivery state of a bubble.
///
/// [pending] and [failed] only ever apply to a **user** message: it is written
/// locally the instant it is typed, so the thread survives losing signal
/// mid-turn and can be retried. An assistant message is only persisted once it
/// arrived whole, so it is always [sent] — there is no half-streamed reply to
/// resume.
enum AiMessageStatus { pending, sent, failed }

/// One bubble of a conversation, as stored locally.
///
/// The device owns the thread: the backend is a stateless broker that keeps no
/// transcript (`supabase/functions/README.md`), so this is the only copy.
class AiMessage extends Equatable {
  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.status,
    this.proposals = const <AiActionProposal>[],
  });

  /// UUID as text, generated on the device.
  final String id;

  final String conversationId;
  final AiMessageRole role;
  final String content;
  final DateTime createdAt;
  final AiMessageStatus status;

  /// Action cards attached to this bubble. Always empty for
  /// [AiMessageRole.user] — only the assistant proposes.
  final List<AiActionProposal> proposals;

  AiMessage copyWith({
    String? content,
    AiMessageStatus? status,
    List<AiActionProposal>? proposals,
  }) =>
      AiMessage(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content ?? this.content,
        createdAt: createdAt,
        status: status ?? this.status,
        proposals: proposals ?? this.proposals,
      );

  @override
  List<Object?> get props =>
      [id, conversationId, role, content, createdAt, status, proposals];
}
