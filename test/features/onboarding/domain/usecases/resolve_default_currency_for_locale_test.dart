import 'package:billetudo/features/onboarding/domain/usecases/resolve_default_currency_for_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ResolveDefaultCurrencyForLocale resolveDefaultCurrencyForLocale;

  setUp(() {
    resolveDefaultCurrencyForLocale = const ResolveDefaultCurrencyForLocale();
  });

  test('HU-02: always resolves to COP, region-based resolution was dropped',
      () {
    expect(resolveDefaultCurrencyForLocale('CO'), 'COP');
    expect(resolveDefaultCurrencyForLocale('US'), 'COP');
    expect(resolveDefaultCurrencyForLocale('ES'), 'COP');
    expect(resolveDefaultCurrencyForLocale('ZZ'), 'COP');
    expect(resolveDefaultCurrencyForLocale(null), 'COP');
  });
}
