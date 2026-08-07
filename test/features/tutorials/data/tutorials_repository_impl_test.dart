import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/tutorials/data/datasources/tutorial_views_local_datasource.dart';
import 'package:billetudo/features/tutorials/data/repositories/tutorials_repository_impl.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late TutorialsRepositoryImpl repository;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    repository = TutorialsRepositoryImpl(
      TutorialViewsLocalDatasource(database),
    );
  });

  tearDown(() async => database.close());

  group('hasSeen / markSeen', () {
    test('a tutorial that was never marked has not been seen', () async {
      final result = await repository.hasSeen(TutorialKey.budgetsScreen);

      expect(result.getRight().toNullable(), isFalse);
    });

    test('marking a tutorial seen makes hasSeen return true', () async {
      await repository.markSeen(TutorialKey.budgetsScreen);

      final result = await repository.hasSeen(TutorialKey.budgetsScreen);

      expect(result.getRight().toNullable(), isTrue);
    });

    test('marking the same tutorial seen twice is a no-op, not an error',
        () async {
      await repository.markSeen(TutorialKey.goalsScreen);
      final second = await repository.markSeen(TutorialKey.goalsScreen);

      expect(second.isRight(), isTrue);
      final rows = await database.select(database.tutorialViews).get();
      expect(
          rows.where((r) => r.id == TutorialKey.goalsScreen.id), hasLength(1));
    });

    test('persists a row keyed by the tutorial\'s stable id, not a UUID',
        () async {
      await repository.markSeen(TutorialKey.debtLinkMovement);

      final rows = await database.select(database.tutorialViews).get();

      expect(rows.single.id, 'tutorial-debt-link-movement');
    });

    test('seeing one tutorial does not affect another', () async {
      await repository.markSeen(TutorialKey.budgetsScreen);

      final result = await repository.hasSeen(TutorialKey.goalsScreen);

      expect(result.getRight().toNullable(), isFalse);
    });
  });

  group('resetAll', () {
    test('clears every seen tutorial so they can appear again', () async {
      await repository.markSeen(TutorialKey.budgetsScreen);
      await repository.markSeen(TutorialKey.goalsScreen);
      await repository.markSeen(TutorialKey.debtScheduledInstallment);

      final reset = await repository.resetAll();

      expect(reset.isRight(), isTrue);
      final rows = await database.select(database.tutorialViews).get();
      expect(rows, isEmpty);
      final result = await repository.hasSeen(TutorialKey.budgetsScreen);
      expect(result.getRight().toNullable(), isFalse);
    });
  });

  group('watchHelpEnabled / setHelpEnabled', () {
    test('defaults to true for a freshly-seeded singleton row', () async {
      final result = await repository.watchHelpEnabled().first;

      expect(result.getRight().toNullable(), isTrue);
    });

    test('setHelpEnabled(false) is reflected by watchHelpEnabled', () async {
      await repository.setHelpEnabled(enabled: false);

      final result = await repository.watchHelpEnabled().first;

      expect(result.getRight().toNullable(), isFalse);
    });

    test('setHelpEnabled upserts the singleton row instead of a second one',
        () async {
      await repository.setHelpEnabled(enabled: false);
      await repository.setHelpEnabled(enabled: true);

      final rows = await database.select(database.appSettings).get();

      expect(rows, hasLength(1));
      expect(rows.single.showHelpOnSectionEntry, isTrue);
    });

    test('stamps updatedAt on every write', () async {
      await repository.setHelpEnabled(enabled: false);
      final first = await database.select(database.appSettings).getSingle();

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.setHelpEnabled(enabled: true);
      final second = await database.select(database.appSettings).getSingle();

      expect(second.updatedAt, greaterThan(first.updatedAt));
    });

    test('re-emits when toggled again', () async {
      final values = <bool>[];
      final subscription = repository.watchHelpEnabled().listen((result) {
        values.add(result.getRight().toNullable()!);
      });
      await Future<void>.delayed(Duration.zero);

      await repository.setHelpEnabled(enabled: false);
      await Future<void>.delayed(Duration.zero);
      await repository.setHelpEnabled(enabled: true);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(values, [true, false, true]);
    });
  });
}
