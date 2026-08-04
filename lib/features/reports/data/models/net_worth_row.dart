/// One SQL-aggregated bucket of the signed delta that alive accounts'
/// balances moved by, out of the patrimonio query. Internal DTO — never
/// leaves `data/`.
///
/// Only the account-balance ("líquido") side is expressed as a bucketed SQL
/// sum: the debt ledger side of patrimonio total is reconstructed from raw
/// rows via `DebtBalanceCalculator`/`DebtEventRules` instead (see
/// `ReportsRepositoryImpl`), to reuse their signing rules rather than
/// duplicate them in SQL `CASE` expressions.
class AccountBalanceBucketRow {
  const AccountBalanceBucketRow({
    required this.bucketKey,
    required this.deltaMinor,
  });

  /// Same format as `CashflowRow.bucketKey`.
  final String bucketKey;

  /// Signed change (cents) to the sum of in-scope accounts' balances during
  /// this bucket.
  final int deltaMinor;
}
