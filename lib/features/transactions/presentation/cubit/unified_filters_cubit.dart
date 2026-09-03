import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../categories/domain/entities/category_node.dart';
import '../../../categories/domain/usecases/watch_categories.dart';
import '../../domain/entities/budget_period_option.dart';
import '../../domain/entities/date_period_filter.dart';
import '../../domain/entities/tag.dart';
import '../../domain/entities/transaction.dart' show TransactionType;
import '../../domain/entities/transaction_filter.dart';
import '../../domain/usecases/watch_tags.dart';

enum UnifiedFiltersStatus { loading, ready, failure }

/// Issue #7: the unified filters sheet's own working copy of every dimension
/// except cuenta (which moved to the filter bar's own chips) — edited freely
/// and only handed back to `TransactionsListCubit` when the user taps
/// "Aplicar", exactly like each single-purpose sheet did before it.
class UnifiedFiltersState extends Equatable {
  UnifiedFiltersState({
    this.status = UnifiedFiltersStatus.loading,
    this.budgetOptions = const <BudgetPeriodOption>[],
    this.selectedBudgetId,
    DatePeriodFilter? datePeriod,
    Set<TransactionType> types = const <TransactionType>{},
    this.expenseNodes = const <CategoryNode>[],
    this.incomeNodes = const <CategoryNode>[],
    Set<String> categoryIds = const <String>{},
    this.tags = const <Tag>[],
    Set<String> tagIds = const <String>{},
    this.failure,
  })  : datePeriod = datePeriod ?? DatePeriodFilter.thisMonth(),
        types = Set.unmodifiable(types),
        categoryIds = Set.unmodifiable(categoryIds),
        tagIds = Set.unmodifiable(tagIds);

  final UnifiedFiltersStatus status;

  /// The live "active budgets" list — criterion #6: an empty list hides the
  /// whole Presupuesto section (and its trailing divider) instead of
  /// rendering it empty or disabled.
  final List<BudgetPeriodOption> budgetOptions;

  /// `null` means "no budget chosen" — the sheet's cleared/default state.
  final String? selectedBudgetId;

  /// HU-06b: never a bare "no filter" state, always a bounded period.
  final DatePeriodFilter datePeriod;

  final Set<TransactionType> types;
  final List<CategoryNode> expenseNodes;
  final List<CategoryNode> incomeNodes;

  /// Empty means "all categories".
  final Set<String> categoryIds;

  final List<Tag> tags;

  /// Empty means "no tag filter".
  final Set<String> tagIds;

  final Failure? failure;

  bool get hasBudgets => budgetOptions.isNotEmpty;
  bool get isBudgetActive => selectedBudgetId != null;
  bool get isDateActive => datePeriod != DatePeriodFilter.thisMonth();

  /// The Fecha section's disabled/locked treatment (icon `lock` + caption,
  /// `Granularity Switch`/`Stepper Row` at `opacity: 0.4`): only while a
  /// Presupuesto filter is active, and only meaningful when there are
  /// budgets to begin with — without any, the exclusion has nothing to
  /// exclude (criterion #6).
  bool get isDateLockedByBudget => hasBudgets && isBudgetActive;

  UnifiedFiltersState copyWith({
    UnifiedFiltersStatus? status,
    List<BudgetPeriodOption>? budgetOptions,
    String? selectedBudgetId,
    bool clearSelectedBudget = false,
    DatePeriodFilter? datePeriod,
    Set<TransactionType>? types,
    List<CategoryNode>? expenseNodes,
    List<CategoryNode>? incomeNodes,
    Set<String>? categoryIds,
    List<Tag>? tags,
    Set<String>? tagIds,
    Failure? failure,
  }) =>
      UnifiedFiltersState(
        status: status ?? this.status,
        budgetOptions: budgetOptions ?? this.budgetOptions,
        selectedBudgetId: clearSelectedBudget
            ? null
            : (selectedBudgetId ?? this.selectedBudgetId),
        datePeriod: datePeriod ?? this.datePeriod,
        types: types ?? this.types,
        expenseNodes: expenseNodes ?? this.expenseNodes,
        incomeNodes: incomeNodes ?? this.incomeNodes,
        categoryIds: categoryIds ?? this.categoryIds,
        tags: tags ?? this.tags,
        tagIds: tagIds ?? this.tagIds,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        budgetOptions,
        selectedBudgetId,
        datePeriod,
        types,
        expenseNodes,
        incomeNodes,
        categoryIds,
        tags,
        tagIds,
        failure,
      ];
}

