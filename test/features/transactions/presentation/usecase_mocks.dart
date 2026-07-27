import 'package:billetudo/core/preferences/account_filter_preference_datasource.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/usecases/create_tag.dart';
import 'package:billetudo/features/transactions/domain/usecases/create_transaction.dart';
import 'package:billetudo/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:billetudo/features/transactions/domain/usecases/get_transaction_edit_impact.dart';
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:billetudo/features/transactions/domain/usecases/set_transaction_tags.dart';
import 'package:billetudo/features/transactions/domain/usecases/update_transaction.dart';
import 'package:billetudo/features/transactions/domain/usecases/watch_tags.dart';
import 'package:billetudo/features/transactions/domain/usecases/watch_transaction_detail.dart';
import 'package:billetudo/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:mocktail/mocktail.dart';

/// The cubits only ever talk to use cases, so these are the only seams the
/// presentation tests need.
class MockWatchTransactions extends Mock implements WatchTransactions {}

class MockWatchTransactionDetail extends Mock
    implements WatchTransactionDetail {}

class MockCreateTransaction extends Mock implements CreateTransaction {}

class MockUpdateTransaction extends Mock implements UpdateTransaction {}

class MockDeleteTransaction extends Mock implements DeleteTransaction {}

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

class MockGetTransactionEditImpact extends Mock
    implements GetTransactionEditImpact {}

class MockSetTransactionTags extends Mock implements SetTransactionTags {}

class MockCreateTag extends Mock implements CreateTag {}

class MockWatchTags extends Mock implements WatchTags {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockWatchCategories extends Mock implements WatchCategories {}

class MockAccountFilterPreferenceDatasource extends Mock
    implements AccountFilterPreferenceDatasource {}

/// Fallbacks mocktail needs for `any()` on the feature's own types.
void registerPresentationFallbacks() {
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
  registerFallbackValue(CategoryKind.expense);
  registerFallbackValue(
    Transaction(
      id: 'fallback',
      accountId: 'fallback',
      amountMinor: 1,
      currency: 'COP',
      type: TransactionType.expense,
      date: DateTime(2026),
      source: TransactionSource.manual,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026).millisecondsSinceEpoch,
    ),
  );
}
