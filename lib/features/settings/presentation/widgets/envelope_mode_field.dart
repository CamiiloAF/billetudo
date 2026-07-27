import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The "Modo sobres" row in Ajustes (HU-06): icon + label + a "¿Qué es?" link
/// that opens the info sheet, closed by a switch that persists the flag. Opt-in
/// at the app level, never forced.
class EnvelopeModeField extends StatelessWidget {
  const EnvelopeModeField({
    required this.enabled,
    required this.onChanged,
    required this.onWhatIs,
    super.key,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onWhatIs;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  LucideIcons.target,
                  size: 20,
                  color: colors.primaryOnSoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // `Settings Row`'s `Label` (`grTTH`) is 15/600.
                    Text(
                      l10n.settingsEnvelopeMode,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.settingsEnvelopeModeSubtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onWhatIs,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          l10n.settingsEnvelopeWhatIs,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.primaryOnSoftStrong,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
