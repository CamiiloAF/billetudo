import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/security/secure_storage_service.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
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

  test('MoneyFormatter formatea centavos según la convención', () {
    final money = getIt<MoneyFormatter>();
    // 123456 cents = 1234.56 major units.
    expect(money.formatAmount(123456), contains('1.234,56'));
    expect(MoneyFormatter.toMinor(12.34), 1234);
    expect(MoneyFormatter.toMajor(1234), 12.34);
  });
}
