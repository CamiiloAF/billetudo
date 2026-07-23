import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_ledger_entry.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_detail_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_detail_state.dart';
import 'package:billetudo/features/debts/presentation/pages/debt_detail_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../debts_presentation_fixtures.dart';

class MockDebtDetailCubit extends MockCubit<DebtDetailState>
    implements DebtDetailCubit {}

/// One debt's detail (`cUzp6`/`ZQIPe`/`tVUoU`, HU-02/HU-03/HU-07): hero,
/// meta card, the cuota card (configured vs. "Configurar cuota"), the
/// running-balance ledger and the fixed "Registrar abono" CTA.
///
/// States captured: loading (skeletons), failure, and three `ready` variants:
///   - `iOwe` + linked cuota + automatic interest ("Crece ~$X/día · estimado")
///   - `owedToMe` + no cuota (the "Configurar cuota" card)
///   - settled (100% pagada, saldo $0)
/// Each in light and dark.
void main() {
  late MockDebtDetailCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockDebtDetailCubit());

  // "Yo debo", accrues automatically, with a linked cuota. Newest-first ledger
  // (interest accrual, then a cash abono, then the opening) with a
  // running-balance aligned index-for-index.
  final iOweDetail = buildDebtDetail(
    debt: buildDebt(
      id: 'd1',
      name: 'Crédito vehicular',
      counterparty: 'Banco de Bogotá',
      accrualMode: DebtAccrualMode.auto,
      interestRateBps: 24000,
      dueDate: DateTime(2026, 12, 15),
    ),
    balance: buildBalance(
      principalMinor: 4200000000,
      totalIncreasesMinor: 4218000000,
      totalDecreasesMinor: 1344000000,
      interestAccruedMinor: 18000000,
    ),
    ledger: [
      buildLedgerEntry(
        id: 'int',
        kind: DebtLedgerKind.interestAccrual,
        date: DateTime(2026, 7, 20),
        effectMinor: 18000000,
        entryId: 'e-int',
      ),
      buildLedgerEntry(
        id: 'pay',
        kind: DebtLedgerKind.cashPayment,
        date: DateTime(2026, 7, 5),
        effectMinor: -100000000,
        transactionId: 't1',
        note: 'Cuota de julio',
      ),
      buildLedgerEntry(
        id: 'open',
        kind: DebtLedgerKind.opening,
        date: DateTime(2026, 1, 1),
        effectMinor: 4200000000,
      ),
    ],
  );

  final iOweReady = DebtDetailState(
    status: DebtDetailStatus.ready,
    detail: iOweDetail,
    runningBalances: const [2874000000, 2856000000, 4200000000],
    dailyGrowthMinor: 2760000,
    installment: DebtInstallmentView(
      scheduledPaymentId: 'sp-9',
      amountMinor: 68000000,
      date: DateTime(2026, 8, 13),
      currency: 'COP',
    ),
  );

  // "Me deben", manual, no cuota configured → the "Configurar cuota" card.
  final owedToMeReady = DebtDetailState(
    status: DebtDetailStatus.ready,
    detail: buildDebtDetail(
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
      ledger: [
        buildLedgerEntry(
          id: 'pay',
          kind: DebtLedgerKind.ledgerPayment,
          date: DateTime(2026, 6, 10),
          effectMinor: -15000000,
          entryId: 'e-1',
        ),
        buildLedgerEntry(
          id: 'open',
          kind: DebtLedgerKind.opening,
          date: DateTime(2026, 5, 1),
          effectMinor: 40000000,
        ),
      ],
    ),
    runningBalances: const [25000000, 40000000],
  );

  // Fully paid: decreases meet increases → outstanding $0, 100% pagada.
  final settledReady = DebtDetailState(
    status: DebtDetailStatus.ready,
    detail: buildDebtDetail(
      debt: buildDebt(
        id: 'd3',
        name: 'Préstamo a mamá',
        counterparty: 'Mamá',
      ),
      balance: buildBalance(
        principalMinor: 200000000,
        totalIncreasesMinor: 200000000,
        totalDecreasesMinor: 200000000,
      ),
      ledger: [
        buildLedgerEntry(
          id: 'pay2',
          kind: DebtLedgerKind.cashPayment,
          date: DateTime(2026, 7, 1),
          effectMinor: -120000000,
          transactionId: 't2',
        ),
        buildLedgerEntry(
          id: 'pay1',
          kind: DebtLedgerKind.cashPayment,
          date: DateTime(2026, 6, 1),
          effectMinor: -80000000,
          transactionId: 't3',
        ),
        buildLedgerEntry(
          id: 'open',
          kind: DebtLedgerKind.opening,
          date: DateTime(2026, 5, 1),
          effectMinor: 200000000,
        ),
      ],
    ),
    runningBalances: const [0, 120000000, 200000000],
  );

  Future<void> golden(
    WidgetTester tester,
    DebtDetailState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<DebtDetailCubit>.value(
        value: cubit,
        child: DebtDetailPage(
          onEdit: (_) {},
          onOpenInstallment: (_) {},
          onConfigureInstallment: (_) {},
          onLinkExisting: (_) {},
        ),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1500),
      settle: settle,
    );
    await expectLater(
      find.byType(DebtDetailPage),
      matchesGoldenFile('goldens/debt_detail_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const DebtDetailState(),
        'loading_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('failure ($suffix)', (tester) async {
      await golden(
        tester,
        const DebtDetailState(status: DebtDetailStatus.failure),
        'failure_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('yo debo, cuota + interés automático ($suffix)',
        (tester) async {
      await golden(
        tester,
        iOweReady,
        'i_owe_with_installment_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('me deben, sin cuota (configurar) ($suffix)', (tester) async {
      await golden(
        tester,
        owedToMeReady,
        'owed_to_me_configure_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('saldada: 100% pagada, saldo \$0 ($suffix)', (tester) async {
      await golden(
        tester,
        settledReady,
        'settled_$suffix',
        brightness: brightness,
      );
    });
  }
}
