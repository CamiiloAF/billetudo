import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_draft.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry_draft.dart';
import 'package:billetudo/features/debts/domain/repositories/debt_repository.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

/// Registers the argument-matcher fallbacks mocktail needs for the custom
/// types this repository takes. Call once from `setUpAll`.
void registerDebtFallbacks() {
  registerFallbackValue(
    const DebtDraft(
      name: 'x',
      direction: DebtDirection.iOwe,
      principalMinor: 0,
      currency: 'COP',
    ),
  );
  registerFallbackValue(
    DebtEntryDraft(
      debtId: 'd1',
      kind: DebtEntryKind.manualAdjustment,
      amountMinor: 0,
      entryDate: DateTime(2026),
    ),
  );
  registerFallbackValue(TransactionType.expense);
}
