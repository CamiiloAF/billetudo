import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_balance.dart';
import 'package:billetudo/features/debts/domain/entities/debt_detail.dart';
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
}) =>
    DebtWithBalance(
      debt: debt ?? buildDebt(),
      balance: balance ?? buildBalance(),
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
}) =>
    DebtDetail(
      debt: debt ?? buildDebt(),
      balance: balance ?? buildBalance(),
      ledger: ledger ?? const [],
    );
