import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../capture/presentation/utils/cloud_transcription_vendor.dart';

/// "Transcribir mi voz en la nube" in Ajustes › Preferencias.
///
/// **No `billetudo.pen` frame covers this row.** It exists because the cloud
/// consent sheet (`kJG43`) ends with "Puedes cambiar esta decisión cuando
/// quieras en Ajustes", and shipping that sentence without the switch would
/// be a promise the screen breaks. It is built out of the section's existing
/// shape — the same card as `ShowHelpOnEntryField` / `AiNotesAccessField`
/// (`gZyEC`, Toggle Field) — rather than inventing a pattern, precisely
/// because it has no frame of its own to be faithful to.
///
/// The subtitle names the third party the same way the sheet does: a switch
/// that says only "en la nube" would be the silent version of the decision
/// this whole flow exists to avoid.
class CloudTranscriptionField extends StatelessWidget {
  const CloudTranscriptionField({
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final bool enabled;

  /// Called with the requested value. Applied straight away in both
  /// directions: the sheet already carried the full explanation, and this row
  /// repeats it in its subtitle, so a confirmation on top would only make
  /// changing one's mind harder than making it.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final vendor = CloudTranscriptionVendor.nameFor(l10n, theme.platform);

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
                LucideIcons.cloud,
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
                    l10n.settingsCloudTranscription,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  // Deliberately unbounded, like `AiNotesAccessField`'s: this
                  // line is what makes the switch informed, and truncating it
                  // would drop the half that names where the audio goes.
                  Text(
                    l10n.settingsCloudTranscriptionSubtitle(vendor),
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
