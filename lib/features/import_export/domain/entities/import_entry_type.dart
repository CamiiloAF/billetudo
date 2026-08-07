/// Mirrors `EntryType`/Transactions' `TransactionType`, declared locally so
/// this feature's domain never depends on another feature's domain or on
/// Drift (same pattern `features/transactions/domain/entities/transaction.dart`
/// uses for its own mirror of the Drift enum).
enum ImportEntryType { income, expense, transfer }
