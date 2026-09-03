import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/transactions/presentation/widgets/account_filter_chip_row.dart';
import 'package:billetudo/features/transactions/presentation/widgets/filter_chip_pill.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../categories/presentation/widgets/pump_widget.dart';

/// GitHub issue #7: the account filter's own row of chips in the Movimientos
/// bar — one chip per active account plus "Todas"/"Limpiar", never landing on
/// zero selected accounts.
void main() {
  AccountWithBalance account(String id, String name) => AccountWithBalance(
        account: Account(
          id: id,
          name: name,
          type: AccountType.cash,
          currency: 'COP',
          initialBalanceMinor: 0,
          archived: false,
          sortOrder: 0,
          createdAt: DateTime(2026),
          updatedAt: 0,
        ),
        balance: AccountBalance.fromBalance(
          account: Account(
            id: id,
            name: name,
            type: AccountType.cash,
            currency: 'COP',
            initialBalanceMinor: 0,
            archived: false,
            sortOrder: 0,
            createdAt: DateTime(2026),
            updatedAt: 0,
          ),
          balanceMinor: 0,
        ),
      );

  final cash = account('acc-1', 'Efectivo');
  final bank = account('acc-2', 'Nequi');
  final savings = account('acc-3', 'Ahorros');
  final accounts = [cash, bank, savings];

  Future<Set<String>?> pumpAndTap(
    WidgetTester tester, {
    required Set<String> selected,
    required String chipLabel,
  }) async {
    Set<String>? result;
    await tester.pumpAppWidget(
      AccountFilterChipRow(
        accounts: accounts,
        selected: selected,
        onChanged: (next) => result = next,
      ),
    );
    await tester.tap(find.text(chipLabel));
    await tester.pump();
    return result;
  }

  testWidgets(
      'sin filtro (selected vacío), cada chip de cuenta y "Todas" quedan '
      'activos', (tester) async {
    await tester.pumpAppWidget(
      AccountFilterChipRow(
        accounts: accounts,
        selected: const {},
        onChanged: (_) {},
      ),
    );

    final pills = tester.widgetList<FilterChipPill>(find.byType(FilterChipPill));
    for (final pill in pills) {
      if (pill.label == 'Limpiar') {
        continue;
      }
      expect(pill.active, isTrue, reason: '${pill.label} debería estar activo');
    }
  });

  testWidgets('tocar "Todas" limpia el filtro (selected vacío)',
      (tester) async {
    final result = await pumpAndTap(
      tester,
      selected: {cash.account.id},
      chipLabel: 'Todas',
    );
    expect(result, isEmpty);
  });

  testWidgets('tocar "Limpiar" también vuelve al default (Todas)',
      (tester) async {
    final result = await pumpAndTap(
      tester,
      selected: {cash.account.id},
      chipLabel: 'Limpiar',
    );
    expect(result, isEmpty);
  });

  testWidgets(
      'deseleccionar una cuenta entre varias explícitas la quita del '
      'conjunto', (tester) async {
    final result = await pumpAndTap(
      tester,
      selected: {cash.account.id, bank.account.id},
      chipLabel: 'Efectivo',
    );
    expect(result, {bank.account.id});
  });

  testWidgets(
      'deseleccionar la última cuenta explícita seleccionada es un no-op '
      '(nunca cero cuentas)', (tester) async {
    final result = await pumpAndTap(
      tester,
      selected: {cash.account.id},
      chipLabel: 'Efectivo',
    );
    expect(result, {cash.account.id});
  });

  testWidgets(
      'sin filtro previo (Todas), deseleccionar una cuenta dentro de 3 '
      'activas deja las otras 2 explícitas', (tester) async {
    final result = await pumpAndTap(
      tester,
      selected: const {},
      chipLabel: 'Efectivo',
    );
    expect(result, {bank.account.id, savings.account.id});
  });

  testWidgets(
      'sin filtro previo y solo una cuenta activa, deseleccionarla es un '
      'no-op', (tester) async {
    Set<String>? result;
    await tester.pumpAppWidget(
      AccountFilterChipRow(
        accounts: [cash],
        selected: const {},
        onChanged: (next) => result = next,
      ),
    );
    await tester.tap(find.text('Efectivo'));
    await tester.pump();
    // No-op: the toggle refuses to leave zero accounts, so it hands back the
    // same effective selection it started from.
    expect(result, {cash.account.id});
  });

  testWidgets(
      'reseleccionar la única cuenta faltante colapsa de vuelta al default '
      'inclusivo-vacío', (tester) async {
    final result = await pumpAndTap(
      tester,
      selected: {cash.account.id, bank.account.id},
      chipLabel: 'Ahorros',
    );
    expect(result, isEmpty);
  });
}
