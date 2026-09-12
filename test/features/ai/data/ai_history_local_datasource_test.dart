import 'package:billetudo/core/database/app_database.dart'
    show AiMessagesCompanion, AppDatabase;
import 'package:billetudo/features/ai/data/datasources/ai_history_local_datasource.dart';
import 'package:billetudo/features/ai/data/mappers/ai_message_mapper.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// `AiMessages` is the local-only transcript: this device holds the only copy,
/// so the queries are exercised against a real SQLite, not a mock.
void main() {
  late AppDatabase database;
  late AiHistoryLocalDatasource datasource;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    datasource = AiHistoryLocalDatasource(database);
  });

  tearDown(() async => database.close());

  Future<String> insertMessage({
    String? id,
    String conversationId = 'conv-1',
    String role = 'assistant',
    String content = 'Hola',
    int? createdAt,
    String status = 'sent',
    String? proposalsJson,
  }) async {
    final row = await database.into(database.aiMessages).insertReturning(
          AiMessagesCompanion.insert(
            id: id == null ? const Value.absent() : Value(id),
            conversationId: conversationId,
            role: role,
            content: content,
            createdAt:
                createdAt == null ? const Value.absent() : Value(createdAt),
            status: Value(status),
            proposalsJson: Value(proposalsJson),
          ),
        );
    return row.id;
  }

  group('ids', () {
    test('a message written without an id gets a UUID, never an autoincrement',
        () async {
      final id = await insertMessage();

      expect(id, hasLength(36));
      expect(int.tryParse(id), isNull);
    });
  });

  group('watchMessages', () {
    test('emits one thread only, oldest first', () async {
      await insertMessage(
        id: 'm2',
        content: 'segunda',
        createdAt: 2000,
      );
      await insertMessage(id: 'm1', content: 'primera', createdAt: 1000);
      await insertMessage(
        id: 'other',
        conversationId: 'conv-2',
        content: 'otra conversación',
        createdAt: 1500,
      );

      final rows = await datasource.watchMessages('conv-1').first;

      expect(rows.map((row) => row.content), ['primera', 'segunda']);
    });

    test('breaks a same-millisecond tie by id so the turn never swaps order',
        () async {
      await insertMessage(
          id: 'b-assistant', content: 'respuesta', createdAt: 7);
      await insertMessage(id: 'a-user', content: 'pregunta', createdAt: 7);

      final rows = await datasource.watchMessages('conv-1').first;

      expect(rows.map((row) => row.content), ['pregunta', 'respuesta']);
    });

    test('re-emits after a write so the thread stays live', () async {
      await insertMessage(id: 'm1', createdAt: 1000);
      final emissions = datasource.watchMessages('conv-1').take(2).toList();

      await insertMessage(id: 'm2', content: 'segunda', createdAt: 2000);

      final results = await emissions;
      expect(results.first, hasLength(1));
      expect(results.last, hasLength(2));
    });
  });

  group('upsertMessage', () {
    test('re-appending the same id updates the row instead of duplicating it',
        () async {
      final pending = AiMessage(
        id: 'm1',
        conversationId: 'conv-1',
        role: AiMessageRole.user,
        content: '¿cuánto gasté?',
        createdAt: DateTime(2026, 8, 25, 9),
        status: AiMessageStatus.pending,
      );

      await datasource.upsertMessage(AiMessageMapper.toCompanion(pending));
      await datasource.upsertMessage(
        AiMessageMapper.toCompanion(
          pending.copyWith(status: AiMessageStatus.sent),
        ),
      );

      final rows = await datasource.watchMessages('conv-1').first;
      expect(rows, hasLength(1));
      expect(rows.single.status, 'sent');
    });

    test('stores createdAt as epoch millis, not seconds', () async {
      final createdAt = DateTime.utc(2026, 8, 25, 9, 30, 15, 250);

      await datasource.upsertMessage(
        AiMessageMapper.toCompanion(
          AiMessage(
            id: 'm1',
            conversationId: 'conv-1',
            role: AiMessageRole.assistant,
            content: 'Hola',
            createdAt: createdAt,
            status: AiMessageStatus.sent,
          ),
        ),
      );

      final row = await datasource.findById('m1');
      expect(row!.createdAt, createdAt.millisecondsSinceEpoch);
    });
  });

  group('updateProposalsJson', () {
    test('rewrites only the proposals column of the addressed row', () async {
      await insertMessage(id: 'm1', proposalsJson: '[]');
      await insertMessage(id: 'm2', proposalsJson: '[]');

      await datasource.updateProposalsJson(
        id: 'm1',
        proposalsJson: '[{"id":"tc_0_0"}]',
      );

      expect((await datasource.findById('m1'))!.proposalsJson,
          '[{"id":"tc_0_0"}]');
      expect((await datasource.findById('m2'))!.proposalsJson, '[]');
      expect((await datasource.findById('m1'))!.content, 'Hola');
    });

    test('clearing the column back to null is possible', () async {
      await insertMessage(id: 'm1', proposalsJson: '[]');

      await datasource.updateProposalsJson(id: 'm1', proposalsJson: null);

      expect((await datasource.findById('m1'))!.proposalsJson, isNull);
    });
  });

  group('lastConversationId', () {
    test('is null when nobody has ever talked to the assistant here', () async {
      expect(await datasource.lastConversationId(), isNull);
    });

    test('is the conversation of the most recent message', () async {
      await insertMessage(id: 'm1', createdAt: 1000);
      await insertMessage(
        id: 'm2',
        conversationId: 'conv-2',
        createdAt: 5000,
      );

      expect(await datasource.lastConversationId(), 'conv-2');
    });
  });

  group('deleteConversation', () {
    test('erases one thread and leaves the others untouched', () async {
      await insertMessage(id: 'm1');
      await insertMessage(id: 'm2', conversationId: 'conv-2');

      await datasource.deleteConversation('conv-1');

      expect(await datasource.watchMessages('conv-1').first, isEmpty);
      expect(await datasource.watchMessages('conv-2').first, hasLength(1));
    });
  });

  group('values this build does not know', () {
    test('an unfamiliar role or status does not take down the read', () async {
      await insertMessage(
        id: 'm1',
        role: 'oracle',
        status: 'half_sent',
        createdAt: 1000,
      );

      final rows = await datasource.watchMessages('conv-1').first;
      final entity = AiMessageMapper.toEntity(rows.single);

      expect(entity.role, AiMessageRole.assistant);
      expect(entity.status, AiMessageStatus.sent);
    });

    test('proposals stored as malformed JSON yield no cards, not an exception',
        () async {
      await insertMessage(id: 'm1', proposalsJson: '{not json');

      final rows = await datasource.watchMessages('conv-1').first;

      expect(AiMessageMapper.toEntity(rows.single).proposals, isEmpty);
      expect(AiMessageMapper.toEntity(rows.single).content, 'Hola');
    });
  });
}
