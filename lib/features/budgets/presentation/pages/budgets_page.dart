import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../accounts/presentation/widgets/empty_state.dart';
import '../../../settings/presentation/cubit/app_settings_cubit.dart';
import '../../domain/entities/zero_based_summary.dart';
import '../cubit/budgets_list_cubit.dart';
import '../cubit/budgets_list_state.dart';
import '../cubit/zero_based_summary_cubit.dart';
import '../widgets/budget_line.dart';
import '../widgets/budget_skeleton_row.dart';
import '../widgets/budgets_error_view.dart';
import '../widgets/envelope_hero.dart';

/// The budgets list (`s833Gk`). Custom header ("Presupuestos" + `+`) over the
/// app tab bar; no `Page Header`. The overflow menu reaches the history.
class BudgetsPage extends StatelessWidget {
  const BudgetsPage({
    required this.onAddBudget,
    required this.onOpenBudget,
    required this.onOpenHistory,
    super.key,
  });

  final VoidCallback onAddBudget;
  final ValueChanged<String> onOpenBudget;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final envelopeEnabled =
        context.watch<AppSettingsCubit>().state.zeroBasedEnabled;
    final ZeroBasedSummary? summary = envelopeEnabled
        ? context.watch<ZeroBasedSummaryCubit>().state.summary
        : null;
    final Widget? envelopeHeader =
        summary == null ? null : EnvelopeHero(summary: summary);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.budgetsTitle),
        actions: [
          IconButton(
            onPressed: onAddBudget,
            tooltip: l10n.budgetsAdd,
            icon: const Icon(LucideIcons.plus),
          ),
          PopupMenuButton<void>(
            icon: const Icon(LucideIcons.ellipsisVertical),
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                onTap: onOpenHistory,
                child: Text(l10n.budgetsMenuHistory),
              ),
              if (envelopeEnabled)
                PopupMenuItem<void>(
                  onTap: () => unawaited(
                    context.read<AppSettingsCubit>().setZeroBasedEnabled(false),
                  ),
                  child: Text(l10n.budgetsMenuDisableEnvelope),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<BudgetsListCubit, BudgetsListState>(
          builder: (context, state) => switch (state.status) {
            BudgetsListStatus.loading => const BudgetsLoadingView(),
            BudgetsListStatus.failure => BudgetsErrorView(
                onRetry: context.read<BudgetsListCubit>().start,
              ),
            BudgetsListStatus.ready when state.budgets.isEmpty =>
              BudgetsEmptyView(
                onAddBudget: onAddBudget,
                header: envelopeHeader,
              ),
            BudgetsListStatus.ready => BudgetsListView(
                state: state,
                onOpenBudget: onOpenBudget,
                onAddBudget: onAddBudget,
                header: envelopeHeader,
              ),
          },
        ),
      ),
    );
  }
}

/// Loading: four skeleton rows matching the real row geometry.
class BudgetsLoadingView extends StatelessWidget {
  const BudgetsLoadingView({super.key});

  static const List<double> _nameWidths = [140, 100, 160, 120];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).budgetsLoading,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _nameWidths.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) =>
            BudgetSkeletonRow(nameWidth: _nameWidths[index]),
      ),
    );
  }
}

class BudgetsEmptyView extends StatelessWidget {
  const BudgetsEmptyView({required this.onAddBudget, this.header, super.key});

  final VoidCallback onAddBudget;

  /// The "Modo sobres" hero, when active (HU-06).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = EmptyState(
      icon: LucideIcons.wallet,
      message: l10n.budgetsEmptyMessage,
      ctaLabel: l10n.budgetsEmptyCta,
      onCta: onAddBudget,
    );
    final header = this.header;
    if (header == null) {
      return empty;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        header,
        const SizedBox(height: 20),
        empty,
      ],
    );
  }
}

/// The list with data: budget lines followed by the "+ Nuevo presupuesto"
/// CTA row (replaces the FAB on this screen).
class BudgetsListView extends StatelessWidget {
  const BudgetsListView({
    required this.state,
    required this.onOpenBudget,
    required this.onAddBudget,
    this.header,
    super.key,
  });

  final BudgetsListState state;
  final ValueChanged<String> onOpenBudget;
  final VoidCallback onAddBudget;

  /// The "Modo sobres" hero, when active (HU-06). Rendered as the first item.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final headerCount = header == null ? 0 : 1;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      itemCount: headerCount + state.budgets.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (header != null && index == 0) {
          return header;
        }
        final budgetIndex = index - headerCount;
        if (budgetIndex == state.budgets.length) {
          return NewBudgetCta(onTap: onAddBudget);
        }
        final entry = state.budgets[budgetIndex];
        return BudgetLine(
          entry: entry,
          onTap: () => onOpenBudget(entry.budget.id),
        );
      },
    );
  }
}

/// The "+ Nuevo presupuesto" CTA row at the end of the list.
class NewBudgetCta extends StatelessWidget {
  const NewBudgetCta({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: colors.primaryLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(LucideIcons.plus, size: 18, color: colors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.budgetsEmptyCta,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.primaryOnSoftStrong,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
