import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift queries for `HomeInsightEvents`, the local-only "shown"/"dismissed"
/// ledger for the Home AI card's insight (`HomeAiInsightType`, kept out of
/// this file per the table's own doc comment).
///
/// A plain injected class rather than a `@DriftAccessor`, same as
/// `AiInsightConversationLocalDatasource`: no tables are declared here.
@lazySingleton
class HomeInsightEventLocalDatasource {
  const HomeInsightEventLocalDatasource(this._db);

  final AppDatabase _db;

  /// Every event ever recorded, as a live query — the repository reduces
  /// this into "the latest per `(insightType, kind)`" itself, since the
  /// table is append-only (its own doc comment) and holds at most a handful
  /// of rows.
  Stream<List<HomeInsightEvent>> watchAll() =>
      _db.select(_db.homeInsightEvents).watch();

  /// Appends a new event row. Never updates or replaces an existing one —
  /// the table is append-only by design (its own doc comment).
  Future<void> insertEvent({
    required String insightType,
    required String kind,
  }) =>
      _db.into(_db.homeInsightEvents).insert(
            HomeInsightEventsCompanion.insert(
              insightType: insightType,
              kind: kind,
            ),
          );
}
