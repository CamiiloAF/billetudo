import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../domain/services/goal_starter_templates.dart';
import '../cubit/goals_list_cubit.dart';
import '../cubit/goals_list_state.dart';
import '../widgets/goal_account_filter_chip.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_coherence_banner.dart';
import '../widgets/goal_empty_hero_card.dart';
import '../widgets/goal_momentum_header.dart';
import '../widgets/goal_starter_template_card.dart';

/// The goals list (HU-11): its own `GoalsPageHeader` (no back arrow — this is
/// a tab root, see `app_router.dart`'s "Metas is a tab root now") with the
/// add action, then either the empty-state that sells (HU-13), an HU-12
/// coherence banner + a flat
/// list of `GoalCard`s, a loading skeleton, or an error state.
class GoalsListPage extends StatelessWidget {
  const GoalsListPage({
    required this.onAddGoal,
    required this.onOpenGoal,
    required this.onOpenArchived,
    super.key,
  });

  /// Opens crear-meta. An optional [GoalStarterTemplate] arrives when the
  /// empty-state's own templates (HU-13) are tapped, to prefill the form.
  final void Function([GoalStarterTemplate? template]) onAddGoal;
  final ValueChanged<String> onOpenGoal;
  final VoidCallback onOpenArchived;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            GoalsPageHeader(onAddGoal: onAddGoal),
            Expanded(
              child: BlocBuilder<GoalsListCubit, GoalsListState>(
                builder: (context, state) => switch (state.status) {
                  GoalsListStatus.loading => const GoalsLoadingView(),
                  GoalsListStatus.failure => GoalsErrorView(
                      onRetry: context.read<GoalsListCubit>().start,
                    ),
                  GoalsListStatus.ready
                      when state.goals.isEmpty && !state.isFiltered =>
                    GoalsEmptyView(onAddGoal: onAddGoal),
                  GoalsListStatus.ready => GoalsListView(
                      state: state,
                      onOpenGoal: onOpenGoal,
                      onOpenArchived: onOpenArchived,
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

/// The list's own header (`TNx20`'s `tjtML`): "Metas" left-aligned bold, a
/// single `+` action button on the right — **no back arrow**, unlike the
/// shared `PageHeader` (that one is for stacked detail/form screens). This is
/// the root of the "Metas" tab, same precedent as Presupuestos'
/// `BudgetsPageHeader`.
class GoalsPageHeader extends StatelessWidget {
  const GoalsPageHeader({required this.onAddGoal, super.key});

  final void Function([GoalStarterTemplate? template]) onAddGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.goalsTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
          ),
          PageHeaderCircleButton(
            icon: LucideIcons.plus,
            background: colors.primary,
            foreground: colors.onPrimary,
            tooltip: l10n.goalsAdd,
            onPressed: onAddGoal,
          ),
        ],
      ),
    );
  }
}

class GoalsLoadingView extends StatelessWidget {
  const GoalsLoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      );
}

/// HU-13: the empty-state that sells (`qzBkN`) — a gradient hero card, never
/// the generic `EmptyState`, plus 3 starter templates and a "Crear meta
/// personalizada" secondary button.
class GoalsEmptyView extends StatelessWidget {
  const GoalsEmptyView({required this.onAddGoal, super.key});

  final void Function([GoalStarterTemplate? template]) onAddGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        GoalEmptyHeroCard(
          headline: l10n.goalsEmptyMessage,
          subtitle: l10n.goalsEmptyDescription,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.goalsEmptyTemplatesTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < GoalStarterTemplates.all.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          GoalStarterTemplateCard(
            template: GoalStarterTemplates.all[i],
            suggestedTargetMinor: GoalStarterTemplates.suggestedTargetMinor(
              template: GoalStarterTemplates.all[i],
              averageMonthlyExpenseMinor:
                  GoalStarterTemplates.fallbackAverageMonthlyExpenseMinor,
            ),
            onTap: () => onAddGoal(GoalStarterTemplates.all[i]),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAddGoal,
            icon: const Icon(LucideIcons.pencil, size: 16),
            label: Text(l10n.goalsEmptyCustomCta),
          ),
        ),
      ],
    );
  }
}

class GoalsErrorView extends StatelessWidget {
  const GoalsErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ErrorState(
        title: AppLocalizations.of(context).goalsErrorTitle,
        onRetry: onRetry,
      );
}

class GoalsListView extends StatelessWidget {
  const GoalsListView({
    required this.state,
    required this.onOpenGoal,
    required this.onOpenArchived,
    super.key,
  });

  final GoalsListState state;
  final ValueChanged<String> onOpenGoal;
  final VoidCallback onOpenArchived;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final cubit = context.read<GoalsListCubit>();
    final momentum = state.momentum;
    final isFiltered = state.isFiltered;
    final visibleGoals = state.visibleGoals;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        if (isFiltered) ...[
          GoalAccountFilterChip(
            accountName: state.filterAccountName!,
            onClear: cubit.clearFilter,
          ),
          if (state.filteredCoherenceSignal case final signal?) ...[
            const SizedBox(height: 12),
            GoalCoherenceBanner(signal: signal),
          ],
          const SizedBox(height: 14),
        ] else ...[
          if (momentum.hasSignal) ...[
            GoalMomentumHeader(momentum: momentum),
            const SizedBox(height: 14),
          ],
          for (final signal in state.coherenceSignals) ...[
            GoalCoherenceBanner(
              signal: signal,
              onTap: () => cubit.filterByAccount(
                signal.accountId,
                signal.accountName,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        for (var i = 0; i < visibleGoals.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          GoalCard(
            entry: visibleGoals[i],
            onTap: () => onOpenGoal(visibleGoals[i].goal.id),
          ),
        ],
        if (!isFiltered) ...[
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: onOpenArchived,
              child: Text(
                l10n.goalsArchivedCta,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
