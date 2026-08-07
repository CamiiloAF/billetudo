import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../../../core/widgets/sheet_buttons_row.dart';

/// The HU-09 file-error pattern (`a5XdP`/`TmHSC`): a neutral treatment (no
/// red, same icon-wrap/icon pair as `ErrorState`, `$muted`/`$text-secondary`)
/// because a malformed file is a problem with the file, never with the user.
///
/// Pencil always pairs the action CTA with a "Cancelar" that leaves the flow
/// entirely (`Ot4yI` Sheet Buttons Row): [onCancel] renders that second
/// button. `null` keeps the single full-width action for the rare caller
/// with nowhere to cancel back to.
class IoErrorView extends StatelessWidget {
  const IoErrorView({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.onCancel,
    this.stackButtons = false,
    super.key,
  });

  final IconData icon;

  /// Already localized ("No pudimos leer este archivo").
  final String title;

  /// Already localized reassurance line.
  final String message;

  /// Already localized ("Elegir otro archivo" / "Reintentar").
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  /// Closes the whole flow instead of retrying. `null` omits the button.
  final VoidCallback? onCancel;

  /// Stacks "Cancelar" above [actionLabel] instead of the default 50/50
  /// `Sheet Buttons Row` split — for a caller whose [actionLabel] is long
  /// enough to truncate at half-width (ej. "Elegir otro archivo" vs.
  /// "Reintentar"). Same fix already applied to "Deshacer importación"
  /// (MASTER.md, "CTA destructivo con label largo"): prioritize readable
  /// text over keeping the 50/50 layout.
  final bool stackButtons;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final action = NeutralButton(label: actionLabel, icon: actionIcon, onPressed: onAction);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetMessage(
              icon: icon,
              iconColor: colors.textSecondary,
              iconBackground: colors.muted,
              title: title,
              message: message,
              messageColor: colors.textSecondary,
              messageFontSize: 14,
            ),
            const SizedBox(height: 20),
            if (onCancel case final onCancel? when stackButtons)
              Column(
                children: [
                  SizedBox(width: double.infinity, child: action),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                ],
              )
            else if (onCancel case final onCancel?)
              SheetButtonsRow(
                left: OutlinedButton(onPressed: onCancel, child: Text(l10n.commonCancel)),
                right: action,
              )
            else
              SizedBox(width: double.infinity, child: action),
          ],
        ),
      ),
    );
  }
}

/// Shortcut icon set for the two HU-09 error kinds.
abstract final class IoErrorIcons {
  const IoErrorIcons._();

  static const IconData unreadableFile = LucideIcons.fileX;
  static const IconData writeFailure = LucideIcons.triangleAlert;
  static const IconData chooseAnotherFile = LucideIcons.folderOpen;
  static const IconData retry = LucideIcons.refreshCw;
}
