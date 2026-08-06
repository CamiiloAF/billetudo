/// One SQL-aggregated bucket (a month or a day) out of the flujo de caja
/// query. Internal DTO — never leaves `data/`; `ReportsRepositoryImpl` maps
/// it into the domain `CashflowPoint`.
class CashflowRow {
  const CashflowRow({
    required this.bucketKey,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.debtIncomeMinor,
    required this.debtExpenseMinor,
  });

  /// `strftime('%Y-%m', ...)` or `strftime('%Y-%m-%d', ...)`, matching the
  /// query's granularity — the raw SQL group key, parsed back into a
  /// `DateTime` bucket start by the repository.
  final String bucketKey;
  final int incomeMinor;
  final int expenseMinor;
  final int debtIncomeMinor;
  final int debtExpenseMinor;
}
