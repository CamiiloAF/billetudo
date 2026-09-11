import 'package:billetudo/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

/// The puente de voz travels as query params on the existing new-movement
/// route (`17-captura-voz.md`, HU-01): same form, prefilled.
void main() {
  test('sin campos entendidos solo viaja el origen', () {
    final uri = Uri.parse(AppRoutes.newTransactionFromVoice());

    expect(uri.path, AppRoutes.newTransaction);
    expect(uri.queryParameters, {'source': 'voice'});
  });

  test('los campos entendidos viajan y los vacíos se omiten', () {
    final uri = Uri.parse(
      AppRoutes.newTransactionFromVoice(
        amountMinor: 2000000,
        type: 'expense',
        accountId: 'acc-1',
        categoryId: 'cat-food',
        categoryKind: 'expense',
        categoryName: 'Alimentación',
        date: DateTime(2026, 9, 8),
        note: 'almuerzo',
      ),
    );

    expect(uri.queryParameters['source'], 'voice');
    expect(uri.queryParameters['amountMinor'], '2000000');
    expect(uri.queryParameters['type'], 'expense');
    expect(uri.queryParameters['accountId'], 'acc-1');
    expect(uri.queryParameters['categoryId'], 'cat-food');
    expect(uri.queryParameters['categoryName'], 'Alimentación');
    expect(uri.queryParameters['date'], startsWith('2026-09-08'));
    expect(uri.queryParameters['note'], 'almuerzo');
    expect(uri.queryParameters.containsKey('amountIsUncertain'), isFalse);
  });

  test('un monto inferido viaja marcado', () {
    final uri = Uri.parse(
      AppRoutes.newTransactionFromVoice(
        amountMinor: 2000000,
        amountIsUncertain: true,
      ),
    );

    expect(uri.queryParameters['amountIsUncertain'], 'true');
  });

  test('una nota con caracteres especiales sobrevive el viaje', () {
    final uri = Uri.parse(
      AppRoutes.newTransactionFromVoice(note: 'café & pan del 100%'),
    );

    expect(uri.queryParameters['note'], 'café & pan del 100%');
  });

  test('una nota vacía no viaja', () {
    final uri = Uri.parse(AppRoutes.newTransactionFromVoice(note: ''));

    expect(uri.queryParameters.containsKey('note'), isFalse);
  });
}
