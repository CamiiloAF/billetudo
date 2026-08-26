import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift queries for `AiMessages`, the local transcript.
///
/// The table is **local-only** (`Table.localOnly('ai_messages', …)` in
/// `powersync_schema.dart`): the broker keeps no copy of a conversation and
/// neither does Postgres, so this device holds the only one. That also means
/// there is no `deletedAt`/`tombstonedAt` to guard here — nothing references
/// these rows, and clearing a thread is a real `DELETE`.
///
/// A plain injected class rather than a `@DriftAccessor`, same as
/// `GoalsLocalDatasource`: no tables are declared here.
@lazySingleton
class AiHistoryLocalDatasource {
  const AiHistoryLocalDatasource(this._db);

  final AppDatabase _db;

  /// One thread, oldest first, as a live query.
  ///
  /// `id` breaks ties on [AiMessages.createdAt]: the column is epoch millis,
  /// and the user bubble plus its assistant reply can land inside the same
  /// millisecond on a fast turn. Without a tiebreaker the two would swap
  /// places between rebuilds.
  Stream<List<AiMessage>> watchMessages(String conversationId) =>
      (_db.select(_db.aiMessages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([
              (m) => OrderingTerm.asc(m.createdAt),
              (m) => OrderingTerm.asc(m.id),
            ]))
          .watch();

  /// Writes a message, replacing any row with the same id.
  ///
  /// Replace rather than plain insert because a user bubble is persisted the
  /// instant it is typed (status `pending`) and re-appended with the same id
  /// once the turn lands or fails — that is how the thread survives losing
  /// signal mid-turn without growing a duplicate.
  Future<void> upsertMessage(AiMessagesCompanion companion) =>
      _db.into(_db.aiMessages).insert(companion, mode: InsertMode.replace);

  Future<AiMessage?> findById(String id) =>
      (_db.select(_db.aiMessages)..where((m) => m.id.equals(id)))
          .getSingleOrNull();

  Future<void> updateProposalsJson({
    required String id,
    required String? proposalsJson,
  }) =>
      (_db.update(_db.aiMessages)..where((m) => m.id.equals(id)))
          .write(AiMessagesCompanion(proposalsJson: Value(proposalsJson)));

  /// The conversation of the most recent message, or `null` when the user has
  /// never talked to the assistant on this device.
  Future<String?> lastConversationId() async {
    final row = await (_db.select(_db.aiMessages)
          ..orderBy([
            (m) => OrderingTerm.desc(m.createdAt),
            (m) => OrderingTerm.desc(m.id),
          ])
          ..limit(1))
        .getSingleOrNull();
    return row?.conversationId;
  }

  Future<void> deleteConversation(String conversationId) =>
      (_db.delete(_db.aiMessages)
            ..where((m) => m.conversationId.equals(conversationId)))
          .go();

  /// Every message currently on the device, across every thread. Irreversible
  /// — same shape as [deleteConversation], just without the `where`.
  Future<void> deleteAll() => _db.delete(_db.aiMessages).go();

  /// One row per thread: its `conversationId`, the timestamp of its most
  /// recent message, and its total message count.
  ///
  /// This is a separate query from [firstUserMessages] rather than one query
  /// with a window function: Drift's query builder has no `FIRST_VALUE`/
  /// `ROW_NUMBER` support, and two simple `groupBy`/`orderBy` queries kept in
  /// sync by the repository are far easier to read and to test in isolation
  /// than a hand-written window-function fragment glued on with
  /// `customSelect`.
  ///
  /// Live: any write to `AiMessages` (a new turn, a clear) recomputes and
  /// re-emits, which is what lets the history list refresh itself while a
  /// conversation is still open elsewhere in the app.
  Stream<List<ConversationSummaryRow>> watchConversationSummaries() {
    final countRef = _db.aiMessages.id.count();
    final lastRef = _db.aiMessages.createdAt.max();
    final query = _db.selectOnly(_db.aiMessages)
      ..addColumns([_db.aiMessages.conversationId, countRef, lastRef])
      ..groupBy([_db.aiMessages.conversationId]);
    return query.watch().map(
          (rows) => [
            for (final row in rows)
              ConversationSummaryRow(
                conversationId: row.read(_db.aiMessages.conversationId)!,
                messageCount: row.read(countRef)!,
                lastMessageAt: row.read(lastRef)!,
              ),
          ],
        );
  }

  /// The first `role='user'` message of every thread, oldest first within
  /// each thread. Used to derive a conversation's title without it drifting
  /// as the user keeps chatting.
  Future<List<AiMessage>> firstUserMessages() async {
    final all = await (_db.select(_db.aiMessages)
          ..where((m) => m.role.equals('user'))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .get();
    final seen = <String>{};
    return [
      for (final row in all)
        if (seen.add(row.conversationId)) row,
    ];
  }
}

/// Aggregates for one thread: how many messages it has and when the most
/// recent one landed. Package-private to `data/` — `AiHistoryRepositoryImpl`
/// is the only consumer, and it turns this into an `AiConversation`.
class ConversationSummaryRow {
  const ConversationSummaryRow({
    required this.conversationId,
    required this.messageCount,
    required this.lastMessageAt,
  });

  final String conversationId;
  final int messageCount;
  final int lastMessageAt;
}
