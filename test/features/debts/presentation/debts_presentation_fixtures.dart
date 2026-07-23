import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_balance.dart';
import 'package:billetudo/features/debts/domain/entities/debt_detail.dart';
import 'package:billetudo/features/debts/domain/entities/debt_installment.dart';
import 'package:billetudo/features/debts/domain/entities/debt_ledger_entry.dart';
import 'package:billetudo/features/debts/domain/entities/debt_with_balance.dart';

import '../domain/debt_test_fixtures.dart';

export '../domain/debt_test_fixtures.dart';

DebtBalance buildBalance({
  int principalMinor = 0,
  int totalIncreasesMinor = 0,
  int totalDecreasesMinor = 0,
  int interestAccruedMinor = 0,
}) =>
    DebtBalance(
      principalMinor: principalMinor,
      totalIncreasesMinor: totalIncreasesMinor,
      totalDecreasesMinor: totalDecreasesMinor,
      interestAccruedMinor: interestAccruedMinor,
    );

DebtWithBalance buildDebtWithBalance({
  Debt? debt,
  DebtBalance? balance,
  DebtInstallment? installment,
}) =>
    DebtWithBalance(
      debt: debt ?? buildDebt(),
      balance: balance ?? buildBalance(),
      installment: installment,
    );

DebtLedgerEntry buildLedgerEntry({
  String id = 'l1',
  DebtLedgerKind kind = DebtLedgerKind.cashPayment,
  DateTime? date,
  int effectMinor = 0,
  String? note,
  String? transactionId,
  String? entryId,
}) =>
    DebtLedgerEntry(
      id: id,
      kind: kind,
      date: date ?? DateTime(2026, 7, 5),
      effectMinor: effectMinor,
      note: note,
      transactionId: transactionId,
      entryId: entryId,
    );

DebtDetail buildDebtDetail({
  Debt? debt,
  DebtBalance? balance,
  List<DebtLedgerEntry>? ledger,
  DebtInstallment? installment,
}) =>
    DebtDetail(
      debt: debt ?? buildDebt(),
      balance: balance ?? buildBalance(),
      ledger: ledger ?? const [],
      installment: installment,
    );

DebtInstallment buildDebtInstallment({
  String scheduledPaymentId = 'sp-1',
  int amountMinor = 100000000,
  DateTime? nextDate,
  String currency = 'COP',
}) =>
    DebtInstallment(
      scheduledPaymentId: scheduledPaymentId,
      amountMinor: amountMinor,
      nextDate: nextDate ?? DateTime(2026, 8, 13),
      currency: currency,
    );
