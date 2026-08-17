import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_ledger_entry.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_ledger_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../debts_presentation_fixtures.dart';

/// Fix A: every solo-deuda row that is not the synthetic opening row (a
/// cash-less abono/desembolso, an interest accrual, or a manual adjustment)
/// must open the movement-detail sheet — a snackbar-only feedback used to
/// cover only `ledgerPayment`, silently leaving `ledgerDisbursement`,
/// `interestAccrual` and `manualAdjustment` completely inert.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required DebtLedgerEntry entry,
    ValueChanged<DebtLedgerEntry>? onOpenMovementDetail,
    ValueChanged<String>? onOpenTransaction,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DebtLedgerRow(
              entry: entry,
              direction: DebtDirection.iOwe,
              runningMinor: 100000,
              currency: 'COP',
              onOpenTransaction: onOpenTransaction,
              onOpenMovementDetail: onOpenMovementDetail,
            ),
          ),
        ),
      );

  for (final kind in [
    DebtLedgerKind.ledgerPayment,
    DebtLedgerKind.ledgerDisbursement,
    DebtLedgerKind.interestAccrual,
    DebtLedgerKind.manualAdjustment,
  ]) {
    testWidgets('$kind opens the movement-detail sheet on tap',
        (tester) async {
      DebtLedgerEntry? tapped;
      final entry = buildLedgerEntry(kind: kind, effectMinor: -1000, entryId: 'e1');
      await pump(
        tester,
        entry: entry,
        onOpenMovementDetail: (e) => tapped = e,
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, entry);
    });
  }

  testWidgets('a cash row never calls onOpenMovementDetail, only onOpenTransaction',
      (tester) async {
    DebtLedgerEntry? movementTapped;
    String? transactionTapped;
    final entry = buildLedgerEntry(
      kind: DebtLedgerKind.cashPayment,
      effectMinor: -1000,
      transactionId: 't1',
    );
    await pump(
      tester,
      entry: entry,
      onOpenMovementDetail: (e) => movementTapped = e,
      onOpenTransaction: (id) => transactionTapped = id,
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(transactionTapped, 't1');
    expect(movementTapped, isNull);
  });

  testWidgets('the opening row never calls onOpenMovementDetail', (tester) async {
    DebtLedgerEntry? movementTapped;
    final entry = buildLedgerEntry(
      kind: DebtLedgerKind.opening,
      effectMinor: 100000,
    );
    await pump(
      tester,
      entry: entry,
      onOpenMovementDetail: (e) => movementTapped = e,
    );

    // No `onLinkOpening` callback is wired here, so the opening row renders
    // inert (no `InkWell`) — this asserts it never falls through to the
    // movement-detail branch instead.
    expect(find.byType(InkWell), findsNothing);
    expect(movementTapped, isNull);
  });
}
