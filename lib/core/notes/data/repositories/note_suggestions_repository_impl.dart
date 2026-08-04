import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../database/app_database.dart';
import '../../domain/repositories/note_suggestions_repository.dart';

/// Drift implementation of [NoteSuggestionsRepository].
///
/// Combines the four tables that today capture a free-text "nota"
/// (`transactions`, `goal_contributions`, `debt_entries`,
/// `scheduled_payments`) into a single UNION ALL, then groups by note text
/// case-insensitively so "Almuerzo" and "almuerzo" count as the same
/// suggestion. Read-only: this never writes `updatedAt`, there is nothing to
/// stamp here.
@LazySingleton(as: NoteSuggestionsRepository)
class NoteSuggestionsRepositoryImpl implements NoteSuggestionsRepository {
  const NoteSuggestionsRepositoryImpl(this._db);

  final AppDatabase _db;

  /// Matches `GetNoteSuggestions.maxSuggestions` — kept as a literal here
  /// too so this repository's own query is self-contained and correct even
  /// if called directly.
  static const int _limit = 10;

  @override
  Future<List<String>> suggest(String query) async {
    final likePattern = '%$query%';
    final rows = await _db
        .customSelect(
          '''
      SELECT note, COUNT(*) AS uses, MAX(updated_at) AS last_used
      FROM (
        SELECT note, updated_at FROM transactions
          WHERE note IS NOT NULL AND TRIM(note) != ''
            AND deleted_at IS NULL AND tombstoned_at IS NULL
            AND note LIKE ? COLLATE NOCASE
        UNION ALL
        SELECT note, updated_at FROM goal_contributions
          WHERE note IS NOT NULL AND TRIM(note) != ''
            AND deleted_at IS NULL AND tombstoned_at IS NULL
            AND note LIKE ? COLLATE NOCASE
        UNION ALL
        SELECT note, updated_at FROM debt_entries
          WHERE note IS NOT NULL AND TRIM(note) != ''
            AND deleted_at IS NULL AND tombstoned_at IS NULL
            AND note LIKE ? COLLATE NOCASE
        UNION ALL
        SELECT note, updated_at FROM scheduled_payments
          WHERE note IS NOT NULL AND TRIM(note) != ''
            AND deleted_at IS NULL AND tombstoned_at IS NULL
            AND note LIKE ? COLLATE NOCASE
      ) AS notes
      GROUP BY note COLLATE NOCASE
      ORDER BY uses DESC, last_used DESC
      LIMIT $_limit
      ''',
          variables: [
            Variable<String>(likePattern),
            Variable<String>(likePattern),
            Variable<String>(likePattern),
            Variable<String>(likePattern),
          ],
          readsFrom: {
            _db.transactions,
            _db.goalContributions,
            _db.debtEntries,
            _db.scheduledPayments,
          },
        )
        .get();

    return rows.map((row) => row.read<String>('note')).toList();
  }
}
