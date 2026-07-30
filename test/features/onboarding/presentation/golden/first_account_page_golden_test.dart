import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_state.dart';
import 'package:billetudo/features/onboarding/presentation/pages/first_account_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockAccountFormCubit extends MockCubit<AccountFormState>
    implements AccountFormCubit {}

/// HU-02 (`G7vDVK`/`c2wua2`, credit-card variant `O2QbEF`/`yClJt`): "Tu
/// primera cuenta" — two distinguishable business states: the pre-filled
/// Ahorros/`savings` default, and the `card` variant that surfaces the
/// domain's mandatory cupo/día de corte/día de pago fields
/// (`13-onboarding.md` HU-02: "El onboarding no relaja validaciones del
/// dominio").
void main() {
  late MockAccountFormCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockAccountFormCubit());

  Future<void> golden(
    WidgetTester tester,
    AccountFormState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    // The card variant adds cupo/día de corte/día de pago below the fold: a
    // tall canvas captures the full scrollable form in one golden.
    await pumpGolden(
      tester,
      BlocProvider<AccountFormCubit>.value(
        value: cubit,
        child: FirstAccountPage(onCreated: () {}, onSkip: () {}),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(),
    );
    await expectLater(
      find.byType(FirstAccountPage),
      matchesGoldenFile('goldens/first_account_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('pre-filled savings default ($suffix)', (tester) async {
      await golden(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.savings,
          name: 'Ahorros',
          currency: 'COP',
          initialBalanceText: '0',
        ),
        'savings_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('credit card variant, cupo/corte/pago visible ($suffix)',
        (tester) async {
      await golden(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.card,
          name: 'Ahorros',
          currency: 'COP',
          initialBalanceText: '0',
          creditLimitText: '3000000',
          statementDay: 15,
          paymentDueDay: 5,
        ),
        'card_$suffix',
        brightness: brightness,
      );
    });
  }
}
