import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../domain/entities/account_with_balance.dart';
import '../cubit/accounts_list_cubit.dart';
import '../cubit/accounts_list_state.dart';
import '../widgets/account_card.dart';
import '../widgets/accounts_error_view.dart';
import '../widgets/accounts_total_card.dart';
import '../widgets/credit_card_account_row.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_row.dart';

/// The accounts list (`l055o`/`nwFMA`/`sh7r2`/`L6Za0`).
///
/// A flat list, not grouped by type: HU-09 (drag to reorder) maps 1:1 onto a
/// linear list and falls apart across groups. What grouping would have bought —
/// telling assets from liabilities — the Total Card's debt sub-line gives
/// without it.
class AccountsPage extends StatelessWidget {
  const AccountsPage({
    required this.onAddAccount,
    required this.onOpenAccount,
    required this.onOpenArchived,
    super.key,
  });

  final VoidCallback onAddAccount;
  final ValueChanged<String> onOpenAccount;
  final VoidCallback onOpenArchived;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: l10n.accountsTitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PageHeaderCircleButton(
                    icon: LucideIcons.archive,
                    background: colors.muted,
                    foreground: colors.textPrimary,
                    tooltip: l10n.accountsArchivedTitle,
                    onPressed: onOpenArchived,
                  ),
                  const SizedBox(width: 8),
                  PageHeaderCircleButton(
                    icon: LucideIcons.plus,
                    background: colors.primary,
                    foreground: colors.onPrimary,
                    tooltip: l10n.accountsAdd,
                    onPressed: onAddAccount,
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<AccountsListCubit, AccountsListState>(
                builder: (context, state) => switch (state.status) {
                  AccountsListStatus.loading => const AccountsLoadingView(),
                  AccountsListStatus.failure => AccountsErrorView(
                      onRetry: context.read<AccountsListCubit>().start,
                    ),
                  AccountsListStatus.ready when state.accounts.isEmpty =>
                    AccountsEmptyView(onAddAccount: onAddAccount),
                  AccountsListStatus.ready => AccountsListView(
                      state: state,
                      onOpenAccount: onOpenAccount,
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading: four `Skeleton Row`s with the same geometry as the real rows, so
/// nothing jumps when the data lands.
class AccountsLoadingView extends StatelessWidget {
  const AccountsLoadingView({super.key});

  /// Widths that vary per row, so the placeholder does not look stamped.
  static const List<double> _nameWidths = [130, 96, 150, 110];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).accountsLoading,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _nameWidths.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => SkeletonRow(
          nameWidth: _nameWidths[index],
          typeWidth: 60 + (index % 3) * 12,
        ),
      ),
    );
  }
}

class AccountsEmptyView extends StatelessWidget {
  const AccountsEmptyView({required this.onAddAccount, super.key});

  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: LucideIcons.landmark,
      message: l10n.accountsEmptyMessage,
      ctaLabel: l10n.accountsAdd,
      onCta: onAddAccount,
    );
  }
}

/// The list with data: Total Card on top, then the accounts, reorderable by
/// long-press (HU-09).
class AccountsListView extends StatelessWidget {
  const AccountsListView({
    required this.state,
    required this.onOpenAccount,
    super.key,
  });

  final AccountsListState state;
  final ValueChanged<String> onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          sliver: SliverToBoxAdapter(
            child: AccountsTotalCard(overview: state.overview),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverReorderableList(
            itemCount: state.accounts.length,
            onReorder: context.read<AccountsListCubit>().reorder,
            itemBuilder: (context, index) {
              final entry = state.accounts[index];
              return ReorderableDelayedDragStartListener(
                // Long-press to drag, straight on the row: no separate "edit"
                // mode. Archive/delete stay in each account's detail.
                key: ValueKey(entry.account.id),
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AccountRowItem(
                    entry: entry,
                    onTap: () => onOpenAccount(entry.account.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Picks the row a given account deserves: a card needs its credit figures, any
/// other account does not.
class AccountRowItem extends StatelessWidget {
  const AccountRowItem({required this.entry, required this.onTap, super.key});

  final AccountWithBalance entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => entry.account.isCard
      ? CreditCardAccountRow(entry: entry, onTap: onTap)
      : AccountCard(entry: entry, onTap: onTap);
}
