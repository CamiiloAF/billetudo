import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/transactions/data/datasources/tags_local_datasource.dart';
import 'package:billetudo/features/transactions/data/repositories/tag_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late TagRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = TagRepositoryImpl(TagsLocalDatasource(database));
  });

  tearDown(() async => database.close());

  group('createTag (HU-07)', () {
    test('persiste la etiqueta con id UUID', () async {
      final result = await repository.createTag('viaje');

      final tag = result.getRight().toNullable()!;
      expect(tag.id, hasLength(36));
      expect(tag.name, 'viaje');
    });
  });

  group('findTagByName', () {
    test('encuentra sin distinguir mayúsculas/minúsculas', () async {
      await repository.createTag('Viaje');

      final result = await repository.findTagByName('viaje');

      expect(result.getRight().toNullable()?.name, 'Viaje');
    });

    test('devuelve null cuando no existe', () async {
      final result = await repository.findTagByName('inexistente');

      expect(result.getRight().toNullable(), isNull);
    });
  });

  group('watchTags', () {
    test('emite la lista ordenada alfabéticamente', () async {
      await repository.createTag('zeta');
      await repository.createTag('alfa');

      final result = await repository.watchTags().first;

      expect(
        result.getRight().toNullable()!.map((t) => t.name),
        ['alfa', 'zeta'],
      );
    });

    test('reacciona a una etiqueta nueva', () async {
      final emissions = <int>[];
      final subscription = repository
          .watchTags()
          .listen((r) => emissions.add(r.getRight().toNullable()!.length));
      await pumpEventQueue();

      await repository.createTag('viaje');
      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions.first, 0);
      expect(emissions.last, 1);
    });
  });
}
