import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart';

enum CategoryQuickPickerStatus { loading, ready, failure }

/// State of the transaction form's Category Quick Picker: the 3 most-used
/// categories of the current `kind` plus the currently selected one, resolved
/// as full entities so every chip can render its icon/color.
class CategoryQuickPickerState extends Equatable {
  const CategoryQuickPickerState({
    this.status = CategoryQuickPickerStatus.loading,
    this.mostUsed = const <Category>[],
    this.selected,
    this.failure,
  });

  final CategoryQuickPickerStatus status;

  /// The most-used categories of the active kind (top 3 by default).
  final List<Category> mostUsed;

  /// The currently selected category, or `null` when none is chosen.
  final Category? selected;

  final Failure? failure;

  String? get selectedId => selected?.id;

  bool get isReady => status == CategoryQuickPickerStatus.ready;

  /// The category chips to render: the most-used set (top 3), with the
  /// current selection prepended as an extra chip when it falls outside that
  /// set (edge case: the user picked a category that isn't among their top
  /// 3). This keeps the current choice always visible without hiding a
  /// most-used category — capped at 3 total, per the `EIoVx` spec (3
  /// category chips + the "Ver más" chip), dropping the least-used one to
  /// make room.
  List<Category> get displayCategories {
    final current = selected;
    if (current == null ||
        mostUsed.any((category) => category.id == current.id)) {
      return mostUsed.take(3).toList();
    }
    return [current, ...mostUsed].take(3).toList();
  }

  CategoryQuickPickerState copyWith({
    CategoryQuickPickerStatus? status,
    List<Category>? mostUsed,
    Category? selected,
    Failure? failure,
    bool clearSelected = false,
  }) =>
      CategoryQuickPickerState(
        status: status ?? this.status,
        mostUsed: mostUsed ?? this.mostUsed,
        selected: clearSelected ? null : (selected ?? this.selected),
        failure: failure,
      );

  @override
  List<Object?> get props => [status, mostUsed, selected, failure];
}
