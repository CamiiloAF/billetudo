import 'package:equatable/equatable.dart';

/// One expense in a budget's period activity list (HU-04 detail). Enriched with
/// everything the row draws — title, account name and the category's
/// appearance — so it renders without a second lookup. Transfers are never
/// here.
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
  });

  final String id;

  /// Category name when categorized, otherwise the account name.
  final String title;

  /// Account the expense was paid from; the row's subtitle leads with it.
  final String accountName;

  /// Category appearance tokens (lucide name / palette token), null for an
  /// uncategorized expense.
  final String? categoryIcon;
  final String? categoryColor;

  final int amountMinor;
  final String currency;
  final DateTime date;
  final String? note;

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
      ];
}
