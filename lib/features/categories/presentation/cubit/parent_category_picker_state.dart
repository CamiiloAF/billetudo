import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/category.dart';

enum ParentCategoryPickerStatus { loading, ready, failure }

/// State of the category picker sheet (`Q55fEz`), reused for two purposes
/// (see `categorias.md`'s pending note):
///  - the "Categoría padre" field of the subcategory form, restricted to root
///    categories (`Parent Category Row`, tap-to-choose-and-close);
///  - the "Reasignar a otra categoría" pickers of HU-04, which reuse the same
///    row but are not restricted to roots when reassigning transactions.
class ParentCategoryPickerState extends Equatable {
  const ParentCategoryPickerState({
    this.status = ParentCategoryPickerStatus.loading,
    this.candidates = const [],
    this.selectedId,
    this.failure,
  });

  final ParentCategoryPickerStatus status;
  final List<Category> candidates;

  /// The currently chosen candidate, so `Parent Category Row` can render its
  /// check mark.
  final String? selectedId;

  final Failure? failure;

  bool get isLoading => status == ParentCategoryPickerStatus.loading;

  ParentCategoryPickerState copyWith({
    ParentCategoryPickerStatus? status,
    List<Category>? candidates,
    String? selectedId,
    Failure? failure,
  }) =>
      ParentCategoryPickerState(
        status: status ?? this.status,
        candidates: candidates ?? this.candidates,
        selectedId: selectedId ?? this.selectedId,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, candidates, selectedId, failure];
}
