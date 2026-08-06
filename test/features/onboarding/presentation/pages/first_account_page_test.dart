import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_draft.dart';
import 'package:billetudo/features/accounts/domain/usecases/create_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/get_account_number.dart';
import 'package:billetudo/features/accounts/domain/usecases/update_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_account_detail.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_cubit.dart';
import 'package:billetudo/features/onboarding/presentation/pages/first_account_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../widgets/pump_widget.dart';

class MockCreateAccount extends Mock implements CreateAccount {}

class MockUpdateAccount extends Mock implements UpdateAccount {}

class MockWatchAccountDetail extends Mock implements WatchAccountDetail {}

class MockGetAccountNumber extends Mock implements GetAccountNumber {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const AccountDraft(name: 'x', type: AccountType.savings, currency: 'COP'),
    );
  });

  late MockCreateAccount createAccount;
  late AccountFormCubit cubit;

  setUp(() {
    createAccount = MockCreateAccount();
    cubit = AccountFormCubit(
      createAccount,
      MockUpdateAccount(),
      MockWatchAccountDetail(),
      MockGetAccountNumber(),
      const MoneyFormatter(),
    );
    unawaited(cubit.load(null));
    cubit
      ..typeSelected(AccountType.savings)
      ..nameChanged('Ahorros')
      ..currencySelected('COP');
  });

  tearDown(() => cubit.close());

  Future<void> pumpFirstAccount(
    WidgetTester tester, {
    VoidCallback? onCreated,
    VoidCallback? onSkip,
  }) =>
      tester.pumpOnboardingWidget(
        BlocProvider.value(
          value: cubit,
          child: FirstAccountPage(
            onCreated: onCreated ?? () {},
            onSkip: onSkip ?? () {},
          ),
        ),
      );

  testWidgets(
      'HU-02: pre-llena nombre "Ahorros", tipo Ahorros y moneda COP',
      (tester) async {
    await pumpFirstAccount(tester);

    expect(find.text('Crea tu primera cuenta'), findsOneWidget);
    expect(find.text('Ahorros'), findsWidgets);
    expect(find.text('COP'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Omitir por ahora'), findsOneWidget);
  });

  testWidgets(
      'HU-02: no muestra institución, número, tasa de interés ni ícono/color',
      (tester) async {
    await pumpFirstAccount(tester);

    expect(find.text('Institución'), findsNothing);
    expect(find.text('Tasa de interés'), findsNothing);
  });

  testWidgets('"Omitir por ahora" invoca onSkip sin crear la cuenta',
      (tester) async {
    var skipped = false;
    await pumpFirstAccount(tester, onSkip: () => skipped = true);

    await tester.tap(find.text('Omitir por ahora'));
    await tester.pump();

    expect(skipped, isTrue);
    verifyNever(() => createAccount(any()));
  });

  testWidgets('crear cuenta llama a CreateAccount y luego invoca onCreated',
      (tester) async {
    final now = DateTime(2026, 7, 29);
    when(() => createAccount(any())).thenAnswer(
      (_) async => Right(
        Account(
          id: '1',
          name: 'Ahorros',
          type: AccountType.savings,
          currency: 'COP',
          initialBalanceMinor: 0,
          archived: false,
          sortOrder: 0,
          createdAt: now,
          updatedAt: now.millisecondsSinceEpoch,
        ),
      ),
    );
    var created = false;
    await pumpFirstAccount(tester, onCreated: () => created = true);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    verify(() => createAccount(any())).called(1);
    expect(created, isTrue);
  });

  testWidgets(
      'HU-02: elegir Tarjeta de crédito exige cupo, día de corte y de pago',
      (tester) async {
    await pumpFirstAccount(tester);
    cubit.typeSelected(AccountType.card);
    await tester.pumpAndSettle();

    expect(find.text('Cupo máximo'), findsOneWidget);
    expect(find.text('Día de corte'), findsOneWidget);
    expect(find.text('Día de pago'), findsOneWidget);
  });
}
