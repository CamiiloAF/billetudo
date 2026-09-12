import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_action_proposal.dart';

/// The icon + label pair that names an `AiProposalCard`'s current status
/// (`billetudo.pen` `pXLiC`).
class AiProposalCardKicker extends StatelessWidget {
  const AiProposalCardKicker({required this.status, super.key});

  final AiProposalStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final (icon, color, label) = switch (status) {
      AiProposalStatus.pending => (
          LucideIcons.sparkles,
          colors.primaryOnSoft,
          l10n.aiProposalKickerPending,
        ),
      AiProposalStatus.confirmed => (
          LucideIcons.check,
          colors.incomeText,
          l10n.aiProposalKickerConfirmed,
        ),
      AiProposalStatus.dismissed => (
          LucideIcons.x,
          colors.textSecondary,
          l10n.aiProposalKickerDismissed,
        ),
      AiProposalStatus.failed => (
          LucideIcons.triangleAlert,
          colors.expenseText,
          l10n.aiProposalKickerFailed,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
