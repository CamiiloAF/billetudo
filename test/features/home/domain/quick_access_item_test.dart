import 'package:billetudo/features/home/domain/entities/quick_access_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaultOrder es una permutación válida de los 5 miembros', () {
    expect(QuickAccessItem.defaultOrder, hasLength(5));
    expect(QuickAccessItem.isValidOrder(QuickAccessItem.defaultOrder), isTrue);
    expect(
      QuickAccessItem.defaultOrder.toSet(),
      QuickAccessItem.values.toSet(),
    );
  });

  test(
      'isValidOrder rechaza un orden de 3 items (persistido antes del '
      'rediseño) — cae al fallback, no revienta', () {
    const legacyOrder = [
      QuickAccessItem.scheduledPayments,
      QuickAccessItem.debts,
      QuickAccessItem.reports,
    ];

    expect(QuickAccessItem.isValidOrder(legacyOrder), isFalse);
  });

  test('isValidOrder rechaza duplicados', () {
    const order = [
      QuickAccessItem.scheduledPayments,
      QuickAccessItem.scheduledPayments,
      QuickAccessItem.debts,
      QuickAccessItem.reports,
      QuickAccessItem.accounts,
    ];

    expect(QuickAccessItem.isValidOrder(order), isFalse);
  });

  test('isValidOrder acepta cualquier permutación de los 5', () {
    const order = [
      QuickAccessItem.goals,
      QuickAccessItem.accounts,
      QuickAccessItem.reports,
      QuickAccessItem.debts,
      QuickAccessItem.scheduledPayments,
    ];

    expect(QuickAccessItem.isValidOrder(order), isTrue);
  });
}
