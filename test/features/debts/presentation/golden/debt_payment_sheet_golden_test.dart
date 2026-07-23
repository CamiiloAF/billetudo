import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_payment_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_payment_state.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_payment_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../accounts/account_fixtures.dart';
import '../debts_presentation_fixtures.dart';

class MockDebtPaymentCubit extends MockCubit<DebtPaymentState>
    implements DebtPaymentCubit {}

/// Registrar abono (`xbsY3` Sí / `V6Z9ln` No, HU-02): the amount héroe, the
/// "¿Agregar a una cuenta?" switch (revealing the account + category when on,
/// hiding them behind a cash-less copy when off), and the "Enlaza un movimiento"
/// escape hatch. Both toggle states, in light and dark.
void main() {
  late MockDebtPaymentCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockDebtPaymentCubit());

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
        categoryId: addToAccount ? 'c1' : null,
        categoryName: addToAccount ? 'Cuota crédito' : null,
        date: DateTime(2026, 7, 5),
      );

  Future<void> golden(
    WidgetTester tester,
    DebtPaymentState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BottomSheetBase.show<void>(
              context,
              builder: (_) => BlocProvider<DebtPaymentCubit>.value(
                value: cubit,
                child: DebtPaymentSheetBody(
                  state: state,
                  onLinkExisting: () {},
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/debt_payment_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('toggle Sí: cuenta + categoría reveladas ($suffix)',
        (tester) async {
      await golden(
        tester,
        stateWith(addToAccount: true),
        'add_to_account_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('toggle No: sin cuenta, copy sin caja ($suffix)',
        (tester) async {
      await golden(
        tester,
        stateWith(addToAccount: false),
        'cashless_$suffix',
        brightness: brightness,
      );
    });
  }
}
