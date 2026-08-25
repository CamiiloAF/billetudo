import 'package:equatable/equatable.dart';

/// One expense (or presupuestable income) in a budget's period activity list
/// (HU-04 detail). Enriched with everything the row draws — title, account
/// name and the category's appearance — so it renders without a second
/// lookup. A plain (non-presupuestable) transfer is never here.
class BudgetActivityItem extends Equatable {
  const BudgetActivityItem({
    required this.id,
    required this.title,
    required this.accountName,
    required this.amountMinor,
    required this.currency,
    required this.date,
    this.categoryIcon,
    this.categoryColor,
    this.note,
    this.isIncome = false,
    this.isNettedTransfer = false,
    this.secondaryAccountName,
  });

  final String id;

  /// Category name when categorized, otherwise the account name. Ignored by
  /// the row when [isNettedTransfer] is `true` — it draws its own fixed
  /// "Transferencia interna" title from `AppLocalizations` instead.
  final String title;

  /// Account the expense was paid from; the row's subtitle leads with it.
  /// For a [isNettedTransfer] row this is the transfer's origin account.
  final String accountName;

  /// Category appearance tokens (lucide name / palette token), null for an
  /// uncategorized expense.
  final String? categoryIcon;
  final String? categoryColor;

  final int amountMinor;
  final String currency;
  final DateTime date;
  final String? note;

  /// `true` for a presupuestable income row (budget-income-counts-in-budget,
  /// e.g. a debt repayment received): the row shows `+amount` and raises the
  /// disponible, instead of the usual `-amount`.
  final bool isIncome;

  /// `true` when a presupuestable transfer (`countsInBudget = true`) has
  /// **both its origin and destination account in this same budget's
  /// scope**: the origin-side expense row and the destination-side income
  /// row net to zero for this budget's total, and the two are collapsed into
  /// a single row here instead of showing as separate expense/income entries
  /// (`design-system/billetudo/pages/presupuestos.md`, "Fila especial —
  /// Transferencia interna neteada"). `amountMinor` is always `0` on this
  /// row and [isIncome] is meaningless (never both `true`).
  final bool isNettedTransfer;

  /// The transfer's destination account name, only set when
  /// [isNettedTransfer] is `true` — the row's subtitle reads
  /// "`accountName` ↔ `secondaryAccountName` · fecha".
  final String? secondaryAccountName;

  @override
  List<Object?> get props => [
        id,
        title,
        accountName,
        categoryIcon,
        categoryColor,
        amountMinor,
        currency,
        date,
        note,
        isIncome,
        isNettedTransfer,
        secondaryAccountName,
      ];
}
