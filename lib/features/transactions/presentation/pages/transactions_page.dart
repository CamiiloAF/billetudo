import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/preferences/balance_carousel_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_fab.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/presentation/widgets/account_type_avatar.dart';
import '../../domain/entities/date_period_filter.dart';
import '../../domain/entities/transaction_filter.dart';
import '../cubit/transactions_list_cubit.dart';
import '../cubit/transactions_list_state.dart';
import '../utils/date_period_label.dart';
import '../utils/transaction_date_grouping.dart';
import '../utils/transaction_sort_label.dart';
import '../widgets/filter_chip_pill.dart';
import '../widgets/movements_balance_carousel.dart';
import '../widgets/sheets/account_filter_sheet.dart';
import '../widgets/sheets/category_filter_sheet.dart';
import '../widgets/sheets/date_filter_sheet.dart';
import '../widgets/sheets/tag_filter_sheet.dart';
import '../widgets/sheets/type_filter_sheet.dart';
import '../widgets/skeleton_row.dart';
import '../widgets/transaction_group_header.dart';
import '../widgets/transaction_row.dart';
import '../widgets/transactions_empty_state.dart';
import '../widgets/transactions_error_view.dart';
import '../widgets/transactions_sort_button.dart';

/// The transaction list (HU-06/`B3GGa`/`xAk6Y`): search, every combinable
/// filter, and the delete/"Deshacer" flow (HU-05). A root destination of the
/// Tab Bar, so its header carries no back button and no trailing action.
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({
    required this.onAddTransaction,
    required this.onOpenTransaction,
    required this.onOpenAccount,
    super.key,
  });

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
    final deletedId = await onOpenTransaction(id);
    if (deletedId != null && context.mounted) {
      context.read<TransactionsListCubit>().notifyExternalDelete(deletedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionsTitle)),
      floatingActionButton: AppFab(
        icon: LucideIcons.plus,
        tooltip: l10n.transactionsAdd,
        onPressed: () => onAddTransaction(_preselectedAccountId(context)),
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
          builder: (context, state) {
            // Search and filters stay pinned; everything below — including the
            // balance carousel (Mejora #2) — lives inside the scrollable body
            // so it scrolls away with the list.
            return Column(
              children: [
                TransactionsSearchRow(state: state),
                const SizedBox(height: 8),
                TransactionsFilterBar(state: state),
                const SizedBox(height: 8),
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
                          MovementsBalanceCarousel(
                            state: state,
                            onOpenAccount: onOpenAccount,
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
                        onOpenTransaction: (id) =>
                            _openTransaction(context, id),
                        onOpenAccount: onOpenAccount,
                      ),
                  },
                ),
              ],
            );
          },
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
    !_hasDateFilter(filter.datePeriod);

/// HU-06b's date filter has no bare "no filter" state (it always defaults to
/// "this month"), so "active" here means "not the untouched default".
bool _hasDateFilter(DatePeriodFilter period) =>
    period != DatePeriodFilter.thisMonth();

/// The search field + sort button row (`B3GGa`/`xAk6Y`).
class TransactionsSearchRow extends StatelessWidget {
  const TransactionsSearchRow({required this.state, super.key});

  final TransactionsListState state;

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
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 20,
                  color: colors.textSecondary,
                ),
                hintText: l10n.transactionsSearchHint,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
              ),
              onChanged: cubit.searchChanged,
            ),
          ),
          const SizedBox(width: 8),
          TransactionsSortButton(
            sortOrder: state.filter.sortOrder,
            onSelect: (sortOrder) => cubit.updateFilter(
              state.filter.copyWith(sortOrder: sortOrder),
            ),
          ),
        ],
      ),
    );
  }
}

/// The row of filter chips: account, category, type, date and tag
/// (HU-06/HU-06a/HU-06b/HU-07). Every chip adopts the same active style
/// (`primary-soft`/`primary`) the instant its own dimension has a filter.
class TransactionsFilterBar extends StatelessWidget {
  const TransactionsFilterBar({required this.state, super.key});

