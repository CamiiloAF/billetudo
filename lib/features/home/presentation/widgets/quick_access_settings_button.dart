import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Trailing affordance of `QuickAccessRow` that opens Ajustes ▸ "Orden del
/// acceso rápido" (`AppRoutes.quickAccessOrder`).
///
/// Deliberately NOT a `QuickAccessChip`: a fourth pill identical to the others
/// reads as a fourth destination, and this one configures the row instead of
/// navigating into a section. It keeps the row's chrome (`$surface` fill,
/// `$border` outline, 44pt tap target) so it still belongs to the strip, but
/// drops the label and takes the circular shape of the design system's shared
/// 44x44 icon button (`MASTER.md`: "Radio de icon-wrap circular: mitad de su
/// alto"). Icon-only, so the accessible name comes from [Tooltip] — which
/// Flutter also exposes to screen readers — never from visible text.
class QuickAccessSettingsButton extends StatelessWidget {
  const QuickAccessSettingsButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Tooltip(
          message: l10n.homeQuickAccessCustomize,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              LucideIcons.settings,
              size: 18,
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
