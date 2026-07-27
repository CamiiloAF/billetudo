import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance_adjustment.dart';
import 'package:billetudo/features/accounts/domain/usecases/adjust_account_balance.dart';
import 'package:billetudo/features/accounts/presentation/cubit/adjust_balance_cubit.dart';
import 'package:billetudo/features/accounts/presentation/widgets/balance_adjust_mode_option.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/adjust_balance_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../account_fixtures.dart';
import 'pump_widget.dart';

class MockAdjustAccountBalance extends Mock implements AdjustAccountBalance {}

void main() {
  late MockAdjustAccountBalance adjust;

  setUpAll(() {
    registerFallbackValue(buildAccount());
    registerFallbackValue(BalanceAdjustmentMode.registerMovement);
  });

  setUp(() {
    adjust = MockAdjustAccountBalance();
    when(
      () => adjust(
        account: any(named: 'account'),
        currentBalanceMinor: any(named: 'currentBalanceMinor'),
        newDisplayedBalanceMinor: any(named: 'newDisplayedBalanceMinor'),
        mode: any(named: 'mode'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  Finder applyButton() =>
      find.byWidgetPredicate((widget) => widget is FilledButton);

  Future<void> pumpSheet(
    WidgetTester tester, {
    required int currentBalanceMinor,
    bool card = false,
  }) async {
    final cubit = AdjustBalanceCubit(adjust)
      ..start(
        account: card
            ? buildCard(
                creditLimitMinor: 300000000, initialBalanceMinor: -100000)
            : buildAccount(initialBalanceMinor: 0),
        currentBalanceMinor: currentBalanceMinor,
      );
    await tester.pumpAppWidget(
      BlocProvider.value(value: cubit, child: const AdjustBalanceSheet()),
    );
  }

  testWidgets('muestra título, saldo actual y las dos opciones', (
    tester,
  ) async {
    await pumpSheet(tester, currentBalanceMinor: 100000);

    expect(find.text('Ajustar saldo'), findsOneWidget);
    expect(find.textContaining('Saldo actual:'), findsOneWidget);
    expect(find.text('Registrar ajuste'), findsOneWidget);
    expect(find.text('Corregir saldo inicial'), findsOneWidget);
    expect(find.text('Nuevo saldo deseado'), findsOneWidget);
  });

  testWidgets('sin cifra, "Aplicar" arranca deshabilitado', (tester) async {
    await pumpSheet(tester, currentBalanceMinor: 100000);

    final button = tester.widget<FilledButton>(applyButton());
    expect(button.onPressed, isNull);
  });

  testWidgets('tarjeta: el campo se etiqueta "Nueva deuda"', (tester) async {
    await pumpSheet(tester, currentBalanceMinor: -100000, card: true);

    expect(find.text('Nueva deuda'), findsOneWidget);
    expect(find.textContaining('Deuda actual:'), findsOneWidget);
  });

  testWidgets('teclear una cifra distinta habilita y aplica', (tester) async {
    await pumpSheet(tester, currentBalanceMinor: 100000);

    await tester.enterText(find.byType(TextField), '5000');
    await tester.pump();

    final button = tester.widget<FilledButton>(applyButton());
    expect(button.onPressed, isNotNull);

    await tester.tap(applyButton());
    await tester.pump();

    verify(
      () => adjust(
        account: any(named: 'account'),
        currentBalanceMinor: 100000,
        newDisplayedBalanceMinor: any(named: 'newDisplayedBalanceMinor'),
        mode: BalanceAdjustmentMode.registerMovement,
        note: any(named: 'note'),
      ),
    ).called(1);
  });

  testWidgets('seleccionar "Corregir saldo inicial" cambia el modo aplicado', (
    tester,
  ) async {
    await pumpSheet(tester, currentBalanceMinor: 100000);

    await tester.enterText(find.byType(TextField), '5000');
    await tester.pump();

    await tester.tap(
      find.widgetWithText(BalanceAdjustModeOption, 'Corregir saldo inicial'),
    );
    await tester.pump();

    await tester.tap(applyButton());
    await tester.pump();

    verify(
      () => adjust(
        account: any(named: 'account'),
        currentBalanceMinor: any(named: 'currentBalanceMinor'),
        newDisplayedBalanceMinor: any(named: 'newDisplayedBalanceMinor'),
        mode: BalanceAdjustmentMode.correctInitial,
        note: any(named: 'note'),
      ),
    ).called(1);
  });
}
