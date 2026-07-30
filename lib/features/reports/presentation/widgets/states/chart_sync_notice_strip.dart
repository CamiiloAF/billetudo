import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// HU-06 "fallo de sync": a discreet, non-blocking `$amber` tira, never a
/// full-page error — the chart underneath still shows every real data point.
///
/// Same domain signal as Home's `Sync Indicator` (`saRZW`), presented
/// differently on purpose: Home is where the user is capturing movements and
/// should not be distracted; here the user reads aggregated figures and
/// needs to know the cut might not include what another device hasn't
/// uploaded yet (`design-system/billetudo/pages/graficas.md`).
class ChartSyncNoticeStrip extends StatelessWidget {
  const ChartSyncNoticeStrip({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: colors.amberSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Icon(LucideIcons.cloudAlert, size: 18, color: colors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.reportsSyncNoticeMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: colors.amberText,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: colors.amberText),
            ],
          ),
        ),
      ),
    );
  }
}
