import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/transactions/data/models/tag_mapper.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../transaction_fixtures.dart';

void main() {
  test('toEntity mapea cada campo', () {
    final row = db.Tag(
      id: 'tag-1',
      name: 'viaje',
      color: 'mint',
      createdAt: testInstant,
      updatedAt: testInstantMillis,
    );

    final entity = TagMapper.toEntity(row);

    expect(entity.id, 'tag-1');
    expect(entity.name, 'viaje');
    expect(entity.color, 'mint');
  });

  test('toInsertCompanion estampa createdAt/updatedAt y deja el id al default',
      () {
    final companion = TagMapper.toInsertCompanion('viaje', now: testInstant);

    expect(companion.name.value, 'viaje');
    expect(companion.id, const Value<String>.absent());
    expect(companion.createdAt, Value(testInstant));
    expect(companion.updatedAt, Value(testInstantMillis));
  });
}
