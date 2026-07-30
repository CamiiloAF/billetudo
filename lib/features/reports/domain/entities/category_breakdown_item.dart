import 'package:equatable/equatable.dart';

/// One row of the estructura de gasto report (HU-03): a root category (or the
/// "Sin categoría" bucket, [categoryId] == null) with its total and, when
/// expanded, its own subcategory rows.
///
/// "Sin categoría" only ever holds debt-linked movements that carry no
/// `categoryId` (see "Reglas de conteo" → Categoría ausente) — normal
/// gasto/ingreso always requires a category.
class CategoryBreakdownItem extends Equatable {
  const CategoryBreakdownItem({
    required this.categoryId,
    required this.name,
    required this.amountMinor,
    this.icon,
    this.color,
    this.subcategories = const [],
  });

  /// Null for the "Sin categoría" bucket.
  final String? categoryId;

  /// Null exactly when [categoryId] is null: the "Sin categoría" bucket has
  /// no name of its own, so the presentation layer must source its label
  /// from `AppLocalizations` (never hardcoded here — `data/` and `domain/`
  /// stay in English/no-UI-copy per CLAUDE.md).
  final String? name;
  final String? icon;
  final String? color;

  /// Total expense (cents) attributed to this row: gasto normal +
  /// transferencias `countsInBudget` (origin side) + cuotas/abonos de deuda
  /// con caja, all in this category (or its subtree, for a root row).
  final int amountMinor;

  /// Only populated on root rows; empty on subcategory rows and on "Sin
  /// categoría". HU-03: "permite expandir a subcategorías".
  final List<CategoryBreakdownItem> subcategories;

  bool get isUncategorized => categoryId == null;

  @override
  List<Object?> get props => [
        categoryId,
        name,
        icon,
        color,
        amountMinor,
        subcategories,
      ];
}
