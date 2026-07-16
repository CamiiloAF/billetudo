import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/merge_summary.dart';
import 'merge_stat.dart';
import 'merge_stat_divider.dart';

class MergeStatsCard extends StatelessWidget {
  const MergeStatsCard({required this.summary, required this.l10n, super.key});

  final MergeSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final statStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.primaryOnSoft,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          MergeStat(
            value: summary.accountsCount.toString(),
            label: l10n.authMergeStatAccounts,
            style: statStyle,
          ),
          MergeStatDivider(color: colors.border),
          MergeStat(
            value: summary.transactionsCount.toString(),
            label: l10n.authMergeStatTransactions,
            style: statStyle,
          ),
          MergeStatDivider(color: colors.border),
          MergeStat(
            value: summary.categoriesCount.toString(),
            label: l10n.authMergeStatCategories,
            style: statStyle,
          ),
        ],
      ),
    );
  }
}
