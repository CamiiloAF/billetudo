import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_state.dart';
import 'package:billetudo/features/accounts/presentation/pages/account_form_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockAccountFormCubit extends MockCubit<AccountFormState>
    implements AccountFormCubit {}

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
    // The form is a ListView: the tall canvas captures every field in one
    // golden instead of only the first viewport (mirrors account_form_page_test).
    await pumpGolden(
      tester,
      BlocProvider<AccountFormCubit>.value(
        value: cubit,
        child: const AccountFormPage(),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(),
    );
    await expectLater(
      find.byType(AccountFormPage),
      matchesGoldenFile('goldens/account_form_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('create, no type chosen ($suffix)', (tester) async {
      await golden(
        tester,
        const AccountFormState(status: AccountFormStatus.ready),
        'create_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('edit, bank account ($suffix)', (tester) async {
      await golden(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          id: 'acc-1',
          type: AccountType.bank,
          name: 'Bancolombia',
          institution: 'Bancolombia',
          initialBalanceText: '450050',
        ),
        'edit_bank_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('card details section expanded ($suffix)', (tester) async {
      await golden(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.card,
          name: 'Visa Oro',
          creditLimitText: '3000000',
          statementDay: 15,
          paymentDueDay: 5,
          last4: '4321',
        ),
        'card_section_$suffix',
        brightness: brightness,
      );
    });
  }
}
