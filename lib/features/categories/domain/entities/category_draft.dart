import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import 'category.dart';

/// Input for creating or editing a category (HU-01/HU-02/HU-03).
///
/// Structural validation (name required/length) lives in [validated]; the
/// business rules that need a repository lookup — parent existence, kind
/// coherence, max depth — live in the use cases (`CreateCategory` /
/// `UpdateCategory`), which is why this draft never resolves them itself.
class CategoryDraft extends Equatable {
  const CategoryDraft({
    required this.name,
    required this.kind,
    this.id,
    this.parentId,
    this.icon,
    this.color,
  });

  // Field keys, so presentation matches `ValidationFailure.field` without
  // duplicating magic strings.
  static const String fieldId = 'id';
  static const String fieldName = 'name';
  static const String fieldKind = 'kind';
  static const String fieldParentId = 'parentId';

  static const int maxNameLength = 100;

  /// `null` when creating; the category id when editing.
  final String? id;
  final String name;
  final CategoryKind kind;

  /// `null` = this draft describes a root category.
  final String? parentId;
  final String? icon;
  final String? color;

  /// Validates the structural rules of HU-01/HU-02 (name required, 1-100
  /// chars) and returns a **normalized** draft: trimmed name, blank
  /// icon/color turned into `null`.
  ///
  /// Returns `Left(ValidationFailure)` with the offending `field` set, so the
  /// form can highlight it.
  Result<CategoryDraft> validated() {
    final name = this.name.trim();
    if (name.isEmpty) {
      return const Left(
        ValidationFailure('category name is required', field: fieldName),
      );
    }
    if (name.length > maxNameLength) {
      return const Left(
        ValidationFailure(
          'category name exceeds $maxNameLength characters',
          field: fieldName,
        ),
      );
    }

    return Right(
      CategoryDraft(
        id: id,
        name: name,
        kind: kind,
        parentId: parentId,
        icon: _blankToNull(icon),
        color: _blankToNull(color),
      ),
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  List<Object?> get props => [id, name, kind, parentId, icon, color];
}
