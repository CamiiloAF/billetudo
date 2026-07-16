import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_deletion_impact.dart';
import '../../domain/usecases/delete_category.dart';

enum CategoryFormStatus {
  /// Reading the category being edited (or its parent, when creating a
  /// subcategory). A new root category skips straight to [ready].
  loading,
  ready,
  saving,

  /// Persisted (create/update) or deleted: the page pops.
  saved,
  failure,
}

/// Why the Tipo toggle is locked (`categorias.md`): the two cases carry
/// different copy, so the page needs to tell them apart.
enum CategoryKindLockReason {
  /// Not locked.
  none,

  /// A subcategory always inherits its root's kind.
  subcategory,

  /// A root category with active subcategories cannot change kind without
  /// breaking their coherence.
  rootWithSubcategories,
}

/// Which of the 3 delete confirmation sheets (HU-04) is showing, if any. When
/// a root has both associated transactions and active subcategories, the
/// flow asks [transactions] first, then chains into [subcategories] before
/// deleting — see `CategoryFormCubit`.
enum CategoryDeletePrompt { none, simple, transactions, subcategories }

/// State of the single add/edit form that covers all 4 cases of
/// `categorias.md` (`CuTjr`/`iUmrh`/`PZvWF`/`STIfS`), plus its delete flow.
class CategoryFormState extends Equatable {
  const CategoryFormState({
    this.status = CategoryFormStatus.loading,
    this.id,
    this.parentId,
    this.parentName,
    this.name = '',
    this.icon,
    this.color,
    this.kind = CategoryKind.expense,
    this.kindLockReason = CategoryKindLockReason.none,
    this.deletionImpact,
    this.deletePrompt = CategoryDeletePrompt.none,
    this.pendingTransactionResolution,
    this.failure,
  });

  static const String fieldName = 'name';

  final CategoryFormStatus status;

  /// `null` while creating; the category id while editing.
  final String? id;

  /// `null` for a root category; the parent root's id for a subcategory —
  /// prefilled and read-only when creating from "Agregar subcategoría",
  /// editable (reclassify) when editing an existing subcategory.
  final String? parentId;

  /// The parent's display name, so the read-only/tappable field can show
  /// something a user recognizes instead of a raw id.
  final String? parentName;

  final String name;
  final String? icon;
  final String? color;
  final CategoryKind kind;
  final CategoryKindLockReason kindLockReason;

  /// Loaded on demand (`promptDelete`), drives which sheet shows.
  final CategoryDeletionImpact? deletionImpact;
  final CategoryDeletePrompt deletePrompt;

  /// Set while chaining the transactions step into the subcategories step of
  /// a combined delete (HU-04, both conditions on the same root).
  final TransactionResolution? pendingTransactionResolution;

  final Failure? failure;

  bool get isEditing => id != null;
  bool get isSubcategory => parentId != null;
  bool get kindLocked => kindLockReason != CategoryKindLockReason.none;

  String? get failedField =>
      failure is ValidationFailure ? (failure! as ValidationFailure).field : null;

  CategoryFormState copyWith({
    CategoryFormStatus? status,
    String? id,
    String? parentId,
    bool clearParentId = false,
    String? parentName,
    String? name,
    String? icon,
    String? color,
    CategoryKind? kind,
    CategoryKindLockReason? kindLockReason,
    CategoryDeletionImpact? deletionImpact,
    CategoryDeletePrompt? deletePrompt,
    TransactionResolution? pendingTransactionResolution,
    bool clearPendingTransactionResolution = false,
    Failure? failure,
  }) =>
      CategoryFormState(
        status: status ?? this.status,
        id: id ?? this.id,
        parentId: clearParentId ? null : parentId ?? this.parentId,
        parentName: clearParentId ? null : parentName ?? this.parentName,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        kind: kind ?? this.kind,
        kindLockReason: kindLockReason ?? this.kindLockReason,
        deletionImpact: deletionImpact ?? this.deletionImpact,
        deletePrompt: deletePrompt ?? this.deletePrompt,
        pendingTransactionResolution: clearPendingTransactionResolution
            ? null
            : pendingTransactionResolution ?? this.pendingTransactionResolution,
        // A new state carrying data is a state without an error: the caller
        // clears the failure by simply not passing one.
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        id,
        parentId,
        parentName,
        name,
        icon,
        color,
        kind,
        kindLockReason,
        deletionImpact,
        deletePrompt,
        pendingTransactionResolution,
        failure,
      ];
}
