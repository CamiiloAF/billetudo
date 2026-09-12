import 'dart:convert';

import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/ai/data/mappers/ai_message_mapper.dart';
import 'package:billetudo/features/ai/domain/entities/ai_action_proposal.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ai_fixtures.dart';

/// `role` and `status` are plain text columns, so this mapper is what keeps a
/// row written by another build from taking down the whole thread.
void main() {
  db.AiMessage row({
    String id = 'm1',
    String conversationId = 'conv-1',
    String role = 'assistant',
    String content = 'Hola',
    int? createdAt,
    String status = 'sent',
    String? proposalsJson,
  }) =>
      db.AiMessage(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content,
        createdAt:
            createdAt ?? DateTime.utc(2026, 8, 25).millisecondsSinceEpoch,
        status: status,
        proposalsJson: proposalsJson,
      );

  group('role', () {
    test('reads the user back as the user', () {
      expect(
          AiMessageMapper.toEntity(row(role: 'user')).role, AiMessageRole.user);
    });

    test('attributes an unreadable role to the assistant', () {
      expect(
        AiMessageMapper.toEntity(row(role: 'oracle')).role,
        AiMessageRole.assistant,
      );
    });
  });

  group('status', () {
    test(
        'accepts "sending" as an alias of pending, so an older row still '
        'reads as on its way', () {
      expect(
        AiMessageMapper.toEntity(row(status: 'sending')).status,
        AiMessageStatus.pending,
      );
    });

    test('reads a failed delivery as failed', () {
      expect(
        AiMessageMapper.toEntity(row(status: 'failed')).status,
        AiMessageStatus.failed,
      );
    });

    test('an unknown status reads as delivered rather than crashing', () {
      expect(
        AiMessageMapper.toEntity(row(status: 'half_sent')).status,
        AiMessageStatus.sent,
      );
    });
  });

  group('createdAt', () {
    test('is read as epoch millis, keeping sub-second ordering', () {
      final instant = DateTime.utc(2026, 8, 25, 9, 30, 15, 250);

      final entity = AiMessageMapper.toEntity(
        row(createdAt: instant.millisecondsSinceEpoch),
      );

      expect(entity.createdAt.millisecondsSinceEpoch,
          instant.millisecondsSinceEpoch);
    });

    test('is written back as the same instant, in UTC millis', () {
      final message = buildAiMessage(createdAt: DateTime(2026, 8, 25, 9, 30));

      final companion = AiMessageMapper.toCompanion(message);

      expect(
        companion.createdAt.value,
        message.createdAt.toUtc().millisecondsSinceEpoch,
      );
    });
  });

  group('proposals', () {
    test('a message with no cards stores null, not an empty array', () {
      expect(AiMessageMapper.encodeProposals(const []), isNull);
    });

    test('cards survive the encode/decode round trip', () {
      final proposals = <AiActionProposal>[
        buildBudgetProposal(status: AiProposalStatus.confirmed),
        buildUnsupportedProposal(),
      ];

      final decoded = AiMessageMapper.decodeProposals(
        AiMessageMapper.encodeProposals(proposals),
      );

      expect(decoded, proposals);
    });

    test('malformed JSON on disk yields no cards instead of an exception', () {
      expect(AiMessageMapper.decodeProposals('{not json'), isEmpty);
      expect(AiMessageMapper.decodeProposals(''), isEmpty);
      expect(AiMessageMapper.decodeProposals(null), isEmpty);
    });

    test('a JSON object where an array belongs yields no cards', () {
      expect(AiMessageMapper.decodeProposals('{"id":"tc_0_0"}'), isEmpty);
    });

    test('a card whose kind this build cannot execute is still read back', () {
      final stored = jsonEncode(<Object?>[
        <String, Object?>{
          'id': 'tc_9_9',
          'kind': 'create_spaceship',
          'title': 'Comprar una nave',
        },
      ]);

      final decoded = AiMessageMapper.decodeProposals(stored);

      expect(
        decoded.single,
        isA<UnsupportedProposal>()
            .having((p) => p.rawKind, 'rawKind', 'create_spaceship'),
      );
    });
  });

  group('entity round trip', () {
    test('a message written and read back is the same message', () {
      final message = buildAiMessage(
        role: AiMessageRole.user,
        content: '¿cuánto gasté?',
        status: AiMessageStatus.failed,
        proposals: [buildTransactionProposal()],
        createdAt: DateTime(2026, 8, 25, 9, 30),
      );

      final companion = AiMessageMapper.toCompanion(message);
      final reread = AiMessageMapper.toEntity(
        row(
          id: companion.id.value,
          conversationId: companion.conversationId.value,
          role: companion.role.value,
          content: companion.content.value,
          createdAt: companion.createdAt.value,
          status: companion.status.value,
          proposalsJson: companion.proposalsJson.value,
        ),
      );

      expect(reread, message);
    });
  });
}
