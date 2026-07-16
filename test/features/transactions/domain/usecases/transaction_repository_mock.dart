import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/repositories/tag_repository.dart';
import 'package:billetudo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockTagRepository extends Mock implements TagRepository {}

/// Registers the fallbacks mocktail needs for `any()` on custom types.
void registerTransactionFallbacks() {
  registerFallbackValue(
    TransactionDraft(
      accountId: 'fallback',
      amountMinor: 1,
      currency: 'COP',
      type: TransactionType.expense,
      date: DateTime(2026),
    ),
  );
  registerFallbackValue(TransactionFilter());
}
