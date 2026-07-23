import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../cubit/debts_list_cubit.dart';
import '../cubit/debts_list_state.dart';
import '../widgets/debt_card.dart';
import '../widgets/debt_card_skeleton.dart';
import '../widgets/debt_skeleton_box.dart';
import '../widgets/debt_summary_card.dart';
import '../widgets/debt_summary_card_skeleton.dart';

/// The debts list (`rPgbX`/`qfpUI`/`hp9rU`/`d64hv`): a per-currency summary
/// card on top, then a flat list of `DebtCard`s. A stacked subsection with a
/// `Page Header` and no `Tab Bar`.
class DebtsListPage extends StatelessWidget {
  const DebtsListPage({
    required this.onAddDebt,
    required this.onOpenDebt,
    super.key,
  });

  final VoidCallback onAddDebt;
  final ValueChanged<String> onOpenDebt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: l10n.debtsTitle,
              trailing: PageHeaderCircleButton(
                icon: LucideIcons.plus,
                background: colors.primary,
                foreground: colors.onPrimary,
                tooltip: l10n.debtsAdd,
                onPressed: onAddDebt,
              ),
            ),
            Expanded(
              child: BlocBuilder<DebtsListCubit, DebtsListState>(
                builder: (context, state) => switch (state.status) {
                  DebtsListStatus.loading => const DebtsLoadingView(),
                  DebtsListStatus.failure => DebtsErrorView(
                      onRetry: context.read<DebtsListCubit>().start,
                    ),
                  DebtsListStatus.ready when state.summary.debts.isEmpty =>
                    DebtsEmptyView(onAddDebt: onAddDebt),
                  DebtsListStatus.ready => DebtsListView(
                      state: state,
                      onOpenDebt: onOpenDebt,
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

/// Loading: summary skeleton + four `Debt Card Skeleton`s with varied widths,
/// so the placeholder does not look stamped.
class DebtsLoadingView extends StatelessWidget {
  const DebtsLoadingView({super.key});

  static const List<List<double>> _widths = [
    [130, 90],
    [150, 100],
    [110, 80],
    [140, 85],
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).debtsLoading,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          const DebtSummaryCardSkeleton(),
          const SizedBox(height: 16),
          const DebtSkeletonBox(width: 90, height: 14),
          const SizedBox(height: 12),
          for (var index = 0; index < _widths.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            DebtCardSkeleton(
              nameWidth: _widths[index][0],
              counterpartyWidth: _widths[index][1],
            ),
          ],
        ],
      ),
    );
  }
}

class DebtsEmptyView extends StatelessWidget {
  const DebtsEmptyView({required this.onAddDebt, super.key});

  final VoidCallback onAddDebt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: LucideIcons.handCoins,
      message: l10n.debtsEmptyMessage,
      description: l10n.debtsEmptyDescription,
      ctaLabel: l10n.debtsAdd,
      onCta: onAddDebt,
    );
  }
}

class DebtsErrorView extends StatelessWidget {
  const DebtsErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: AppLocalizations.of(context).debtsErrorTitle,
      onRetry: onRetry,
    );
  }
}

/// The list with data: one summary card per currency, then the debts.
class DebtsListView extends StatelessWidget {
  const DebtsListView({
    required this.state,
    required this.onOpenDebt,
    super.key,
  });

  final DebtsListState state;
  final ValueChanged<String> onOpenDebt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final totals = state.summary.totals;
    final debts = state.summary.debts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        for (var index = 0; index < totals.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          DebtSummaryCard(total: totals[index]),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.debtsSectionTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < debts.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          DebtCard(
            entry: debts[index],
            onTap: () => onOpenDebt(debts[index].debt.id),
          ),
        ],
      ],
    );
  }
}
