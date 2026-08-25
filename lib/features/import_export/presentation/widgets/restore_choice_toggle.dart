import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/restore_mode.dart';
import 'choice_toggle_segment.dart';

/// The `Choice Toggle` (`FMJ1w`, HU-04): a 2-segment pill choosing
/// Fusionar/Reemplazar todo. Pencil calls this ad-hoc rather than an
/// instance of the shared `Segmented Control` (`hFu41`) — "Fusionar" carries
/// a "Recomendado" sub-label the generic component has no slot for — so this
/// stays its own small widget instead of forcing that shape onto it.
///
/// The active segment is `$surface` lifted on a `$muted` track in light
/// mode; in dark mode the same pair loses almost all contrast (~1.09:1,
/// `design-system/billetudo/pages/import-export.md`), so the active segment
/// gets an explicit `$text-secondary` stroke there.
class RestoreChoiceToggle extends StatelessWidget {
  const RestoreChoiceToggle({
    required this.mode,
    required this.onChanged,
    required this.mergeLabel,
    required this.mergeSubLabel,
    required this.replaceLabel,
    super.key,
  });

  final RestoreMode mode;
  final ValueChanged<RestoreMode> onChanged;
  final String mergeLabel;
  final String mergeSubLabel;
  final String replaceLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
      ),
      child: Row(
        children: [
          ChoiceToggleSegment(
            selected: mode == RestoreMode.merge,
            onTap: () => onChanged(RestoreMode.merge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mergeLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  mergeSubLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          ChoiceToggleSegment(
            selected: mode == RestoreMode.replaceAll,
            onTap: () => onChanged(RestoreMode.replaceAll),
            child: Text(
              replaceLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: mode == RestoreMode.replaceAll
                    ? colors.textPrimary
                    : colors.segmentInactiveText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
