import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/preferences/balance_carousel_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_fab.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../../../core/widgets/root_tab_header.dart';
import '../../../../core/widgets/scroll_aware_fab.dart';
import '../../../../core/widgets/scroll_aware_fab_visibility.dart';
import '../../../accounts/presentation/utils/show_account_gate_if_needed.dart';
import '../../../accounts/presentation/widgets/account_gate_copy.dart';
import '../../domain/entities/transaction_filter.dart';
import '../cubit/transactions_list_cubit.dart';
import '../cubit/transactions_list_state.dart';
import '../utils/transaction_amount_presentation.dart';
import '../utils/transaction_date_grouping.dart';
import '../utils/transaction_group_total.dart';
import '../utils/transaction_sort_label.dart';
import '../widgets/account_filter_chip_row.dart';
import '../widgets/filters_button.dart';
import '../widgets/movements_balance_carousel.dart';
import '../widgets/sheets/unified_filters_sheet.dart';
import '../widgets/skeleton_row.dart';
import '../widgets/transaction_group_header.dart';
import '../widgets/transaction_row.dart';
import '../widgets/transactions_empty_state.dart';
import '../widgets/transactions_error_view.dart';
import '../widgets/transactions_link_mode.dart';
import '../widgets/transactions_sort_button.dart';

