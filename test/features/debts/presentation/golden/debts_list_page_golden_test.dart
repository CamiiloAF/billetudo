import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debts_summary.dart';
import 'package:billetudo/features/debts/presentation/cubit/debts_list_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debts_list_state.dart';
import 'package:billetudo/features/debts/presentation/pages/debts_list_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../debts_presentation_fixtures.dart';

class MockDebtsListCubit extends MockCubit<DebtsListState>
    implements DebtsListCubit {}

/// The debts list (`rPgbX`/`qfpUI`/`hp9rU`/`d64hv`, HU-04): the per-currency
/// "Yo debo / Me deben" summary card(s) on top, then a `DebtCard` per debt.
///
/// States captured: loading (summary + four card skeletons), empty/onboarding,
/// with data (two currencies so both summary cards render, mixing `iOwe` and
/// `owedToMe`), and the load failure. Each in light and dark.
void main() {
  late MockDebtsListCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockDebtsListCubit());

  // One COP "Yo debo" + one COP "Me deben" (they share the first summary card)
  // and one USD "Yo debo" (a second summary card), so the per-currency split
  // (HU-04, never a cross-currency sum) renders in the golden.
  final summary = DebtsSummary.from([
    buildDebtWithBalance(
      debt: buildDebt(
        id: 'd1',
        name: 'Crédito vehicular',
        counterparty: 'Banco de Bogotá',
      ),
      balance: buildBalance(
        principalMinor: 4200000000,
        totalIncreasesMinor: 4200000000,
        totalDecreasesMinor: 1344000000,
      ),
      // A linked cuota, so the "Cuota · <fecha>" badge (`tHLtM`) renders — the
      // mockup's card. The other two show no meta (no cuota, no dueDate).
      installment: buildDebtInstallment(nextDate: DateTime(2026, 8, 5)),
    ),
    buildDebtWithBalance(
      debt: buildDebt(
        id: 'd2',
        name: 'Le presté a Andrés',
        counterparty: 'Andrés',
        direction: DebtDirection.owedToMe,
      ),
      balance: buildBalance(
        principalMinor: 40000000,
        totalIncreasesMinor: 40000000,
        totalDecreasesMinor: 15000000,
      ),
    ),
    buildDebtWithBalance(
      debt: buildDebt(
        id: 'd3',
        name: 'Adelanto de nómina',
        currency: 'USD',
        counterparty: 'Empresa',
      ),
      balance: buildBalance(
        principalMinor: 120000,
        totalIncreasesMinor: 120000,
        totalDecreasesMinor: 30000,
      ),
    ),
  ]);

  Future<void> golden(
    WidgetTester tester,
    DebtsListState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<DebtsListCubit>.value(
        value: cubit,
        child: DebtsListPage(onAddDebt: () {}, onOpenDebt: (_) {}),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1400),
      settle: settle,
    );
    await expectLater(
      find.byType(DebtsListPage),
      matchesGoldenFile('goldens/debts_list_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const DebtsListState(),
        'loading_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty / onboarding ($suffix)', (tester) async {
      await golden(
        tester,
        const DebtsListState(status: DebtsListStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data: per-currency summary + debts ($suffix)',
        (tester) async {
      await golden(
        tester,
        DebtsListState(status: DebtsListStatus.ready, summary: summary),
        'with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        const DebtsListState(status: DebtsListStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
