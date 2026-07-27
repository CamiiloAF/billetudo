import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/entities/category_node.dart';
import '../../../categories/domain/usecases/watch_categories.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_detail_data.dart';
import '../../domain/services/budget_category_scope_resolver.dart';
import '../../domain/usecases/create_budget.dart';
import '../../domain/usecases/get_budget_by_id.dart';
import '../../domain/usecases/update_budget.dart';
import 'budget_form_state.dart';

/// Drives creating and editing a budget (HU-01/HU-03/HU-09).
///
/// It collects raw field values and hands a draft to a use case; it does not
/// re-implement a single validation rule — those live in
/// `BudgetDraft.validated`, shared with any other caller.
@injectable
class BudgetFormCubit extends Cubit<BudgetFormState> {
  BudgetFormCubit(
    this._createBudget,
    this._updateBudget,
    this._getBudgetById,
    this._watchCategories,
    this._scopeResolver,
  ) : super(BudgetFormState.loading());

  final CreateBudget _createBudget;
  final UpdateBudget _updateBudget;
  final GetBudgetById _getBudgetById;
  final WatchCategories _watchCategories;
  final BudgetCategoryScopeResolver _scopeResolver;

  // The live category tree, kept only to translate between the picker's
  // materialized selection and the canonical scope stored on the budget (fix
  // #14). Not in the form state: it never renders here — the picker loads its
  // own copy — it only feeds [categoryScopeForPicker] / [categoriesPicked].
  List<CategoryNode> _expenseNodes = const [];
  List<CategoryNode> _incomeNodes = const [];
  StreamSubscription<Result<List<CategoryNode>>>? _expenseSubscription;
  StreamSubscription<Result<List<CategoryNode>>>? _incomeSubscription;
  var _expenseSeen = false;
  var _incomeSeen = false;
  final _categoriesReady = Completer<void>();

