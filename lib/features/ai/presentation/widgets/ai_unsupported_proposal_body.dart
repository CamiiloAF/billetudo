import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The Body Slot for an `UnsupportedProposal`: plain text, no structured
/// rows, matching the domain's own rule that this kind never offers a
/// confirm button (`ai_action_proposal_mapper.dart`).
class AiUnsupportedProposalBody extends StatelessWidget {
  const AiUnsupportedProposalBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Text(
      l10n.aiProposalUnsupported,
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
      ),
    );
  }
}
