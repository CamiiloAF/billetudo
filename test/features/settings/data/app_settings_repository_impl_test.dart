import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/ai/domain/entities/ai_consent.dart';
import 'package:billetudo/features/settings/data/datasources/app_settings_local_datasource.dart';
import 'package:billetudo/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late AppSettingsRepositoryImpl repository;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    repository = AppSettingsRepositoryImpl(
      AppSettingsLocalDatasource(database),
    );
  });

  tearDown(() async => database.close());

  group('watchSettings', () {
    test('emits AppSettings.defaults() when the singleton row is missing',
        () async {
      final result = await repository.watchSettings().first;

      expect(
        result.getRight().toNullable(),
        const AppSettings.defaults(),
      );
    });

    test('emits the persisted flag once it has been set', () async {
      await repository.setZeroBasedEnabled(enabled: true);

      final result = await repository.watchSettings().first;

      expect(result.getRight().toNullable()!.zeroBasedEnabled, isTrue);
    });

    test('re-emits when the flag is toggled again', () async {
      final values = <bool>[];
      final subscription = repository.watchSettings().listen((result) {
        values.add(result.getRight().toNullable()!.zeroBasedEnabled);
      });
      // Let the initial "missing row" emission land before the first write,
      // so it is not coalesced with it (Drift batches invalidations that
      // land in the same microtask).
      await Future<void>.delayed(Duration.zero);

      await repository.setZeroBasedEnabled(enabled: true);
      await Future<void>.delayed(Duration.zero);
      await repository.setZeroBasedEnabled(enabled: false);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(values, [false, true, false]);
    });
  });

  group('setZeroBasedEnabled', () {
    test('upserts the singleton row instead of creating a second one',
        () async {
      await repository.setZeroBasedEnabled(enabled: true);
      await repository.setZeroBasedEnabled(enabled: false);

      final rows = await database.select(database.appSettings).get();

      expect(rows, hasLength(1));
      expect(rows.single.id, AppSettingsLocalDatasource.singletonId);
      expect(rows.single.zeroBasedEnabled, isFalse);
    });

    test('stamps updatedAt on every write', () async {
      await repository.setZeroBasedEnabled(enabled: true);
      final first = await database.select(database.appSettings).getSingle();

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.setZeroBasedEnabled(enabled: false);
      final second = await database.select(database.appSettings).getSingle();

      expect(second.updatedAt, greaterThan(first.updatedAt));
    });
  });

  group('setFeaturedBudget', () {
    test(
        'persists the picked budget id, flips featuredBudgetMode to manual, '
        'and reflects both in _toEntity', () async {
      await repository.setFeaturedBudget(budgetId: 'budget-1');

      final result = await repository.getSettings();
      final settings = result.getRight().toNullable()!;

      expect(settings.featuredBudgetId, 'budget-1');
      expect(settings.featuredBudgetMode, FeaturedBudgetMode.manual);
    });

    test('stamps updatedAt on write', () async {
      await repository.setFeaturedBudget(budgetId: 'budget-1');
      final first = await database.select(database.appSettings).getSingle();

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.setFeaturedBudget(budgetId: 'budget-2');
      final second = await database.select(database.appSettings).getSingle();

      expect(second.updatedAt, greaterThan(first.updatedAt));
    });

    test('upserts the singleton row instead of creating a second one',
        () async {
      await repository.setFeaturedBudget(budgetId: 'budget-1');

      final rows = await database.select(database.appSettings).get();

      expect(rows, hasLength(1));
      expect(rows.single.id, AppSettingsLocalDatasource.singletonId);
    });
  });

  group('clearFeaturedBudget', () {
    test(
        'resets featuredBudgetId to null and featuredBudgetMode to none, '
        'not automatic', () async {
      await repository.setFeaturedBudget(budgetId: 'budget-1');

      await repository.clearFeaturedBudget();

      final result = await repository.getSettings();
      final settings = result.getRight().toNullable()!;

      expect(settings.featuredBudgetId, isNull);
      expect(settings.featuredBudgetMode, FeaturedBudgetMode.none);
    });

    test('stamps updatedAt on write', () async {
      await repository.setFeaturedBudget(budgetId: 'budget-1');
      final first = await database.select(database.appSettings).getSingle();

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.clearFeaturedBudget();
      final second = await database.select(database.appSettings).getSingle();

      expect(second.updatedAt, greaterThan(first.updatedAt));
    });
  });

  group('markOnboardingCompleted', () {
    test('turns the latch on and upserts the singleton row', () async {
      await repository.markOnboardingCompleted();

      final rows = await database.select(database.appSettings).get();

      expect(rows, hasLength(1));
      expect(rows.single.id, AppSettingsLocalDatasource.singletonId);
      expect(rows.single.onboardingCompleted, isTrue);
    });

    test('is reflected by getSettings', () async {
      await repository.markOnboardingCompleted();

      final result = await repository.getSettings();

      expect(result.getRight().toNullable()!.onboardingCompleted, isTrue);
    });
  });

  group('AI notes access and consent version', () {
    Future<AppSettings> read() async =>
        (await repository.getSettings()).getRight().toNullable()!;

    test('notes access is off by default — nobody has to opt out', () async {
      expect((await read()).aiNotesAccessEnabled, isFalse);
    });

    test('round-trips the opt-in through the singleton row', () async {
      await repository.setAiNotesAccessEnabled(enabled: true);
      expect((await read()).aiNotesAccessEnabled, isTrue);

      await repository.setAiNotesAccessEnabled(enabled: false);
      expect((await read()).aiNotesAccessEnabled, isFalse);
    });

    test('stamps the consent version alongside the timestamp, in one write',
        () async {
      await repository.markAiConsentAccepted();

      final row = await database.select(database.appSettings).getSingle();
      expect(row.aiConsentAcceptedAt, isNotNull);
      expect(row.aiConsentVersion, currentAiConsentVersion);

      final settings = await read();
      expect(settings.aiConsentVersion, currentAiConsentVersion);
      expect(settings.hasAcceptedAiConsent, isTrue);
    });

    test(
        'a NULL version reads as 0, so an unversioned acceptance is not '
        'treated as consent to the current copy', () async {
      await repository.markAiConsentAccepted();
      await database.customStatement(
        'UPDATE app_settings SET ai_consent_version = NULL',
      );

      final settings = await read();

      expect(settings.aiConsentVersion, 0);
      expect(settings.aiConsentAcceptedAt, isNotNull);
      expect(settings.hasAcceptedAiConsent, isFalse);
    });

    test('turning notes access on does not touch the consent columns',
        () async {
      await repository.markAiConsentAccepted();
      final before = await database.select(database.appSettings).getSingle();

      await repository.setAiNotesAccessEnabled(enabled: true);
      final after = await database.select(database.appSettings).getSingle();

      expect(after.aiConsentAcceptedAt, before.aiConsentAcceptedAt);
      expect(after.aiConsentVersion, before.aiConsentVersion);
      expect(after.aiNotesAccessEnabled, isTrue);
    });

    test(
        'withdrawing the consent (RGPD art. 7.3) clears both consent columns '
        'AND turns the notes opt-in off — leaving it on would be a permission '
        'the person believes they just cancelled', () async {
      await repository.markAiConsentAccepted();
      await repository.setAiNotesAccessEnabled(enabled: true);
      expect((await read()).aiNotesAccessEnabled, isTrue);

      await repository.clearAiConsent();

      final row = await database.select(database.appSettings).getSingle();
      expect(row.aiConsentAcceptedAt, isNull);
      expect(row.aiConsentVersion, isNull);
      expect(row.aiNotesAccessEnabled, isFalse);

      final settings = await read();
      expect(settings.hasAcceptedAiConsent, isFalse);
      expect(settings.aiNotesAccessEnabled, isFalse);
    });

    test('withdrawing bumps updatedAt, like every other write', () async {
      await repository.markAiConsentAccepted();
      final before = await database.select(database.appSettings).getSingle();
      await Future<void>.delayed(const Duration(milliseconds: 2));

      await repository.clearAiConsent();

      final after = await database.select(database.appSettings).getSingle();
      expect(after.updatedAt, greaterThan(before.updatedAt));
    });

    test(
        'withdrawing is idempotent and safe on a row that never consented: '
        'the gate simply stays closed', () async {
      await repository.clearAiConsent();
      await repository.clearAiConsent();

      final settings = await read();
      expect(settings.hasAcceptedAiConsent, isFalse);
      expect(settings.aiNotesAccessEnabled, isFalse);
    });

    test(
        're-accepting after a withdrawal grants consent again, with the notes '
        'opt-in still off — it is not silently restored', () async {
      await repository.markAiConsentAccepted();
      await repository.setAiNotesAccessEnabled(enabled: true);
      await repository.clearAiConsent();

      await repository.markAiConsentAccepted();

      final settings = await read();
      expect(settings.hasAcceptedAiConsent, isTrue);
      expect(settings.aiNotesAccessEnabled, isFalse);
    });

    test(
        'the withdrawal is persisted, not held in memory: a brand-new '
        'repository over the same database reads the gate as closed', () async {
      await repository.markAiConsentAccepted();
      await repository.clearAiConsent();

      final reopened = AppSettingsRepositoryImpl(
        AppSettingsLocalDatasource(database),
      );
      final settings = (await reopened.getSettings()).getRight().toNullable()!;

      expect(settings.hasAcceptedAiConsent, isFalse);
    });
  });
}
