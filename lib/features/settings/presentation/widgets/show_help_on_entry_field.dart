import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// "Mostrar ayuda al entrar a una sección" in Ajustes › Preferencias
/// (`docs/requirements/fase-1/16-minitutoriales.md` HU-04), right after "Moneda".
/// Same card shape as `EnvelopeModeField` — icon + label + subtitle + a
/// switch — minus its "¿Qué es?" link, since there is nothing extra to
/// explain here.
class ShowHelpOnEntryField extends StatelessWidget {
  const ShowHelpOnEntryField({
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final bool enabled;
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
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                LucideIcons.circleHelp,
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
                    l10n.settingsShowHelpOnEntry,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.settingsShowHelpOnEntrySubtitle,
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
