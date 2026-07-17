import 'package:equatable/equatable.dart';

/// One expense in a budget's period activity list (HU-04 detail). Enriched with
/// the display title (category name, falling back to the account name) so the
/// row renders without a second lookup. Transfers are never here.
class BudgetActivityItem extends Equatable {
  const BudgetActivityItem({
    required this.id,
    required this.title,
    required this.amountMinor,
    required this.currency,
    required this.date,
    this.note,
  });

  final String id;

  /// Category name when categorized, otherwise the account name.
  final String title;
  final int amountMinor;
  final String currency;
  final DateTime date;
  final String? note;

  @override
  List<Object?> get props => [id, title, amountMinor, currency, date, note];
}