/// What "Aplicar" resolves the sheet with: the delta the caller merges into
/// `TransactionFilter` via `copyWith`. Cuenta is not part of this — it never
/// left the filter bar's own chips (`AccountFilterChipRow`).
class UnifiedFiltersResult extends Equatable {
  const UnifiedFiltersResult({
    required this.datePeriod,
    required this.types,
    required this.categoryIds,
    required this.tagIds,
    this.budgetPeriod,
  });

  final DatePeriodFilter datePeriod;

  /// The chosen budget's current period window, or `null` when cleared —
  /// same shape as `TransactionFilter.budgetPeriod`.
  final DatePeriodFilter? budgetPeriod;
  final Set<TransactionType> types;
  final Set<String> categoryIds;
  final Set<String> tagIds;

  @override
  List<Object?> get props =>
      [datePeriod, budgetPeriod, types, categoryIds, tagIds];
}

/// Drives the unified filters sheet (issue #7): Presupuesto, Fecha, Tipo,
/// Categoría and Etiqueta all edited as one working copy, only reaching
/// `TransactionsListCubit` on "Aplicar" — plus the two rules the sheet's spec
/// (`design-system/billetudo/pages/transacciones.md` § "Bottom sheet
/// unificado de filtros") requires this exact cubit to own:
///
///  - **Exclusión mutua bidireccional Presupuesto ↔ Fecha**: selecting one
///    clears the other's active filter immediately (not just disables it),
///    in the very same method call that applies the new selection — see
///    [selectBudget]/[granularitySelected]/[step]/[applyCustomDateRange].
///  - **Ocultación condicional de Presupuesto**: [UnifiedFiltersState.hasBudgets]
///    tells the widget tree whether to render that section at all.
@injectable
class UnifiedFiltersCubit extends Cubit<UnifiedFiltersState> {
  UnifiedFiltersCubit(this._watchCategories, this._watchTags)
      : super(UnifiedFiltersState());

  final WatchCategories _watchCategories;
  final WatchTags _watchTags;

  StreamSubscription<Result<List<CategoryNode>>>? _expenseSubscription;
  StreamSubscription<Result<List<CategoryNode>>>? _incomeSubscription;
  StreamSubscription<Result<List<Tag>>>? _tagsSubscription;

