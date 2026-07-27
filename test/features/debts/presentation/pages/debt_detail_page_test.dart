import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/error_state.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_ledger_entry.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_detail_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_detail_state.dart';
import 'package:billetudo/features/debts/presentation/pages/debt_detail_page.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_configure_installment_card.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_hero_card.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_installment_card.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_ledger_row.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_meta_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../debts_presentation_fixtures.dart';

class MockDebtDetailCubit extends MockCubit<DebtDetailState>
    implements DebtDetailCubit {}

void main() {
  late MockDebtDetailCubit cubit;

  final detail = buildDebtDetail(
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
    ledger: [
      buildLedgerEntry(
        id: 'pay',
        kind: DebtLedgerKind.cashPayment,
        effectMinor: -100000000,
        transactionId: 't1',
      ),
      buildLedgerEntry(
        id: 'open',
        kind: DebtLedgerKind.opening,
        effectMinor: 4200000000,
      ),
    ],
  );

  final readyState = DebtDetailState(
    status: DebtDetailStatus.ready,
    detail: detail,
    runningBalances: const [2856000000, 4200000000],
  );

  setUp(() => cubit = MockDebtDetailCubit());

  Future<void> pump(
    WidgetTester tester,
    DebtDetailState state, {
    void Function(Debt debt, int outstandingMinor)? onConfigureInstallment,
    ValueChanged<String>? onOpenInstallment,
    ValueChanged<String>? onOpenTransaction,
  }) async {
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DebtDetailCubit>.value(
          value: cubit,
          child: DebtDetailPage(
            onEdit: (_) {},
            onOpenInstallment: onOpenInstallment ?? (_) {},
            onConfigureInstallment: onConfigureInstallment ?? (_, __) {},
            onLinkExisting: (_) {},
            onOpenTransaction: onOpenTransaction ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('ready: hero, meta card, filas de ledger y CTA fijo',
      (tester) async {
    await pump(tester, readyState);
    expect(find.byType(DebtHeroCard), findsOneWidget);
    expect(find.byType(DebtMetaCard), findsOneWidget);
    expect(find.byType(DebtLedgerRow), findsNWidgets(2));
    expect(find.text('Registrar abono'), findsOneWidget);
    expect(find.text('Crédito vehicular'), findsOneWidget);
  });

  testWidgets('carga: no muestra hero ni error', (tester) async {
    await pump(tester, const DebtDetailState());
    expect(find.byType(DebtHeroCard), findsNothing);
    expect(find.byType(ErrorState), findsNothing);
  });

  testWidgets('error: ErrorState con el título del detalle', (tester) async {
    await pump(tester, const DebtDetailState(status: DebtDetailStatus.failure));
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('No pudimos cargar esta deuda'), findsOneWidget);
  });

  group('HU-03: cuota en el detalle', () {
    testWidgets(
        'sin cuota configurada muestra la card "Configurar cuota" y la abre al '
        'tocarla', (tester) async {
      Debt? configuredDebt;
      await pump(
        tester,
        readyState,
        onConfigureInstallment: (debt, _) => configuredDebt = debt,
      );

      expect(find.byType(DebtConfigureInstallmentCard), findsOneWidget);
      expect(find.byType(DebtInstallmentCard), findsNothing);
      expect(find.text('Configurar cuota'), findsOneWidget);

      await tester.tap(find.byType(DebtConfigureInstallmentCard));
      await tester.pumpAndSettle();
      expect(configuredDebt?.id, 'd1');
    });

    testWidgets(
        'con cuota configurada muestra la card de próxima cuota y cross-linkea '
        'a Pagos programados', (tester) async {
      String? openedSpId;
      await pump(
        tester,
        readyState.copyWith(
          installment: DebtInstallmentView(
            scheduledPaymentId: 'sp-9',
            amountMinor: 68000000,
            date: DateTime(2026, 8, 13),
            currency: 'COP',
          ),
        ),
        onOpenInstallment: (id) => openedSpId = id,
      );

      expect(find.byType(DebtInstallmentCard), findsOneWidget);
      expect(find.byType(DebtConfigureInstallmentCard), findsNothing);
      expect(find.text('Próxima cuota'), findsOneWidget);

      await tester.tap(find.byType(DebtInstallmentCard));
      await tester.pumpAndSettle();
      expect(openedSpId, 'sp-9');
    });
  });

  group('HU-04: ver el movimiento desde el ledger (3c)', () {
    testWidgets('tocar una fila cash abre el detalle de su movimiento',
        (tester) async {
      String? openedTx;
      await pump(
        tester,
        readyState,
        onOpenTransaction: (id) => openedTx = id,
      );

      // The first ledger row is the cash payment (transactionId 't1').
      await tester.tap(find.byType(DebtLedgerRow).first);
      await tester.pumpAndSettle();
      expect(openedTx, 't1');
    });

    testWidgets('la fila de apertura (sin transactionId) no navega',
        (tester) async {
      var opened = false;
      await pump(
        tester,
        readyState,
        onOpenTransaction: (_) => opened = true,
      );

      // The second ledger row is the opening balance: no movement behind it.
      await tester.tap(find.byType(DebtLedgerRow).at(1));
      await tester.pumpAndSettle();
      expect(opened, isFalse);
    });

    testWidgets(
        'la fila de apertura muestra el snackbar de feedback sin acción '
        '"Enlazar"', (tester) async {
      await pump(tester, readyState);

      // The second ledger row is the synthetic opening balance.
      await tester.tap(find.byType(DebtLedgerRow).at(1));
      await tester.pump();
      expect(find.text('Saldo inicial · sin cuenta enlazada'), findsOneWidget);
      expect(find.text('Enlazar'), findsNothing);
      expect(find.byType(SnackBarAction), findsNothing);
    });
  });

  testWidgets(
      'tocar un abono sin caja (ledgerPayment sin tx) muestra el snackbar de '
      'feedback', (tester) async {
    final abonoState = DebtDetailState(
      status: DebtDetailStatus.ready,
      detail: buildDebtDetail(
        debt: buildDebt(id: 'd1', name: 'Préstamo a Ana'),
        balance: buildBalance(
          principalMinor: 100000,
          totalIncreasesMinor: 100000,
          totalDecreasesMinor: 20000,
        ),
        ledger: [
          buildLedgerEntry(
            id: 'abono',
            kind: DebtLedgerKind.ledgerPayment,
            effectMinor: -20000,
          ),
          buildLedgerEntry(
            id: 'open',
            kind: DebtLedgerKind.opening,
            effectMinor: 100000,
          ),
        ],
      ),
      runningBalances: const [80000, 100000],
    );

    await pump(tester, abonoState);

    // The first row is the cash-less abono: no movement behind it.
    await tester.tap(find.byType(DebtLedgerRow).first);
    await tester.pump();
    expect(find.text('Este abono no movió ninguna cuenta'), findsOneWidget);
  });
}
