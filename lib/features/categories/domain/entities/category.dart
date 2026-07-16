import 'package:equatable/equatable.dart';

/// What a category is for. Mirrors `CategoryKind` stored as text in Drift,
/// but is declared here so the domain never depends on the database layer.
enum CategoryKind { income, expense }

/// A user category: root or subcategory, for income or expense.
///
/// Pure domain entity: no Drift types. Hierarchy is expressed with
/// [parentId]: `null` means this is a root category, otherwise it is a
/// subcategory of the category with that id (HU-02). The hierarchy supports
/// at most 2 levels (root -> subcategory); enforcing that is a use case
/// concern, not this entity's.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.icon,
    this.color,
  });

  /// UUID as text.
  final String id;
  final String name;
  final CategoryKind kind;

  /// `null` = root category; otherwise the id of the root this subcategory
  /// belongs to.
  final String? parentId;

  /// Lucide icon name (see `billetudo.pen` icon picker), e.g. 'utensils'.
  final String? icon;

  /// One of the 7 decorative palette tokens (e.g. 'mint', 'sky'), never a raw
  /// hex — colors are always resolved from the design system's variables.
  final String? color;

  final int sortOrder;
  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` (schema v5) — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  bool get isRoot => parentId == null;

  @override
  List<Object?> get props => [
        id,
        name,
        kind,
        parentId,
        icon,
        color,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}
