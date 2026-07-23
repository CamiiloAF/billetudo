import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_type_avatar.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_payment_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_payment_state.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_cash_switch.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_payment_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../debts_presentation_fixtures.dart';

class MockDebtPaymentCubit extends MockCubit<DebtPaymentState>
    implements DebtPaymentCubit {}

void main() {
  late MockDebtPaymentCubit cubit;

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Bancolombia'),
      balanceMinor: 3450000,
    ),
  ];

  DebtPaymentState stateWith({required bool addToAccount}) => DebtPaymentState(
        debt: buildDebt(name: 'Crédito vehicular'),
        status: DebtPaymentStatus.ready,
        accounts: accounts,
        addToAccount: addToAccount,
        selectedAccountId: 'a1',
        amountMinor: 150000,
        date: DateTime(2026, 7, 22),
      );

  setUp(() => cubit = MockDebtPaymentCubit());

  Future<void> pump(WidgetTester tester, DebtPaymentState state) async {
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<DebtPaymentCubit>.value(
            value: cubit,
            child: DebtPaymentSheetBody(
              state: state,
              onLinkExisting: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('toggle Sí revela la cuenta y la categoría', (tester) async {
    await pump(tester, stateWith(addToAccount: true));
    expect(find.byType(AccountTypeAvatar), findsOneWidget);
    expect(find.text('Bancolombia'), findsOneWidget);
    expect(find.text('Categoría (opcional)'), findsOneWidget);
    expect(
      find.text('Moverá el saldo y contará en tus estadísticas'),
      findsOneWidget,
    );
    expect(find.byType(DebtCashSwitch), findsOneWidget);
  });

  testWidgets('toggle No oculta cuenta y categoría, con el copy sin caja',
      (tester) async {
    await pump(tester, stateWith(addToAccount: false));
    expect(find.byType(AccountTypeAvatar), findsNothing);
    expect(find.text('Categoría (opcional)'), findsNothing);
    expect(
      find.text(
        'Este abono baja el saldo de la deuda pero no moverá ninguna cuenta.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('muestra el enlace "Enlaza un movimiento"', (tester) async {
    await pump(tester, stateWith(addToAccount: true));
    expect(
      find.text('¿Ya lo registraste? Enlaza un movimiento'),
      findsOneWidget,
    );
  });
}