/// The transaction list (HU-06/`B3GGa`/`xAk6Y`): search, every combinable
/// filter, and the delete/"Deshacer" flow (HU-05). A root destination of the
/// Tab Bar, so its header carries no back button and no trailing action.
/// GitHub issue #26: `StatefulWidget` only to own the scroll-aware FAB state
/// ([ScrollAwareFabVisibility]) that [TransactionsListView] below feeds via
/// its own [ScrollController] — same pattern already used by `HomePage`.
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    required this.onAddTransaction,
    required this.onOpenTransaction,
    required this.onOpenAccount,
    this.linkMode,
    this.onBackToReports,
    super.key,
  });

  /// When set, the page is in Deudas link mode (`g0x859`): a banner naming the
  /// debt, no FAB, no balance carousel, and every row tap attributes that
  /// movement to the debt instead of opening its detail. Null is the ordinary
  /// list.
  final TransactionsLinkMode? linkMode;

  /// Navigates back to Gráficas e informes. Wired unconditionally by the
  /// router, but only rendered as the header's leading button while
  /// [TransactionsListState.arrivedFromReports] is true — i.e. right after
  /// Gráficas' categories drill-down (a `context.go` to this branch's root,
  /// which drops `/graficas` off the stack, so `Navigator.pop` has nothing to
  /// return to). Visibility is state-driven, not builder-driven: a
  /// `StatefulShellBranch` does not re-run its `GoRoute` builder on a later
  /// `context.go` to an already-visited branch (see `app_router.dart`'s
  /// `_movimientosBranch`), so a plain constructor-time null/non-null check
  /// would go stale after the first visit. If both this and [linkMode] were
  /// ever set, [linkMode]'s back button wins — its "cancel the link"
  /// semantics are the more urgent action to expose — though in practice the
  /// two never happen at once.
  final VoidCallback? onBackToReports;

  /// Opens the new-movement form. Receives the account to preselect, or null
  /// for none: the account of the balance carousel's active card (Mejora #2)
  /// is preselected as a convenience — the form still lets the user change it.
  final void Function(String? accountId) onAddTransaction;

  /// Navigates to the detail page and resolves with whatever it popped with
  /// (the deleted transaction's id, or `null`).
  final Future<String?> Function(String id) onOpenTransaction;

  /// Opens an account's detail page: fired when a balance carousel card is
  /// tapped (Mejora #2).
  final void Function(String accountId) onOpenAccount;

  /// The account to preselect in the new-movement form: the account of the
  /// balance carousel's active card (Mejora #2), which covers all three filter
  /// states — one account, several, or "Todas" — since the carousel always
  /// shows a card per displayed account. Read at tap time from the carousel
  /// cubit's remembered page, clamped in case the filter shrank the set, and
  /// null only when no account is shown.
  /// HU-02/HU-03 of `15-gate-cuenta.md`: without any active account the FAB
  /// opens the bridge sheet instead of a form that could not save anyway.

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with ScrollAwareFabVisibility<TransactionsPage> {
  Future<void> _addTransaction(BuildContext context) async {
    final canProceed = await showAccountGateIfNeeded(
      context,
      AccountGateSurface.movement,
    );
    if (canProceed && context.mounted) {
      widget.onAddTransaction(_preselectedAccountId(context));
    }
  }

  static String? _preselectedAccountId(BuildContext context) {
    final displayed =
        context.read<TransactionsListCubit>().state.displayedAccounts;
    if (displayed.isEmpty) {
      return null;
    }
    final page = context.read<BalanceCarouselCubit>().state.currentPage;
    final index = page.clamp(0, displayed.length - 1);
    return displayed[index].account.id;
  }

  /// Awaits the detail page's navigation, then — if it deleted something —
  /// offers HU-05's "Deshacer" snackbar via [TransactionsListCubit]. This
  /// reads the cubit from [context], a real descendant of this page's own
  /// `BlocProvider.value`; the router's `BuildContext` that builds this page
  /// is an ancestor of that provider, so reading from there throws
  /// `ProviderNotFoundError` instead of silently doing nothing.
  Future<void> _openTransaction(BuildContext context, String id) async {
    final deletedId = await widget.onOpenTransaction(id);
    if (deletedId != null && context.mounted) {
      context.read<TransactionsListCubit>().notifyExternalDelete(deletedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final linkMode = widget.linkMode;
    final onBackToReports = widget.onBackToReports;
    // Same source of truth as the leading button below: when the user
    // arrived here from Gráficas' drill-down, the system back
    // gesture/button must also return there instead of falling through to
    // the Navigator's default pop (which, since this branch was reached via
    // `context.go`, would land on Inicio — bugfix falla 3). `linkMode` is
    // never active at the same time as `arrivedFromReports` in practice
    // (they come from different entry points), but the `onBackToReports !=
    // null` guard keeps this inert if that ever changes.
    final arrivedFromReports =
        context.watch<TransactionsListCubit>().state.arrivedFromReports;
    final interceptSystemBack = arrivedFromReports && onBackToReports != null;
    return PopScope(
      canPop: !interceptSystemBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && interceptSystemBack) {
          onBackToReports();
        }
      },
      child: Scaffold(
        // Link mode hides the FAB entirely: the task there is to pick an
        // existing movement, not to create one (`g0x859`). Otherwise it is
        // scroll-aware (GH-26), same pattern as `HomePage`'s own FAB.
        floatingActionButton: linkMode != null
            ? null
            : ScrollAwareFab(
                visible: fabVisible,
                child: AppFab(
                  icon: LucideIcons.plus,
                  tooltip: l10n.transactionsAdd,
                  onPressed: () => unawaited(_addTransaction(context)),
                ),
              ),
        body: SafeArea(
          child: BlocConsumer<TransactionsListCubit, TransactionsListState>(
            listenWhen: (previous, current) =>
                previous.pendingUndoId != current.pendingUndoId &&
                current.pendingUndoId != null,
            listener: (context, state) {
              final cubit = context.read<TransactionsListCubit>();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l10n.transactionsUndoDeletedMessage),
                    action: SnackBarAction(
                      label: l10n.transactionsUndoAction,
                      onPressed: cubit.undoDelete,
                    ),
                    persist: false,
                  ),
                );
            },
            builder: (context, rawState) {
              // Search and filters stay pinned; everything below — including the
              // balance carousel (Mejora #2) — lives inside the scrollable body
              // so it scrolls away with the list.
              // In link mode a row tap attributes the movement to the debt; the
              // carousel is dropped so the focus is the list to pick from.
              // Link mode also restricts the list to the movements that may be
              // an abono of this debt: only the required type and dated on/after
              // the debt's creation (Deudas HU-02). Linking a movement of the
              // wrong type or an older date would push the balance the wrong way,
              // so those are dropped from the list entirely rather than shown and
              // rejected on tap.
              final state = linkMode == null
                  ? rawState
                  : rawState.copyWith(
                      items: rawState.items
                          .where((item) => linkMode.accepts(item.transaction))
                          .toList(),
                    );
              final onRowTap = linkMode != null
                  ? linkMode.onLinkTransaction
                  : (String id) => _openTransaction(context, id);
              final showCarousel = linkMode == null;
              return Column(
                children: [
                  RootTabHeader(
                    title: l10n.transactionsTitle,
                    // Link mode is a stacked screen with no other visible exit
                    // (the banner no longer carries an "x"), so it gets a back
                    // button here to never trap the user.
                    leading: linkMode != null
                        ? PageHeaderCircleButton(
                            icon: LucideIcons.arrowLeft,
                            background: context.colors.muted,
                            foreground: context.colors.textPrimary,
                            tooltip: l10n.commonBack,
                            onPressed: linkMode.onCancel,
                          )
                        : state.arrivedFromReports && onBackToReports != null
                            ? PageHeaderCircleButton(
                                icon: LucideIcons.arrowLeft,
                                background: context.colors.muted,
                                foreground: context.colors.textPrimary,
                                tooltip: l10n.commonBack,
                                onPressed: onBackToReports,
                              )
                            : null,
                  ),
                  TransactionsSearchRow(state: state),
                  const SizedBox(height: 8),
                  TransactionsFilterBar(state: state),
                  const SizedBox(height: 8),
                  if (linkMode != null)
                    TransactionsLinkBanner(linkMode: linkMode),
                  Expanded(
                    child: switch (state.status) {
                      TransactionsListStatus.loading =>
                        const TransactionsLoadingView(),
                      TransactionsListStatus.failure => TransactionsErrorView(
                          onRetry: context.read<TransactionsListCubit>().start,
                        ),
                      // Empty period: the carousel is pinned above the message
                      // (there is nothing to scroll here) so the balances stay
                      // visible when there are accounts but no movements yet.
                      TransactionsListStatus.ready when state.items.isEmpty =>
                        Column(
                          children: [
                            if (showCarousel)
                              MovementsBalanceCarousel(
                                state: state,
                                onOpenAccount: widget.onOpenAccount,
                              ),
                            Expanded(
                              child: TransactionsEmptyState(
                                message: _isUnfiltered(state.filter)
                                    ? l10n.transactionsEmptyMessage
                                    : l10n.transactionsEmptyPeriodMessage,
                              ),
                            ),
                          ],
                        ),
                      TransactionsListStatus.ready => TransactionsListView(
                          state: state,
                          onOpenTransaction: onRowTap,
                          onOpenAccount: widget.onOpenAccount,
                          showCarousel: showCarousel,
                          scrollController: fabScrollController,
                        ),
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Whether HU-06's search/filters are all at their untouched default (the
/// current month with no other filter): only then does an empty list read as
/// "no movements yet" instead of "nothing in this period".
bool _isUnfiltered(TransactionFilter filter) =>
    filter.searchText.isEmpty &&
    !filter.hasAccountFilter &&
    !filter.hasCategoryFilter &&
    !filter.hasTypeFilter &&
    !filter.hasTagFilter &&
    !filter.hasBudgetPeriodFilter &&
    !filter.hasDateFilter;

/// The search field + sort button row (`B3GGa`/`xAk6Y`).
///
/// Bugfix item 3: a trailing "x" clears the field once it has text, inside
/// the input — same clear affordance other text fields in the app already
/// use. `StatefulWidget` only to own the `TextEditingController` that drives
/// it; the search text itself still lives in [TransactionsListCubit].
class TransactionsSearchRow extends StatefulWidget {
  const TransactionsSearchRow({required this.state, super.key});

  final TransactionsListState state;

  @override
  State<TransactionsSearchRow> createState() => _TransactionsSearchRowState();
}

class _TransactionsSearchRowState extends State<TransactionsSearchRow> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.state.filter.searchText);

  @override
  void didUpdateWidget(covariant TransactionsSearchRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keeps the field in sync with a search text cleared/changed from
    // outside this row (e.g. `start()` resetting the filter) without
    // clobbering the user's own typing/cursor position on every rebuild.
    final filterText = widget.state.filter.searchText;
    if (filterText != _controller.text) {
      _controller.text = filterText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<TransactionsListCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                return TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                            tooltip: l10n.commonClear,
                            onPressed: () {
                              _controller.clear();
                              unawaited(cubit.searchChanged(''));
                            },
                          ),
                    hintText: l10n.transactionsSearchHint,
                    hintStyle:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                  ),
                  onChanged: cubit.searchChanged,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          TransactionsSortButton(
            sortOrder: widget.state.filter.sortOrder,
            onSelect: (sortOrder) => cubit.updateFilter(
              widget.state.filter.copyWith(sortOrder: sortOrder),
            ),
          ),
        ],
      ),
    );
  }
}

/// GitHub issue #7's redesign: the account filter is now its own row of
/// chips (`AccountFilterChipRow`) — no longer part of this bar — plus the
/// "Filtros" button that opens the single unified sheet for
/// Presupuesto/Fecha/Tipo/Categoría/Etiqueta (`UnifiedFiltersSheet`).
class TransactionsFilterBar extends StatelessWidget {
  const TransactionsFilterBar({required this.state, super.key});

  final TransactionsListState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsListCubit>();
    final filter = state.filter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          AccountFilterChipRow(
            accounts: state.accounts,
            selected: filter.accountIds,
            onChanged: (accountIds) => unawaited(
              cubit.updateFilter(filter.copyWith(accountIds: accountIds)),
            ),
          ),
          const SizedBox(width: 8),
          FiltersButton(
            activeCount: filter.activeFilterCount,
            onTap: () async {
              final result = await UnifiedFiltersSheet.show(
                context,
                initialFilter: filter,
                budgetOptions: state.budgetOptions,
              );
              // Null means the sheet was dismissed without "Aplicar"/
              // "Limpiar" — keep the current filter.
              if (result != null) {
                await cubit.updateFilter(
                  filter.copyWith(
                    datePeriod: result.datePeriod,
                    budgetPeriod: result.budgetPeriod,
                    clearBudgetPeriod: result.budgetPeriod == null,
                    types: result.types,
                    categoryIds: result.categoryIds,
                    tagIds: result.tagIds,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class TransactionsLoadingView extends StatelessWidget {
  const TransactionsLoadingView({super.key});

  static const List<double> _titleWidths = [130, 96, 150, 110];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).transactionsLoading,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _titleWidths.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            SkeletonRow(titleWidth: _titleWidths[index]),
      ),
    );
  }
}

class TransactionsListView extends StatelessWidget {
  const TransactionsListView({
    required this.state,
    required this.onOpenTransaction,
    required this.onOpenAccount,
    this.showCarousel = true,
    this.scrollController,
    super.key,
  });

  final TransactionsListState state;
  final ValueChanged<String> onOpenTransaction;

  /// Forwarded to the balance carousel header: tapping a card opens that
  /// account's detail page (Mejora #2).
  final ValueChanged<String> onOpenAccount;

  /// The balance carousel is the list's first scrollable item, but link mode
  /// drops it to keep the focus on picking a movement (`g0x859`).
  final bool showCarousel;

  /// GH-26: drives [TransactionsPage]'s scroll-aware FAB — attached to
  /// whichever of the two lists below actually renders, so scrolling either
  /// one hides/shows the FAB the same way `HomePage`'s own list does.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sortOrder = state.filter.sortOrder;

    // The carousel (Mejora #2) is the first scrollable item in both modes, so
    // it scrolls away with the list while the search/chips stay pinned. It
    // spans the full width (its own cards manage the 20px inset and the peek),
    // so the list's horizontal padding drops to 0 and each row/header carries
    // its own 20px instead.
    // HU-06 (`tigaH`/`Q8gSaB`): sorting by amount drops chronological order,
    // so the `Date Head` grouping stops making sense — the list flattens
    // into one plain run of `Transaction Row`, with a `Sort Label` above it
    // for context since the date headers are gone.
    if (transactionSortIsByAmount(sortOrder)) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          if (showCarousel)
            MovementsBalanceCarousel(
              state: state,
              onOpenAccount: onOpenAccount,
            ),
          TransactionsPeriodTotalRow(state: state),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                transactionSortActiveLabel(l10n, sortOrder)!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
          for (var i = 0; i < state.items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TransactionRow(
                entry: state.items[i],
                onTap: () => onOpenTransaction(state.items[i].transaction.id),
              ),
            ),
            if (i != state.items.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    final groups = groupTransactionsByDate(state.items);
    // The carousel occupies index 0 when shown; link mode drops it, so the
    // group indices shift back by one.
    final carouselSlots = showCarousel ? 1 : 0;
    // Bugfix (issue #7 item 5): one more slot for the period's aggregate
    // total, right after the carousel — `null` (mixed types/currencies, or
    // no exclusive income/expense filter active) means no slot at all, same
    // rule as each day's own total (`transactionGroupTotalFor`).
    final periodTotal = transactionPeriodTotalFor(state.filter, state.items);
    final totalSlots = periodTotal == null ? 0 : 1;
    final leadingSlots = carouselSlots + totalSlots;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 28),
      itemCount: groups.length + leadingSlots,
      itemBuilder: (context, index) {
        if (showCarousel && index == 0) {
          return MovementsBalanceCarousel(
            state: state,
            onOpenAccount: onOpenAccount,
          );
        }
        if (totalSlots == 1 && index == carouselSlots) {
          return TransactionsPeriodTotalRow(state: state);
        }
        final groupIndex = index - leadingSlots;
        final group = groups[groupIndex];
        final groupTotal = transactionGroupTotalFor(state.filter, group.items);
        return Padding(
          padding: EdgeInsets.fromLTRB(20, groupIndex == 0 ? 0 : 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TransactionGroupHeader(
                label: transactionGroupLabel(l10n, group.date),
                count: groupTotal == null ? group.items.length : null,
                totalLabel: groupTotal == null
                    ? null
                    : signedAmountLabel(
                        amountMinor: groupTotal.amountMinor,
                        currencyCode: groupTotal.currency,
                        type: groupTotal.type,
                      ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < group.items.length; i++) ...[
                TransactionRow(
                  entry: group.items[i],
                  onTap: () => onOpenTransaction(group.items[i].transaction.id),
                ),
                if (i != group.items.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Bugfix (issue #7 item 5): the filtered period's aggregate total (e.g. "el
/// total ganado en todo el período" while "solo ingresos" is active) — reuses
/// `TransactionGroupHeader`'s own left-label/right-total row, the pattern
/// already used for a single day's total, instead of a new component.
/// Renders nothing when [transactionPeriodTotalFor] has nothing to show
/// (mixed types, transfers, or a mixed-currency period).
class TransactionsPeriodTotalRow extends StatelessWidget {
  const TransactionsPeriodTotalRow({required this.state, super.key});

  final TransactionsListState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = transactionPeriodTotalFor(state.filter, state.items);
    if (total == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TransactionGroupHeader(
        label: l10n.transactionsPeriodTotalLabel,
        totalLabel: signedAmountLabel(
          amountMinor: total.amountMinor,
          currencyCode: total.currency,
          type: total.type,
        ),
      ),
    );
  }
}
