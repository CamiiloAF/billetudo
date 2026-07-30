/// One SQL-aggregated row out of the estructura de gasto query: the total
/// expense for a single `categoryId` (a leaf: root or subcategory) in the
/// range. `categoryId == null` is the "Sin categoría" bucket. Internal
/// DTO — `ReportsRepositoryImpl` rolls these up into the root/subcategory
/// tree using the category metadata it loads separately.
class CategoryExpenseRow {
  const CategoryExpenseRow({
    required this.categoryId,
    required this.amountMinor,
  });

  final String? categoryId;
  final int amountMinor;
}
