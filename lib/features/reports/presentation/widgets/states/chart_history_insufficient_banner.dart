import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// HU-06 "historial insuficiente" note (`fFjhO`): the view narrowed the
/// range and switched to daily buckets instead of faking a longer series.
class ChartHistoryInsufficientBanner extends StatelessWidget {
  const ChartHistoryInsufficientBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.sparkles, size: 16, color: colors.hintText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.reportsCashflowShortHistoryNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: colors.hintText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
