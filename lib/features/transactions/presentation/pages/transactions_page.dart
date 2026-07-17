import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/transaction_filter.dart';
import '../cubit/transactions_list_cubit.dart';
import '../cubit/transactions_list_state.dart';
import '../widgets/sheets/account_filter_sheet.dart';
import '../widgets/sheets/category_filter_sheet.dart';
import '../widgets/sheets/date_filter_sheet.dart';
import '../widgets/sheets/tag_filter_sheet.dart';
import '../widgets/sheets/type_filter_sheet.dart';
import '../widgets/skeleton_row.dart';
import '../widgets/transaction_row.dart';
import '../widgets/transactions_empty_state.dart';
import '../widgets/transactions_error_view.dart';

/// The transaction list (HU-06): search, every combinable filter, and the
/// delete/"Deshacer" flow (HU-05).
class TransactionsPage extends StatelessWidget {
  const TransactionsPage({
    required this.onAddTransaction,
    required this.onOpenTransaction,
    super.key,
  });

  final VoidCallback onAddTransaction;

  /// Navigates to the detail page and resolves with whatever it popped with
  /// (the deleted transaction's id, or `null`).
  final Future<String?> Function(String id) onOpenTransaction;

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
      floatingActionButton: FloatingActionButton(
        // ignore: avoid_hardcoded_ui_strings
        heroTag: 'transactionsAddTransactionFab',
        onPressed: onAddTransaction,
        tooltip: l10n.transactionsAdd,
        child: const Icon(LucideIcons.plus),
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
                ),
              );
          },
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(LucideIcons.search),
                      hintText: l10n.transactionsSearchHint,
                    ),
                    onChanged:
                        context.read<TransactionsListCubit>().searchChanged,
                  ),
                ),
                TransactionsFilterBar(state: state),
                Expanded(
                  child: switch (state.status) {
                    TransactionsListStatus.loading =>
                      const TransactionsLoadingView(),
                    TransactionsListStatus.failure => TransactionsErrorView(
                        onRetry: context.read<TransactionsListCubit>().start,
                      ),
                    TransactionsListStatus.ready when state.items.isEmpty =>
                      TransactionsEmptyState(
                        message: _isUnfiltered(state.filter)
                            ? l10n.transactionsEmptyMessage
                            : l10n.transactionsEmptyPeriodMessage,
                      ),
                    TransactionsListStatus.ready => TransactionsListView(
                        state: state,
                        onOpenTransaction: (id) =>
                            _openTransaction(context, id),
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

/// The row of filter chips: account, category, type, date and tag
/// (HU-06/HU-06a/HU-06b/HU-07).
/// Whether HU-06's search/filters are all at their untouched default (the
/// current month with no other filter): only then does an empty list read as
/// "no movements yet" instead of "nothing in this period".
bool _isUnfiltered(TransactionFilter filter) =>
    filter.searchText.isEmpty &&
    !filter.hasAccountFilter &&
    !filter.hasCategoryFilter &&
    !filter.hasTypeFilter &&
    !filter.hasTagFilter &&
    !filter.datePeriod.isCustomRange;

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
          ActionChip(
            label: Text(l10n.transactionsFilterAccounts),
            avatar: filter.hasAccountFilter
                ? const Icon(LucideIcons.check, size: 16)
                : null,
            onPressed: () async {
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
          ActionChip(
            label: Text(l10n.transactionsFilterCategories),
            avatar: filter.hasCategoryFilter
                ? const Icon(LucideIcons.check, size: 16)
                : null,
            onPressed: () async {
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
          ActionChip(
            label: Text(l10n.transactionsFilterType),
            avatar: filter.hasTypeFilter
                ? const Icon(LucideIcons.check, size: 16)
                : null,
            onPressed: () async {
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
          ActionChip(
            label: Text(l10n.transactionsFilterDate),
            onPressed: () async {
              final applied = await DateFilterSheet.show(
                context,
                initial: filter.datePeriod,
              );
              await cubit.updateFilter(filter.copyWith(datePeriod: applied));
            },
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: Text(l10n.transactionsFilterTag),
            avatar: filter.hasTagFilter
                ? const Icon(LucideIcons.check, size: 16)
                : null,
            onPressed: () async {
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
    super.key,
  });

  final TransactionsListState state;
  final ValueChanged<String> onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      itemCount: state.items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = state.items[index];
        return TransactionRow(
          entry: entry,
          onTap: () => onOpenTransaction(entry.transaction.id),
        );
      },
    );
  }
}
