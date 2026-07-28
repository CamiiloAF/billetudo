import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../domain/entities/goal_with_progress.dart';
import '../cubit/archived_goals_cubit.dart';
import '../cubit/archived_goals_state.dart';
import '../widgets/archived_goal_row.dart';

/// HU-09: "Metas archivadas" (`owwhT`/`aekkM`): a flat list of paused goals,
/// each with a one-tap "Desarchivar" that brings it back to the main list.
class ArchivedGoalsPage extends StatelessWidget {
  const ArchivedGoalsPage({required this.onOpenGoal, super.key});

  final ValueChanged<String> onOpenGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.goalsArchivedTitle),
            Expanded(
              child: BlocBuilder<ArchivedGoalsCubit, ArchivedGoalsState>(
                builder: (context, state) => switch (state.status) {
                  ArchivedGoalsStatus.loading =>
                    const Center(child: CircularProgressIndicator()),
                  ArchivedGoalsStatus.failure => ErrorState(
                      title: l10n.goalsErrorTitle,
                      onRetry: context.read<ArchivedGoalsCubit>().start,
                    ),
                  ArchivedGoalsStatus.ready when state.goals.isEmpty =>
                    EmptyState(
                      icon: LucideIcons.archive,
                      message: l10n.goalsArchivedEmptyMessage,
                      description: l10n.goalsArchivedEmptyDescription,
                    ),
                  ArchivedGoalsStatus.ready => ArchivedGoalsListView(
                      goals: state.goals,
                      accounts: state.accounts,
                      onOpenGoal: onOpenGoal,
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

class ArchivedGoalsListView extends StatelessWidget {
  const ArchivedGoalsListView({
    required this.goals,
    required this.accounts,
    required this.onOpenGoal,
    super.key,
  });

  final List<GoalWithProgress> goals;
  final List<AccountWithBalance> accounts;
  final ValueChanged<String> onOpenGoal;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      itemCount: goals.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => ArchivedGoalRow(
        entry: goals[index],
        accountName: _accountName(goals[index].goal.accountId),
        onTap: () => onOpenGoal(goals[index].goal.id),
      ),
    );
  }

  String? _accountName(String? accountId) {
    if (accountId == null) {
      return null;
    }
    for (final entry in accounts) {
      if (entry.account.id == accountId) {
        return entry.account.name;
      }
    }
    return null;
  }
}