  /// Opens the sheet seeded with [filter]'s currently applied values
  /// (criterion #11: an untouched dimension is never reset) and
  /// [budgetOptions] — already loaded by `TransactionsListState`, so this
  /// cubit does not need its own budgets subscription, unlike
  /// categories/tags which it does watch live.
  Future<void> start({
    required TransactionFilter filter,
    required List<BudgetPeriodOption> budgetOptions,
  }) async {
    await _cancelSubscriptions();
    emit(
      UnifiedFiltersState(
        budgetOptions: budgetOptions,
        selectedBudgetId: filter.budgetPeriod?.budgetId,
        datePeriod: filter.datePeriod,
        types: filter.types,
        categoryIds: filter.categoryIds,
        tagIds: filter.tagIds,
      ),
    );
    _expenseSubscription =
        _watchCategories(CategoryKind.expense).listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: UnifiedFiltersStatus.failure,
            failure: failure,
          ),
          (nodes) => state.copyWith(
            status: UnifiedFiltersStatus.ready,
            expenseNodes: nodes,
          ),
        ),
      );
    });
    _incomeSubscription =
        _watchCategories(CategoryKind.income).listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: UnifiedFiltersStatus.failure,
            failure: failure,
          ),
          (nodes) => state.copyWith(
            status: UnifiedFiltersStatus.ready,
            incomeNodes: nodes,
          ),
        ),
      );
    });
    _tagsSubscription = _watchTags().listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: UnifiedFiltersStatus.failure,
            failure: failure,
          ),
          (tags) =>
              state.copyWith(status: UnifiedFiltersStatus.ready, tags: tags),
        ),
      );
    });
  }

  /// Criterion #7: selecting a Presupuesto clears any active Fecha filter in
  /// the very same event — not a visual-only disable.
  void selectBudget(String budgetId) => emit(
        state.copyWith(
          selectedBudgetId: budgetId,
          datePeriod: DatePeriodFilter.thisMonth(),
        ),
      );

  /// The Presupuesto section's own "Ninguno" pill.
  void clearBudget() => emit(state.copyWith(clearSelectedBudget: true));

  /// Criterion #8: picking a new granularity clears any active Presupuesto
  /// filter in the very same event.
  void granularitySelected(DateGranularity granularity) => emit(
        state.copyWith(
          datePeriod: state.datePeriod.withGranularity(granularity),
          clearSelectedBudget: true,
        ),
      );

  /// Criterion #8: stepping the period clears any active Presupuesto filter.
  void step(int direction) => emit(
        state.copyWith(
          datePeriod: state.datePeriod.stepped(direction),
          clearSelectedBudget: true,
        ),
      );

  /// Criterion #8: choosing a custom range clears any active Presupuesto
  /// filter.
  void applyCustomDateRange({
    required DateTime start,
    required DateTime end,
  }) =>
      emit(
        state.copyWith(
          datePeriod: DatePeriodFilter.custom(start: start, end: end),
          clearSelectedBudget: true,
        ),
      );

  /// The Fecha section's own "Limpiar" — resets to "Este mes" without
  /// touching Presupuesto (it was not selected, or this call could not have
  /// been reached in the first place while it was, since Fecha is locked).
  void clearDateToThisMonth() =>
      emit(state.copyWith(datePeriod: DatePeriodFilter.clearedToThisMonth()));

  void toggleType(TransactionType type) {
    final next = Set<TransactionType>.of(state.types);
    if (!next.remove(type)) {
      next.add(type);
    }
    emit(state.copyWith(types: next));
  }

  /// HU-06's symmetric toggle: a root category selects/deselects itself and
  /// its whole subcategory tree in one block.
  void toggleRootCategory(CategoryNode node) {
    final subIds = node.subcategories.map((category) => category.id);
    final wasSelected = state.categoryIds.contains(node.root.id);
    final next = Set<String>.of(state.categoryIds);
    if (wasSelected) {
      next
        ..remove(node.root.id)
        ..removeAll(subIds);
    } else {
      next
        ..add(node.root.id)
        ..addAll(subIds);
    }
    emit(state.copyWith(categoryIds: next));
  }

  void toggleTag(String tagId) {
    final next = Set<String>.of(state.tagIds);
    if (!next.remove(tagId)) {
      next.add(tagId);
    }
    emit(state.copyWith(tagIds: next));
  }

  /// Header's "Limpiar todo"/footer's "Limpiar": every working dimension
  /// back to its untouched default in one tap, keeping the loaded lists
  /// (budgets/categories/tags) so the sheet does not flash back to loading.
  void clearAll() => emit(
        UnifiedFiltersState(
          status: state.status,
          budgetOptions: state.budgetOptions,
          expenseNodes: state.expenseNodes,
          incomeNodes: state.incomeNodes,
          tags: state.tags,
        ),
      );

  /// Builds the delta "Aplicar" hands back to the caller.
  UnifiedFiltersResult buildResult() {
    final budgetId = state.selectedBudgetId;
    DatePeriodFilter? budgetPeriod;
    if (budgetId != null) {
      for (final option in state.budgetOptions) {
        if (option.budgetId == budgetId) {
          budgetPeriod = DatePeriodFilter.budget(
            budgetId: option.budgetId,
            start: option.start,
            endExclusive: option.endExclusive,
          );
          break;
        }
      }
    }
    return UnifiedFiltersResult(
      datePeriod: state.datePeriod,
      budgetPeriod: budgetPeriod,
      types: state.types,
      categoryIds: state.categoryIds,
      tagIds: state.tagIds,
    );
  }

  Future<void> _cancelSubscriptions() async {
    await _expenseSubscription?.cancel();
    await _incomeSubscription?.cancel();
    await _tagsSubscription?.cancel();
    _expenseSubscription = null;
    _incomeSubscription = null;
    _tagsSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
