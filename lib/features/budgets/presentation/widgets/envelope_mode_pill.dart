import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The hero's "Modo sobres" pill (`Z2DJfz`): `$primary-soft` chip with the
/// `target` icon, naming the mode the list is currently in.
class EnvelopeModePill extends StatelessWidget {
  const EnvelopeModePill({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.target,
            size: 13,
            color: colors.primaryOnSoftStrong,
          ),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context).budgetsEnvelopeBadge,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.primaryOnSoftStrong,
            ),
          ),
        ],
      ),
    );
  }
}
