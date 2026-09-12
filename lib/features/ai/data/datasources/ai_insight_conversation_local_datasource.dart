import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift queries for `AiInsightConversations`, the local-only link between a
/// Home AI insight chip (`HomeAiInsightType`, kept out of this file per the
/// table's own doc comment) and the thread it started.
///
/// A plain injected class rather than a `@DriftAccessor`, same as
/// [AiHistoryLocalDatasource]: no tables are declared here.
@lazySingleton
class AiInsightConversationLocalDatasource {
  const AiInsightConversationLocalDatasource(this._db);

  final AppDatabase _db;

  /// The current `conversationId` for [insightType], or `null` when no chip
  /// of that kind has ever started one. Append-only table (see its own doc):
  /// the current row is the most recent by `createdAt`, never a unique lookup.
  Future<String?> latestConversationId(String insightType) async {
    final row = await (_db.select(_db.aiInsightConversations)
          ..where((t) => t.insightType.equals(insightType))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.conversationId;
  }

  /// Appends a new link row. Never updates or replaces an existing one —
  /// the table is append-only by design (its own doc comment).
  Future<void> insertLink({
    required String insightType,
    required String conversationId,
  }) =>
      _db.into(_db.aiInsightConversations).insert(
            AiInsightConversationsCompanion.insert(
              insightType: insightType,
              conversationId: conversationId,
            ),
          );
}