  final TransactionsListState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TransactionsListCubit>();
    final filter = state.filter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          FilterChipPill(
            label: _accountChipLabel(l10n, filter, state.accounts),
            // The Account Chip has no neutral/unset look: HU-06a's 3 states
            // ("N cuentas" / one account / "Todas" as a stand-in for "no
            // filter") are all rendered in the same active pill (`s8uIq`).
            active: true,
            leadingIcon: _accountChipIcon(filter, state.accounts),
            trailingIcon: LucideIcons.chevronDown,
            onTap: () async {
              final selected = await AccountFilterSheet.show(
                context,
                initialSelected: filter.accountIds,
              );
              if (selected != null) {
                await cubit.updateFilter(filter.copyWith(accountIds: selected));
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChipPill(
            // HU-06b: there is always a real date filter active (defaults to
            // "Este mes"), so the Chip Fecha never renders as unset — always
            // its own `calendar` icon plus the current period's label.
            label: datePeriodLabel(filter.datePeriod),
            active: true,
            leadingIcon: LucideIcons.calendar,
            onTap: () async {
              final applied = await DateFilterSheet.show(
                context,
                initial: filter.datePeriod,
              );
              // Null means the sheet was dismissed without "Aplicar" — keep
              // the current filter.
              if (applied != null) {
                await cubit.updateFilter(
                  filter.copyWith(datePeriod: applied),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChipPill(
            label: l10n.transactionsFilterCategories,
            active: filter.hasCategoryFilter,
            onTap: () async {
              final selected = await CategoryFilterSheet.show(
                context,
                initialSelected: filter.categoryIds,
              );
              if (selected != null) {
                await cubit
                    .updateFilter(filter.copyWith(categoryIds: selected));
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChipPill(
            label: l10n.transactionsFilterType,
            active: filter.hasTypeFilter,
            onTap: () async {
              final selected = await TypeFilterSheet.show(
                context,
                initialSelected: filter.types,
              );
              if (selected != null) {
                await cubit.updateFilter(filter.copyWith(types: selected));
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChipPill(
            label: l10n.transactionsFilterTag,
            active: filter.hasTagFilter,
            onTap: () async {
              final selected = await TagFilterSheet.show(
                context,
                initialSelected: filter.tagIds,
              );
              if (selected != null) {
                await cubit.updateFilter(filter.copyWith(tagIds: selected));
              }
            },
          ),
        ],
      ),
    );
  }

  /// The Account Chip's label across HU-06a's 3 states: the account's own
  /// name when exactly one is selected, a count for 2+, and "Todas" (not
  /// "Cuentas") when there is no filter — `s8uIq` treats "no filter" as the
  /// same active "Todas" state, never as an unset 4th look.
  static String _accountChipLabel(
    AppLocalizations l10n,
    TransactionFilter filter,
    List<AccountWithBalance> accounts,
  ) {
    if (!filter.hasAccountFilter) {
      return l10n.accountFilterSelectAll;
    }
    final selected = _singleSelectedAccount(filter, accounts);
    if (selected != null) {
      return selected.name;
    }
    return l10n.transactionsFilterAccountsSelected(filter.accountIds.length);
  }

  /// The Account Chip's leading icon across its 3 states: the selected
  /// account's own type icon for exactly one, a generic `layers` for 2+, and
  /// a generic `wallet` for "Todas" (`s8uIq`/`XlXA8`).
  static IconData _accountChipIcon(
    TransactionFilter filter,
    List<AccountWithBalance> accounts,
  ) {
    if (!filter.hasAccountFilter) {
      return LucideIcons.wallet;
    }
    final selected = _singleSelectedAccount(filter, accounts);
    return selected?.type.icon ?? LucideIcons.layers;
  }

  static Account? _singleSelectedAccount(
    TransactionFilter filter,
    List<AccountWithBalance> accounts,
  ) {
    if (filter.accountIds.length != 1) {
      return null;
    }
    final id = filter.accountIds.first;
    for (final entry in accounts) {
      if (entry.account.id == id) {
        return entry.account;
      }
    }
    return null;
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
    super.key,
  });

  final TransactionsListState state;
  final ValueChanged<String> onOpenTransaction;

  /// Forwarded to the balance carousel header: tapping a card opens that
  /// account's detail page (Mejora #2).
  final ValueChanged<String> onOpenAccount;

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
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          MovementsBalanceCarousel(state: state, onOpenAccount: onOpenAccount),
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

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 28),
      // +1 for the carousel header at index 0.
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return MovementsBalanceCarousel(
            state: state,
            onOpenAccount: onOpenAccount,
          );
        }
        final group = groups[index - 1];
        return Padding(
          padding: EdgeInsets.fromLTRB(20, index == 1 ? 0 : 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TransactionGroupHeader(
                label: transactionGroupLabel(l10n, group.date),
                count: group.items.length,
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
