import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_update_balance_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_update_balance_state.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_update_balance_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../debts_presentation_fixtures.dart';

class MockDebtUpdateBalanceCubit extends MockCubit<DebtUpdateBalanceState>
    implements DebtUpdateBalanceCubit {}

/// Actualizar saldo (`DEWMf`, HU-06): a "Nuevo saldo" héroe, the reconciliation
/// card ("Saldo estimado hoy" over the signed "Ajuste que se registra"), and
/// the `$primary-soft` strip reassuring that no account moves. Both a downward
/// (−) and an upward (+) adjustment, in light and dark — the adjustment is
/// always neutral toned, never `$expense`, even when it grows.
void main() {
  late MockDebtUpdateBalanceCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockDebtUpdateBalanceCubit());

  DebtUpdateBalanceState stateWith({
    required int currentOutstandingMinor,
    required int targetMinor,
  }) =>
      DebtUpdateBalanceState(
        debt: buildDebt(name: 'Crédito vehicular'),
        currentOutstandingMinor: currentOutstandingMinor,
        targetMinor: targetMinor,
        date: DateTime(2026, 7, 5),
      );

  Future<void> golden(
    WidgetTester tester,
    DebtUpdateBalanceState state,
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
              builder: (_) => BlocProvider<DebtUpdateBalanceCubit>.value(
                value: cubit,
                child: DebtUpdateBalanceSheetBody(state: state),
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
      matchesGoldenFile('goldens/debt_update_balance_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('ajuste hacia abajo (−) ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(
          currentOutstandingMinor: 2856000000,
          targetMinor: 2676000000,
        ),
        'adjust_down_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('ajuste hacia arriba (+) ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(
          currentOutstandingMinor: 2856000000,
          targetMinor: 3036000000,
        ),
        'adjust_up_$suffix',
        brightness: brightness,
      );
    });
  }
}
