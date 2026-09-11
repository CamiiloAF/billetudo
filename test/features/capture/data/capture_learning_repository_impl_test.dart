import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/capture/data/datasources/merchant_learning_local_datasource.dart';
import 'package:billetudo/features/capture/data/repositories/capture_learning_repository_impl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late CaptureLearningRepositoryImpl repository;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    repository = CaptureLearningRepositoryImpl(
      MerchantLearningLocalDatasource(database),
      const NoopCrashReporter(),
    );
  });

  tearDown(() async => database.close());

  Future<db.Category> createCategory(String name) =>
      database.into(database.categories).insertReturning(
            db.CategoriesCompanion.insert(
              name: name,
              kind: db.CategoryKind.expense,
            ),
          );

  Future<db.MerchantCategoryLearningData> storedRow() async =>
      (await database.select(database.merchantCategoryLearning).get()).single;

  test('learning a merchant makes it suggestible', () async {
    final category = await createCategory('Mercado');

    await repository.learnMerchantCategory(
      merchantKey: 'EXITO CALLE 80',
      categoryId: category.id,
    );
    final suggestion = await repository.suggestedCategoryFor('EXITO CALLE 80');

    expect(suggestion.getOrElse((_) => null), category.id);
  });

  test('stamps updatedAt and starts the hit count at one', () async {
    final category = await createCategory('Mercado');

    await repository.learnMerchantCategory(
      merchantKey: 'EXITO',
      categoryId: category.id,
    );

    final row = await storedRow();
    expect(row.hitCount, 1);
    expect(row.updatedAt, greaterThan(0));
  });

  test('re-confirming the same pairing reinforces it', () async {
    final category = await createCategory('Mercado');

    await repository.learnMerchantCategory(
      merchantKey: 'EXITO',
      categoryId: category.id,
    );
    await repository.learnMerchantCategory(
      merchantKey: 'EXITO',
      categoryId: category.id,
    );

    expect((await storedRow()).hitCount, 2);
  });

  test('a different category rewrites the association', () async {
    final groceries = await createCategory('Mercado');
    final restaurants = await createCategory('Restaurantes');

    await repository.learnMerchantCategory(
      merchantKey: 'RAPPI',
      categoryId: groceries.id,
    );
    await repository.learnMerchantCategory(
      merchantKey: 'RAPPI',
      categoryId: restaurants.id,
    );

    final row = await storedRow();
    expect(row.categoryId, restaurants.id);
    expect(row.hitCount, 1);
  });

  test('stops suggesting a category the user deleted', () async {
    final category = await createCategory('Mercado');
    await repository.learnMerchantCategory(
      merchantKey: 'EXITO',
      categoryId: category.id,
    );

    await (database.update(database.categories)
          ..where((t) => t.id.equals(category.id)))
        .write(
      db.CategoriesCompanion(deletedAt: Value(DateTime.now())),
    );
    final suggestion = await repository.suggestedCategoryFor('EXITO');

    expect(suggestion.getOrElse((_) => 'x'), isNull);
  });

  test('suggests nothing for an unknown merchant', () async {
    final suggestion = await repository.suggestedCategoryFor('DESCONOCIDO');

    expect(suggestion.getOrElse((_) => 'x'), isNull);
  });

  test('forgetting one association deletes the row physically', () async {
    final category = await createCategory('Mercado');
    await repository.learnMerchantCategory(
      merchantKey: 'EXITO',
      categoryId: category.id,
    );

    await repository.forgetMerchant('EXITO');

    expect(
      await database.select(database.merchantCategoryLearning).get(),
      isEmpty,
    );
  });

  test('forgetting everything leaves no learning behind', () async {
    final category = await createCategory('Mercado');
    await repository.learnMerchantCategory(
      merchantKey: 'EXITO',
      categoryId: category.id,
    );
    await repository.learnMerchantCategory(
      merchantKey: 'RAPPI',
      categoryId: category.id,
    );

    await repository.forgetAllLearning();

    expect(
      await database.select(database.merchantCategoryLearning).get(),
      isEmpty,
    );
    expect(await database.select(database.categories).get(), hasLength(1));
  });
}
