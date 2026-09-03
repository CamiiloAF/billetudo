import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/ai_action_proposal.dart';
import '../../domain/entities/ai_message.dart';
import 'ai_action_proposal_mapper.dart';

/// Drift row ↔ [AiMessage].
///
/// `role` and `status` are plain `text()` columns, not `textEnum`: the enums
/// live in this feature's domain layer and `core/database` must not depend on
/// `features/` (see the table doc in `app_database.dart`). So the string ↔
/// enum mapping is here, and — like the proposal mapper — it never throws: a
/// value this build does not know must not take down the whole thread.
abstract final class AiMessageMapper {
  static const String _roleUser = 'user';
  static const String _roleAssistant = 'assistant';

  static const String _statusPending = 'pending';
  static const String _statusSent = 'sent';
  static const String _statusFailed = 'failed';

  static AiMessage toEntity(db.AiMessage row) => AiMessage(
        id: row.id,
        conversationId: row.conversationId,
        role: _role(row.role),
        content: row.content,
        // The column is epoch **millis** (not a Drift `DateTimeColumn`, which
        // is whole seconds) precisely so two messages of one turn keep their
        // order. Handed back in local time because that is what the bubble
        // timestamp shows; the instant is identical either way.
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        status: _status(row.status),
        proposals: decodeProposals(row.proposalsJson),
      );

  static db.AiMessagesCompanion toCompanion(AiMessage message) =>
      db.AiMessagesCompanion(
        id: Value(message.id),
        conversationId: Value(message.conversationId),
        role: Value(_roleName(message.role)),
        content: Value(message.content),
        createdAt: Value(message.createdAt.toUtc().millisecondsSinceEpoch),
        status: Value(_statusName(message.status)),
        proposalsJson: Value(encodeProposals(message.proposals)),
      );

  /// `null` for a message with no cards, which is what the column's "no
  /// proposals" state is — an empty `[]` would be indistinguishable from a
  /// stored-but-empty list and cost a decode on every read.
  static String? encodeProposals(List<AiActionProposal> proposals) {
    if (proposals.isEmpty) {
      return null;
    }
    return jsonEncode(proposals.map(AiActionProposalMapper.toJson).toList());
  }

  /// Total by construction: malformed JSON on disk yields no cards instead of
  /// an exception. The bubble's text still renders, which is the part the user
  /// actually reads.
  static List<AiActionProposal> decodeProposals(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <AiActionProposal>[];
    }
    try {
      return AiActionProposalMapper.fromJsonList(jsonDecode(raw));
    } on FormatException {
      return const <AiActionProposal>[];
    }
  }

  /// An unknown role reads as the assistant: attributing an unreadable row to
  /// the model is the conservative choice, since the user's own words are
  /// never something this app has to reconstruct.
  static AiMessageRole _role(String raw) =>
      raw == _roleUser ? AiMessageRole.user : AiMessageRole.assistant;

  static String _roleName(AiMessageRole role) => switch (role) {
        AiMessageRole.user => _roleUser,
        AiMessageRole.assistant => _roleAssistant,
      };

  /// `sending` is accepted as an alias of [AiMessageStatus.pending]: the
  /// column's doc names it, and a row written by an older build must keep
  /// reading as "still on its way" rather than as delivered.
  static AiMessageStatus _status(String raw) => switch (raw) {
        _statusPending || 'sending' => AiMessageStatus.pending,
        _statusFailed => AiMessageStatus.failed,
        _ => AiMessageStatus.sent,
      };

  static String _statusName(AiMessageStatus status) => switch (status) {
        AiMessageStatus.pending => _statusPending,
        AiMessageStatus.sent => _statusSent,
        AiMessageStatus.failed => _statusFailed,
      };
}
