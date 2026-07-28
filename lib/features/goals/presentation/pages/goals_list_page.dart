import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../domain/services/goal_starter_templates.dart';
import '../cubit/goals_list_cubit.dart';
import '../cubit/goals_list_state.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_coherence_banner.dart';
import '../widgets/goal_momentum_header.dart';
import '../widgets/goal_starter_template_card.dart';

/// The goals list (HU-11): a `Page Header` with the add action, then either
/// the empty-state that sells (HU-13), an HU-12 coherence banner + a flat
/// list of `GoalCard`s, a loading skeleton, or an error state.
class GoalsListPage extends StatelessWidget {
  const GoalsListPage({
    required this.onAddGoal,
    required this.onOpenGoal,
    required this.onOpenArchived,
    required this.onOpenCoherenceAccount,
    super.key,
  });

  final VoidCallback onAddGoal;
  final ValueChanged<String> onOpenGoal;
  final VoidCallback onOpenArchived;
  final ValueChanged<String> onOpenCoherenceAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              title: l10n.goalsTitle,
              trailing: PageHeaderCircleButton(
                icon: LucideIcons.plus,
                background: colors.primary,
                foreground: colors.onPrimary,
                tooltip: l10n.goalsAdd,
                onPressed: onAddGoal,
              ),
            ),
            Expanded(
              child: BlocBuilder<GoalsListCubit, GoalsListState>(
                builder: (context, state) => switch (state.status) {
                  GoalsListStatus.loading => const GoalsLoadingView(),
                  GoalsListStatus.failure => GoalsErrorView(
                      onRetry: context.read<GoalsListCubit>().start,
                    ),
                  GoalsListStatus.ready when state.goals.isEmpty =>
                    GoalsEmptyView(onAddGoal: onAddGoal),
                  GoalsListStatus.ready => GoalsListView(
                      state: state,
                      onOpenGoal: onOpenGoal,
                      onOpenArchived: onOpenArchived,
                      onOpenCoherenceAccount: onOpenCoherenceAccount,
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

class GoalsLoadingView extends StatelessWidget {
  const GoalsLoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      );
}

/// HU-13: the empty-state that sells — hero copy + 3 starter templates.
class GoalsEmptyView extends StatelessWidget {
  const GoalsEmptyView({required this.onAddGoal, super.key});

  final VoidCallback onAddGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        EmptyState(
          icon: LucideIcons.target,
          message: l10n.goalsEmptyMessage,
          description: l10n.goalsEmptyDescription,
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
            onTap: onAddGoal,
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: onAddGoal,
            icon: const Icon(LucideIcons.plus, size: 16),
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
    required this.onOpenCoherenceAccount,
    super.key,
  });

  final GoalsListState state;
  final ValueChanged<String> onOpenGoal;
  final VoidCallback onOpenArchived;
  final ValueChanged<String> onOpenCoherenceAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final signals = state.coherenceSignals;
    final momentum = state.momentum;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        if (momentum.hasSignal) ...[
          GoalMomentumHeader(momentum: momentum),
          const SizedBox(height: 14),
        ],
        for (var i = 0; i < signals.length; i++) ...[
          GoalCoherenceBanner(
            signal: signals[i],
            onTap: () => onOpenCoherenceAccount(signals[i].accountId),
          ),
          const SizedBox(height: 10),
        ],
        for (var i = 0; i < state.goals.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          GoalCard(
            entry: state.goals[i],
            onTap: () => onOpenGoal(state.goals[i].goal.id),
          ),
        ],
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
    );
  }
}
