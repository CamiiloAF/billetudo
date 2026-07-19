import 'dart:io';

import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/security/secure_storage_service.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/features/accounts/domain/repositories/account_repository.dart';
import 'package:billetudo/features/accounts/domain/usecases/create_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/categories/domain/repositories/category_repository.dart';
import 'package:billetudo/features/categories/domain/usecases/create_category.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Every test in this file calls `configureDependencies()` fresh (see
  // `setUp` below), which builds a new `AppDatabase` wrapper on top of the
  // same `PowerSyncDatabase` connection opened once in `setUpAll`. Drift
  // warns about that pattern by default (it usually signals two independent
  // connections to the same file); here it is intentional, so silence it.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    // `AuthCubit` is an eager singleton that resolves down to `SupabaseClient`
    // (see `register_module.dart`), so the graph needs a real (if offline)
    // Supabase instance to build — same as `bootstrap.dart` does before
    // `configureDependencies()`.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );

    // `AppDatabase` now opens on top of the PowerSync-managed connection (see
    // `register_module.dart` and decision #6, docs/requirements/05-auth-sync.md)
    // instead of a lazy `NativeDatabase`, so the graph needs a real (if
    // never-connected-to-the-service) `PowerSyncDatabase` too — same pattern as
    // `bootstrap.dart`, but pointed at a throwaway temp file instead of
    // `path_provider` (no platform channel implementation under `flutter test`).
    final tempDir = await Directory.systemTemp.createTemp('billetudo_di_test');
    addTearDown(() => tempDir.delete(recursive: true));
    await openPowerSyncDatabase(path: p.join(tempDir.path, 'test.sqlite'));
  });

  setUp(configureDependencies);
  tearDown(getIt.reset);

  test('el grafo de dependencias se resuelve sin errores', () {
    expect(getIt<CrashReporter>(), isA<NoopCrashReporter>());
    expect(getIt<MoneyFormatter>(), isA<MoneyFormatter>());
    expect(getIt<SecureStorageService>(), isA<SecureStorageService>());
    expect(getIt<AppDatabase>(), isA<AppDatabase>());
  });

  test('el grafo de Cuentas se resuelve (repositorio y casos de uso)', () {
    // Los lazySingleton no se construyen hasta que se piden: sin esto, un
    // cableado roto de la feature no lo detectaría ningún test.
    expect(getIt<AccountRepository>(), isA<AccountRepository>());
    expect(getIt<CreateAccount>(), isA<CreateAccount>());
    expect(getIt<WatchAccounts>(), isA<WatchAccounts>());
  });

  test('el grafo de Categorías se resuelve (repositorio y casos de uso)', () {
    expect(getIt<CategoryRepository>(), isA<CategoryRepository>());
    expect(getIt<CreateCategory>(), isA<CreateCategory>());
    expect(getIt<WatchCategories>(), isA<WatchCategories>());
  });

  test('MoneyFormatter formatea centavos según la convención', () {
    final money = getIt<MoneyFormatter>();
    // 123456 cents = 1234.56 major units.
    expect(money.formatAmount(123456), contains('1.234,56'));
    expect(MoneyFormatter.toMinor(12.34), 1234);
    expect(MoneyFormatter.toMajor(1234), 12.34);
  });
}
