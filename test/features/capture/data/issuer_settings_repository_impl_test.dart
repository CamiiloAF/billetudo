import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/data/datasources/issuer_catalog.dart';
import 'package:billetudo/features/capture/data/datasources/issuer_settings_preference_datasource.dart';
import 'package:billetudo/features/capture/data/repositories/issuer_settings_repository_impl.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_catalog_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late IssuerSettingsPreferenceDatasource preferences;
  late IssuerSettingsRepositoryImpl repository;

  final firstIssuer = launchIssuerCatalog.first.packageName;
  final secondIssuer = launchIssuerCatalog[1].packageName;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = IssuerSettingsPreferenceDatasource(SharedPreferencesAsync());
    repository = IssuerSettingsRepositoryImpl(
      preferences,
      const NoopCrashReporter(),
    );
  });

  tearDown(() async => preferences.dispose());

  List<IssuerCatalogEntry> noIssuers(Failure _) => const <IssuerCatalogEntry>[];

  test('every issuer starts off: a fresh install captures nothing', () async {
    final catalog = await repository.getIssuerCatalog();

    final entries = catalog.getOrElse(noIssuers);
    expect(entries, hasLength(launchIssuerCatalog.length));
    expect(entries.every((issuer) => !issuer.enabled), isTrue);
  });

  test('the catalog carries both banks and wallets', () async {
    final catalog = await repository.getIssuerCatalog();

    final kinds =
        catalog.getOrElse(noIssuers).map((issuer) => issuer.kind).toSet();
    expect(
        kinds, containsAll(<IssuerKind>[IssuerKind.bank, IssuerKind.wallet]));
  });

  test('turning one issuer on leaves the others off', () async {
    await repository.setIssuerEnabled(
      packageName: firstIssuer,
      enabled: true,
    );

    final entries = (await repository.getIssuerCatalog()).getOrElse(noIssuers);
    expect(
      entries.where((issuer) => issuer.enabled).map((i) => i.packageName),
      [firstIssuer],
    );
  });

  test('turning an issuer off stops it capturing', () async {
    await repository.setIssuerEnabled(packageName: firstIssuer, enabled: true);
    await repository.setIssuerEnabled(packageName: firstIssuer, enabled: false);

    final entries = (await repository.getIssuerCatalog()).getOrElse(noIssuers);
    expect(entries.where((issuer) => issuer.enabled), isEmpty);
  });

  test('refuses a package outside the curated catalog', () async {
    final result = await repository.setIssuerEnabled(
      packageName: 'com.whatsapp',
      enabled: true,
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    final entries = (await repository.getIssuerCatalog()).getOrElse(noIssuers);
    expect(entries.where((issuer) => issuer.enabled), isEmpty);
  });

  test('turns every issuer off in one action', () async {
    await repository.setIssuerEnabled(packageName: firstIssuer, enabled: true);
    await repository.setIssuerEnabled(packageName: secondIssuer, enabled: true);

    await repository.disableAllIssuers();

    final entries = (await repository.getIssuerCatalog()).getOrElse(noIssuers);
    expect(entries.where((issuer) => issuer.enabled), isEmpty);
  });

  test('re-emits the catalog after every change', () async {
    final emissions = <List<IssuerCatalogEntry>>[];
    final subscription = repository.watchIssuerCatalog().listen(
          (result) => emissions.add(result.getOrElse(noIssuers)),
        );

    await Future<void>.delayed(Duration.zero);
    await repository.setIssuerEnabled(packageName: firstIssuer, enabled: true);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(emissions.length, greaterThanOrEqualTo(2));
    expect(emissions.first.where((issuer) => issuer.enabled), isEmpty);
    expect(emissions.last.where((issuer) => issuer.enabled), hasLength(1));
  });
}
