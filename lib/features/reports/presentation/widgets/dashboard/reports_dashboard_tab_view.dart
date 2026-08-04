import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../../goals/domain/entities/goal_with_progress.dart';
import '../../cubit/reports_dashboard_cubit.dart';
import '../../cubit/reports_dashboard_state.dart';
import '../states/chart_skeleton_view.dart';
import 'budget_summary_section.dart';
import 'debts_cross_link_card.dart';
import 'goal_summary_section.dart';
import 'reports_dashboard_hero.dart';

/// HU-04: the Resumen tab — the default tab, no Period Row of its own (D2).
class ReportsDashboardTabView extends StatefulWidget {
  const ReportsDashboardTabView({
    required this.onTapBudget,
    required this.onCreateBudget,
    required this.onTapGoal,
    required this.onCreateGoal,
    required this.onOpenDebts,
    super.key,
  });

  final ValueChanged<BudgetWithProgress> onTapBudget;
  final VoidCallback onCreateBudget;
  final ValueChanged<GoalWithProgress> onTapGoal;
  final VoidCallback onCreateGoal;
  final VoidCallback onOpenDebts;

  @override
  State<ReportsDashboardTabView> createState() =>
      _ReportsDashboardTabViewState();
}

class _ReportsDashboardTabViewState extends State<ReportsDashboardTabView> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<ReportsDashboardCubit>().start());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsDashboardCubit, ReportsDashboardState>(
      builder: (context, state) {
        if (state.isLoading || state.dashboard == null) {
          return const SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 24),
            child: ChartSkeletonView(showNote: false, columnCount: 0),
          );
        }

        final dashboard = state.dashboard!;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              if (!dashboard.isEmpty)
                ReportsDashboardHero(
                  budgets: dashboard.budgets,
                  goals: dashboard.goals,
                ),
              BudgetSummarySection(
                budgets: dashboard.budgets,
                onTapBudget: widget.onTapBudget,
                onCreateBudget: widget.onCreateBudget,
              ),
              GoalSummarySection(
                goals: dashboard.goals,
                onTapGoal: widget.onTapGoal,
                onCreateGoal: widget.onCreateGoal,
              ),
              DebtsCrossLinkCard(onTap: widget.onOpenDebts),
            ],
          ),
        );
      },
    );
  }
}
