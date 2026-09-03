import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The hero's `Hero Note` (`KSaru`, `design-system/billetudo/pages/inicio.md`
/// § "Hero compacto"), only lit for `HomeHeroState.scheduledOverspendRisk`:
/// "Podría exceder por $X", pinned right under the bar's amber segment.
///
/// Deliberately never replaces the kicker/amount pair above it — see the
/// hero's "ancla fija" rule: this is additional information on its own line,
/// not a substitute for "Te quedan $X".
class RiskNote extends StatelessWidget {
  const RiskNote({required this.text, super.key});

  /// Already localized, e.g. "Podría exceder por $330.000".
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.calendarClock, size: 14, color: colors.onPrimaryWarn),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
