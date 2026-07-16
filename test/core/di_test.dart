import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/security/secure_storage_service.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/features/accounts/domain/repositories/account_repository.dart';
import 'package:billetudo/features/accounts/domain/usecases/create_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/categories/domain/repositories/category_repository.dart';
import 'package:billetudo/features/categories/domain/usecases/create_category.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(configureDependencies);
  tearDown(getIt.reset);

  test('el grafo de dependencias se resuelve sin errores', () {
    expect(getIt<CrashReporter>(), isA<NoopCrashReporter>());
    expect(getIt<MoneyFormatter>(), isA<MoneyFormatter>());
    expect(getIt<SecureStorageService>(), isA<SecureStorageService>());
    // AppDatabase is registered with a lazy connection: building it opens no
    // I/O.
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