  /// Loads the budget to edit, or prepares an empty form when [id] is null.
  Future<void> load(String? id) async {
    _watchCategoryTree();
    if (id == null) {
      emit(BudgetFormState.initial(DateTime.now()));
      return;
    }

    emit(BudgetFormState.loading());
    final result = await _getBudgetById(id).first;
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
            state.copyWith(status: BudgetFormStatus.failure, failure: failure));
      case Right(value: final data):
        emit(_formFor(data));
    }
  }

  void _watchCategoryTree() {
    _expenseSubscription ??=
        _watchCategories(CategoryKind.expense).listen((result) {
      if (result case Right(value: final nodes)) {
        _expenseNodes = nodes;
      }
      _expenseSeen = true;
      _maybeCompleteCategories();
    });
    _incomeSubscription ??=
        _watchCategories(CategoryKind.income).listen((result) {
      if (result case Right(value: final nodes)) {
        _incomeNodes = nodes;
      }
      _incomeSeen = true;
      _maybeCompleteCategories();
    });
  }

  void _maybeCompleteCategories() {
    if (_expenseSeen && _incomeSeen && !_categoriesReady.isCompleted) {
      _categoriesReady.complete();
    }
  }

  /// Every root id -> its direct children ids, across both trees. The single
  /// input both [BudgetCategoryScopeResolver] methods need.
  Map<String, List<String>> get _childrenByRoot => {
        for (final node in [..._expenseNodes, ..._incomeNodes])
          node.root.id: [for (final child in node.subcategories) child.id],
      };

  /// The **materialized** selection to seed the shared category picker with,
  /// so a root-only or global ("Todas") budget shows the right rows checked.
  /// Awaits the live tree (loaded once, fast and local) so the expansion is
  /// never computed against an empty tree.
  Future<Set<String>> categoryScopeForPicker() async {
    await _categoriesReady.future;
    return _scopeResolver.expand(state.categoryIds, _childrenByRoot);
  }

  /// Collapses what the picker returned back into the canonical scope before
  /// storing it: "Todas" -> `{}`, a whole root -> just its id. The tree is
  /// already loaded here (the picker was shown via [categoryScopeForPicker]).
  void categoriesPicked(Set<String> materialized) => categoriesSelected(
      _scopeResolver.collapse(materialized, _childrenByRoot));

  BudgetFormState _formFor(BudgetDetailData data) {
    final budget = data.budget;
    final oneOff = budget.isOneOff;
    return BudgetFormState(
      status: BudgetFormStatus.ready,
      id: budget.id,
      name: budget.name,
      icon: budget.icon,
      amountMinor: budget.amountMinor,
      currency: budget.currency,
      recurring: !oneOff,
      // A one-off is stored as `custom`; the periodicity picker only shows the
      // recurring options, so keep a sensible default there.
      period: oneOff ? BudgetPeriod.monthly : budget.period,
      startDate: budget.startDate,
      endDate: budget.endDate,
      alertThresholdPct: budget.alertThresholdPct,
      accountIds: data.scope.aliveAccountIds,
      categoryIds: data.scope.aliveCategoryIds,
    );
  }

  void nameChanged(String value) => emit(state.copyWith(name: value));

  void iconSelected(String? icon) => emit(
        icon == null
            ? state.copyWith(clearIcon: true)
            : state.copyWith(icon: icon),
      );

  void amountChanged(int? amountMinor) => emit(
        amountMinor == null
            ? state.copyWith(clearAmount: true)
            : state.copyWith(amountMinor: amountMinor),
      );

  /// Switching currency keeps the figure and only re-cuts its precision: COP
  /// shows no cents, so a USD `1.234,56` becomes `1.235`
  /// ([MoneyFormatter.roundToCurrencyPrecision] explains why half-up and not
  /// truncation). The stored amount is rounded here, in the cubit, so the
  /// field can never display a figure the state does not hold. No FX
  /// conversion happens — the number itself is the user's, only its currency
  /// label changed.
  void currencyChanged(String currency) {
    if (currency == state.currency) {
      return;
    }
    final amountMinor = state.amountMinor;
    emit(
      state.copyWith(
        currency: currency,
        amountMinor: amountMinor == null
            ? null
            : MoneyFormatter.roundToCurrencyPrecision(amountMinor, currency),
      ),
    );
  }

  /// HU-03: switching between "Periódico" and "Una única vez". A one-off must
  /// carry an end date; a periodic budget keeps whatever end (or none) it had.
  void recurringChanged({required bool recurring}) => emit(
        state.copyWith(recurring: recurring),
      );

  void periodSelected(BudgetPeriod period) =>
      emit(state.copyWith(period: period));

  void startDateSelected(DateTime date) => emit(
        state.copyWith(startDate: DateTime(date.year, date.month, date.day)),
      );

  void endDateSelected(DateTime? date) => emit(
        date == null
            ? state.copyWith(clearEndDate: true)
            : state.copyWith(
                endDate: DateTime(date.year, date.month, date.day),
              ),
      );

  void thresholdSelected(int? pct) => emit(
        pct == null
            ? state.copyWith(clearThreshold: true)
            : state.copyWith(alertThresholdPct: pct),
      );

  void accountsSelected(Set<String> accountIds) =>
      emit(state.copyWith(accountIds: accountIds));

  void categoriesSelected(Set<String> categoryIds) =>
      emit(state.copyWith(categoryIds: categoryIds));

  /// Validates and persists. On success sets `savedId`; on a validation error
  /// surfaces the [Failure] so the form can point at the offending field.
  Future<void> submit() async {
    if (state.submitting) {
      return;
    }
    emit(state.copyWith(submitting: true));

    final draft = state.toDraft();
    final result = state.isEditing
        ? await _updateBudget(draft)
        : await _createBudget(draft);
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(submitting: false, failure: failure),
        (budget) => state.copyWith(submitting: false, savedId: budget.id),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _expenseSubscription?.cancel();
    await _incomeSubscription?.cancel();
    return super.close();
  }
}
