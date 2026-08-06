import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/reports/presentation/widgets/account_filter_row.dart';
import 'package:billetudo/features/transactions/presentation/cubit/account_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/widgets/filter_chip_pill.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountFilterCubit extends MockCubit<AccountFilterState>
    implements AccountFilterCubit {}

final DateTime _instant = DateTime(2026, 1, 1);
final int _instantMillis = _instant.millisecondsSinceEpoch;

AccountWithBalance _account(String id, String name) {
  final account = Account(
    id: id,
    name: name,
    type: AccountType.cash,
    currency: 'COP',
    initialBalanceMinor: 0,
    archived: false,
    sortOrder: 0,
    createdAt: _instant,
    updatedAt: _instantMillis,
  );
  return AccountWithBalance(
    account: account,
    balance: AccountBalance.fromBalance(account: account, balanceMinor: 100000),
  );
}

void main() {
  setUp(getIt.reset);
  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester, {
    required Set<String> selected,
    required ValueChanged<Set<String>> onChanged,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AccountFilterRow(
              selected: selected,
              onChanged: onChanged,
            ),
          ),
        ),
      );

  testWidgets('sin selección muestra "Todas las cuentas" sin badge activo',
      (tester) async {
    await pump(tester, selected: const {}, onChanged: (_) {});

    expect(find.text('Todas las cuentas'), findsOneWidget);
    final pill = tester.widget<FilterChipPill>(find.byType(FilterChipPill));
    expect(pill.active, isFalse);
  });

  testWidgets('con selección parcial muestra el conteo de cuentas',
      (tester) async {
    await pump(tester, selected: {'acc-1', 'acc-2'}, onChanged: (_) {});

    expect(find.text('2 cuentas'), findsOneWidget);
    final pill = tester.widget<FilterChipPill>(find.byType(FilterChipPill));
    expect(pill.active, isTrue);
  });

  testWidgets('tocar el chip abre la hoja y aplicar propaga la selección',
      (tester) async {
    final cubit = MockAccountFilterCubit();
    when(() => cubit.start(any())).thenAnswer((_) async {});
    when(() => cubit.state).thenReturn(
      AccountFilterState(
        status: AccountFilterStatus.ready,
        accounts: [_account('acc-1', 'Efectivo'), _account('acc-2', 'Banco')],
        selected: const {'acc-1'},
      ),
    );
    getIt.registerFactory<AccountFilterCubit>(() => cubit);

    Set<String>? applied;
    await pump(
      tester,
      selected: const {},
      onChanged: (value) => applied = value,
    );

    await tester.tap(find.byType(FilterChipPill));
    await tester.pumpAndSettle();

    expect(find.text('Aplicar'), findsOneWidget);

    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(applied, {'acc-1'});
  });
}
