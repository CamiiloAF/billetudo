import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/transactions/presentation/widgets/account_filter_chip_row.dart';
import 'package:billetudo/features/transactions/presentation/widgets/circular_icon_chip.dart';
import 'package:billetudo/features/transactions/presentation/widgets/filter_chip_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../categories/presentation/widgets/pump_widget.dart';

/// GitHub issue #7: the account filter's own row of chips in the Movimientos
/// bar — one chip per active account plus a single "Todas"/"Limpiar" toggle
/// chip, never landing on zero selected accounts.
///
/// 2026-11-07 (explicit user request): a plain tap is **single-select** (it
/// replaces the filter with the tapped account only), and a **long press**
/// enters multi-select seeded with that account, after which every tap
/// adds/removes one account. These tests cover both modes plus the mode
/// switch itself.
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

  // "Todas" and "Limpiar" are icon-only `CircularIconChip`s (no visible
  // text), so they're located by their lucide icon rather than by label.
  Finder circularIconChip(IconData icon) => find.byWidgetPredicate(
        (widget) => widget is CircularIconChip && widget.icon == icon,
      );

  /// Pumps the row behind a small stateful harness that feeds every emission
  /// back as the new `selected`, mirroring production (`TransactionsListCubit`
  /// emits the new filter and the row rebuilds) — without it, chained
  /// interactions in multi-select mode would read a stale prop.
  Future<List<Set<String>>> pumpRow(
    WidgetTester tester, {
    required Set<String> selected,
    List<AccountWithBalance>? rowAccounts,
  }) async {
    final emissions = <Set<String>>[];
    await tester.pumpAppWidget(
      _AccountFilterChipRowHarness(
        accounts: rowAccounts ?? accounts,
        initialSelected: selected,
        onEmitted: emissions.add,
      ),
    );
    return emissions;
  }

  testWidgets(
      'sin filtro (selected vacío), cada chip de cuenta y "Todas" '
      'quedan activos', (tester) async {
    await pumpRow(tester, selected: const {});

    final pills =
        tester.widgetList<FilterChipPill>(find.byType(FilterChipPill));
    for (final pill in pills) {
      expect(
        pill.active,
        isTrue,
        reason: '${pill.label} debería estar activo',
      );
    }
  });

  group('selección simple (tap sin long press)', () {
    testWidgets('desde "Todas", tocar una cuenta filtra solo esa cuenta',
        (tester) async {
      final emissions = await pumpRow(tester, selected: const {});

      await tester.tap(find.text('Efectivo'));
      await tester.pump();

      expect(emissions.last, {cash.account.id});
    });

    testWidgets(
        'tocar otra cuenta reemplaza la selección anterior (no la '
        'suma)', (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id},
      );

      await tester.tap(find.text('Nequi'));
      await tester.pump();

      expect(emissions.last, {bank.account.id});
    });

    testWidgets('tocar la cuenta ya seleccionada la mantiene (idempotente)',
        (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id},
      );

      await tester.tap(find.text('Efectivo'));
      await tester.pump();

      expect(emissions.last, {cash.account.id});
    });

    testWidgets(
        'con una selección múltiple previa, un tap la colapsa a una '
        'sola cuenta', (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id, bank.account.id},
      );

      await tester.tap(find.text('Ahorros'));
      await tester.pump();

      expect(emissions.last, {savings.account.id});
    });
  });

  group('selección múltiple (long press)', () {
    FilterChipPill pillFor(WidgetTester tester, String label) =>
        tester.widget<FilterChipPill>(
          find.byWidgetPredicate(
            (widget) => widget is FilterChipPill && widget.label == label,
          ),
        );

    bool multiActive(WidgetTester tester) => tester
        .widgetList<FilterChipPill>(find.byType(FilterChipPill))
        .any((pill) => pill.trailingIcon == LucideIcons.check);

    testWidgets(
        'con "Efectivo" seleccionado, long press en "Nequi" deja ambas '
        'activas (suma, no reemplaza)', (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id},
      );

      await tester.longPress(find.text('Nequi'));
      await tester.pump();

      expect(emissions.last, {cash.account.id, bank.account.id});
      expect(pillFor(tester, 'Efectivo').active, isTrue);
      expect(pillFor(tester, 'Nequi').active, isTrue);
      expect(multiActive(tester), isTrue);
    });

    testWidgets(
        'long press sobre la única cuenta ya seleccionada no entra en multi '
        '(haría falta una segunda)', (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id},
      );

      await tester.longPress(find.text('Efectivo'));
      await tester.pump();

      expect(emissions, isEmpty);
      expect(multiActive(tester), isFalse);
    });

    testWidgets(
        'desde "Todas", el long press conserva todas las cuentas y entra en '
        'multi', (tester) async {
      final emissions = await pumpRow(tester, selected: const {});

      await tester.longPress(find.text('Efectivo'));
      await tester.pump();

      // Sin cambio de filtro: todas siguen activas (default inclusivo-vacío).
      expect(emissions.last, isEmpty);
      expect(multiActive(tester), isTrue);
      expect(pillFor(tester, 'Nequi').active, isTrue);
    });

    testWidgets(
        'en multi, cada tap suma una cuenta hasta el default '
        'inclusivo (1, 2, 3...)', (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id},
      );

      await tester.longPress(find.text('Nequi')); // {Efectivo, Nequi}
      await tester.pump();
      expect(emissions.last, {cash.account.id, bank.account.id});

      await tester.tap(find.text('Ahorros'));
      await tester.pump();
      // Las 3 cuentas = el default inclusivo-vacío de "Todas".
      expect(emissions.last, isEmpty);
      expect(multiActive(tester), isTrue);
    });

    testWidgets('un tap en multi quita la cuenta tocada', (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id},
      );

      await tester.longPress(find.text('Nequi')); // {Efectivo, Nequi}
      await tester.pump();
      await tester.tap(find.text('Nequi'));
      await tester.pump();

      expect(emissions.last, {cash.account.id});
    });

    testWidgets(
        'al volver a 1 cuenta seleccionada el multi se desactiva, y el '
        'siguiente tap vuelve a reemplazar', (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id},
      );

      await tester.longPress(find.text('Nequi')); // multi: {Efectivo, Nequi}
      await tester.pump();
      expect(multiActive(tester), isTrue);

      await tester.tap(find.text('Efectivo')); // 2 -> 1: sale del modo
      await tester.pump();
      expect(emissions.last, {bank.account.id});
      expect(multiActive(tester), isFalse);

      await tester.tap(find.text('Ahorros'));
      await tester.pump();
      expect(emissions.last, {savings.account.id});
    });

    testWidgets('mientras multi está activo, un long press no hace nada',
        (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id},
      );

      await tester.longPress(find.text('Nequi'));
      await tester.pump();
      final emittedBefore = emissions.length;

      await tester.longPress(find.text('Ahorros'));
      await tester.pump();

      expect(
        emissions.length,
        emittedBefore,
        reason: 'el long press en multi no debe emitir ni salir del modo',
      );
      expect(multiActive(tester), isTrue);

      // Si el long press no hubiera hecho nada, este tap suma Ahorros y
      // colapsa al default (3 de 3); si hubiera entrado/salido del modo de
      // otra forma, el resultado habría sido distinto.
      await tester.tap(find.text('Ahorros'));
      await tester.pump();
      expect(emissions.last, isEmpty);
    });

    testWidgets('en modo multi, cada pill seleccionada muestra el check',
        (tester) async {
      await pumpRow(tester, selected: {cash.account.id});

      // Single-select: sin checks, aunque la pill esté activa.
      expect(pillFor(tester, 'Efectivo').trailingIcon, isNull);

      await tester.longPress(find.text('Nequi'));
      await tester.pump();

      expect(pillFor(tester, 'Efectivo').trailingIcon, LucideIcons.check);
      expect(pillFor(tester, 'Nequi').trailingIcon, LucideIcons.check);
      expect(pillFor(tester, 'Ahorros').trailingIcon, isNull);
    });

    testWidgets('tocar el chip "Todas" sale del modo multi y vuelve al default',
        (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id},
      );

      await tester.longPress(find.text('Nequi')); // multi: {Efectivo, Nequi}
      await tester.pump();
      expect(multiActive(tester), isTrue);

      await tester.tap(circularIconChip(LucideIcons.checkCheck));
      await tester.pump();

      // "Todas" emite el conjunto explícito completo (no el vacío implícito,
      // para que el estado sea distinguible), y sale del modo multi.
      expect(
        emissions.last,
        {cash.account.id, bank.account.id, savings.account.id},
      );
      expect(multiActive(tester), isFalse);

      // De vuelta en single-select: el próximo tap reemplaza.
      await tester.tap(find.text('Ahorros'));
      await tester.pump();
      expect(emissions.last, {savings.account.id});
    });
  });

  group('chip toggle "Todas"/"Limpiar"', () {
    testWidgets(
        'con una selección parcial, muestra "Todas" y al tocarlo selecciona '
        'explícitamente todas las cuentas', (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id},
      );

      await tester.tap(circularIconChip(LucideIcons.checkCheck));
      await tester.pump();

      expect(
        emissions.last,
        {cash.account.id, bank.account.id, savings.account.id},
      );
    });

    testWidgets(
        'con todas las cuentas seleccionadas (implícito), muestra "Limpiar" y '
        'al tocarlo deja solo la primera cuenta', (tester) async {
      final emissions = await pumpRow(tester, selected: const {});

      await tester.tap(circularIconChip(LucideIcons.x));
      await tester.pump();

      expect(emissions.last, {cash.account.id});
    });

    testWidgets(
        'con todas las cuentas seleccionadas explícitamente, también muestra '
        '"Limpiar"', (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: {cash.account.id, bank.account.id, savings.account.id},
      );

      await tester.tap(circularIconChip(LucideIcons.x));
      await tester.pump();

      expect(emissions.last, {cash.account.id});
    });
  });

  group('única cuenta activa', () {
    testWidgets('tocar la única cuenta existente la selecciona',
        (tester) async {
      final emissions = await pumpRow(
        tester,
        selected: const {},
        rowAccounts: [cash],
      );

      await tester.tap(find.text('Efectivo'));
      await tester.pump();

      expect(emissions.last, {cash.account.id});
    });
  });
}

/// Test-only harness: keeps `selected` live so a chain of taps behaves like
/// the real screen, where each emission rebuilds the row with the new filter.
class _AccountFilterChipRowHarness extends StatefulWidget {
  const _AccountFilterChipRowHarness({
    required this.accounts,
    required this.initialSelected,
    required this.onEmitted,
  });

  final List<AccountWithBalance> accounts;
  final Set<String> initialSelected;
  final ValueChanged<Set<String>> onEmitted;

  @override
  State<_AccountFilterChipRowHarness> createState() =>
      _AccountFilterChipRowHarnessState();
}

class _AccountFilterChipRowHarnessState
    extends State<_AccountFilterChipRowHarness> {
  late Set<String> _selected = widget.initialSelected;

  @override
  Widget build(BuildContext context) => AccountFilterChipRow(
        accounts: widget.accounts,
        selected: _selected,
        onChanged: (next) {
          widget.onEmitted(next);
          setState(() => _selected = next);
        },
      );
}
