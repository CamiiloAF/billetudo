import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// "Dejar que el asistente lea mis notas" in Ajustes › Asistente de IA
/// (`AppSettings.aiNotesAccessEnabled`).
///
/// Same card shape as `ShowHelpOnEntryField`/`EnvelopeModeField` — the shared
/// Ajustes row: icon wrap + label + subtitle + switch. No `billetudo.pen`
/// frame covers this section yet (`aaQBp`/`jDaUb` predate the assistant), so
/// it reuses the section's existing pattern instead of inventing a new one.
///
/// The subtitle carries a load-bearing message, not decoration: with the
/// switch off the assistant still searches, on device, and turning it off
/// must not read as losing the feature.
class AiNotesAccessField extends StatelessWidget {
  const AiNotesAccessField({
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final bool enabled;

  /// Called with the requested value. Turning it **on** is expected to open a
  /// confirmation first (the call site owns that); turning it off applies
  /// straight away.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                LucideIcons.sparkles,
                size: 20,
                color: colors.primaryOnSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsAiNotesAccess,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  // Deliberately unbounded: this line explains that search
                  // keeps working with the switch off, and truncating it
                  // would drop exactly the reassuring half.
                  Text(
                    l10n.settingsAiNotesAccessSubtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
