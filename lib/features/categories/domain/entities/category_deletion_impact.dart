import 'package:equatable/equatable.dart';

/// What deleting a category would affect (HU-04). Drives which of the 3
/// confirmation bottom sheets the UI shows. Shown before confirming, in
/// neutral terms — never as a scolding (`CLAUDE.md`).
class CategoryDeletionImpact extends Equatable {
  const CategoryDeletionImpact({
    required this.hasActiveSubcategories,
    required this.transactionCount,
    this.budgetCount = 0,
  });

  /// Whether the category has active (not tombstoned, not deleted)
  /// subcategories. Only ever true for a root category, since subcategories
  /// cannot themselves have children (max depth 2 levels).
  final bool hasActiveSubcategories;

  /// Active transactions (`deletedAt IS NULL`) that reference this category
  /// by `categoryId`.
  final int transactionCount;

  /// Active budgets whose scope references this category (Presupuestos HU-06).
  /// The budget is not deleted in cascade; the confirmation only tells the user
  /// the category is used there, and restoring it repopulates the scope.
  final int budgetCount;

  bool get hasImpact =>
      hasActiveSubcategories || transactionCount > 0 || budgetCount > 0;

  @override
  List<Object?> get props =>
      [hasActiveSubcategories, transactionCount, budgetCount];
}
