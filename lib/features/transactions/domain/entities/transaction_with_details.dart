import 'package:equatable/equatable.dart';

import 'tag.dart';
import 'transaction.dart';

/// A [Transaction] enriched with the display data the list and the detail
/// screen need (HU-06/HU-08): the name of its account(s), its category, and
/// its tags.
///
/// Data-layer joins produce this; it never carries Drift types.
class TransactionWithDetails extends Equatable {
  const TransactionWithDetails({
    required this.transaction,
    required this.accountName,
    this.transferAccountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.tags = const <Tag>[],
    this.debtName,
  });

  final Transaction transaction;
  final String accountName;

  /// Only set when [Transaction.type] is `transfer`.
  final String? transferAccountName;

  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  final List<Tag> tags;

  /// Only set when [Transaction.debtId] is non-null (HU-08/deudas): the name
  /// of the debt this transaction is linked to, so the detail screen can
  /// surface the link instead of showing just the generic category.
  final String? debtName;

  @override
  List<Object?> get props => [
        transaction,
        accountName,
        transferAccountName,
        categoryName,
        categoryIcon,
        categoryColor,
        tags,
        debtName,
      ];
}
