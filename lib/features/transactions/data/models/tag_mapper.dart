import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/tag.dart';

/// Translates between Drift's generated `Tag` rows and the domain [Tag]
/// entity. The only place where the generated type meets the domain.
abstract final class TagMapper {
  static Tag toEntity(db.Tag row) => Tag(
        id: row.id,
        name: row.name,
        color: row.color,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static db.TagsCompanion toInsertCompanion(
    String name, {
    required DateTime now,
  }) =>
      db.TagsCompanion.insert(
        name: name,
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );
}
