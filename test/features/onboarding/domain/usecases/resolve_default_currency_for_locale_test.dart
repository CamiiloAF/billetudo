import 'package:billetudo/features/onboarding/domain/usecases/resolve_default_currency_for_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ResolveDefaultCurrencyForLocale resolveDefaultCurrencyForLocale;

  setUp(() {
    resolveDefaultCurrencyForLocale = const ResolveDefaultCurrencyForLocale();
  });

  test('HU-02: resolves CO to COP', () {
    expect(resolveDefaultCurrencyForLocale('CO'), 'COP');
  });

  test('is case-insensitive', () {
    expect(resolveDefaultCurrencyForLocale('co'), 'COP');
  });

  test(
      'falls back to USD for a region the Accounts currency picker does not '
      'support (MXN/ARS/CLP/PEN/EUR were retired from it)', () {
    expect(resolveDefaultCurrencyForLocale('MX'), 'USD');
    expect(resolveDefaultCurrencyForLocale('AR'), 'USD');
    expect(resolveDefaultCurrencyForLocale('CL'), 'USD');
    expect(resolveDefaultCurrencyForLocale('PE'), 'USD');
    expect(resolveDefaultCurrencyForLocale('ES'), 'USD');
  });

  test('falls back to USD for US, as the requirements table says', () {
    expect(resolveDefaultCurrencyForLocale('US'), 'USD');
  });

  test('falls back to USD for an unknown region', () {
    expect(resolveDefaultCurrencyForLocale('ZZ'), 'USD');
  });

  test('falls back to USD when the region is null', () {
    expect(resolveDefaultCurrencyForLocale(null), 'USD');
  });
}
