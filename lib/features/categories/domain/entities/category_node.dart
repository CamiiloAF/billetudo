import 'package:equatable/equatable.dart';

import 'category.dart';

/// A root category together with its (active) subcategories, ordered by
/// `sortOrder` — the shape the accordion of the main listing needs
/// (HU-05/HU-12).
class CategoryNode extends Equatable {
  const CategoryNode({required this.root, this.subcategories = const []});

  final Category root;
  final List<Category> subcategories;

  int get subcategoryCount => subcategories.length;

  bool get hasSubcategories => subcategories.isNotEmpty;

  @override
  List<Object?> get props => [root, subcategories];
}
