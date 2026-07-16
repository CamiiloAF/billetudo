import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../bottom_sheet_base.dart';
import '../sheet_buttons_row.dart';

/// HU-08: the last active account cannot be deleted.
///
/// A system constraint, not a destructive act, so the icon is a neutral `info`
/// — never `$expense`.
///
/// The hierarchy is inverted on purpose: **"Entendido" is the primary** and
/// "Crear cuenta" the secondary. In a blocking sheet the dominant action is the
/// safe one that closes it; pushing the user three levels of stacking deep is
/// not the default they asked for.
class CannotDeleteLastAccountSheet extends StatelessWidget {
  const CannotDeleteLastAccountSheet({super.key});

  /// Resolves to `true` when the user chose to create another account.
  static Future<bool?> show(BuildContext context) => BottomSheetBase.show<bool>(
        context,
        builder: (context) => const CannotDeleteLastAccountSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: Icons.info_outline,
          iconColor: colors.textSecondary,
          iconBackground: colors.muted,
          title: l10n.accountCannotDeleteTitle,
          message: l10n.accountCannotDeleteMessage,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.accountCannotDeleteUnderstood),
          ),
          right: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.add),
            label: Text(l10n.accountsAdd),
          ),
        ),
      ],
    );
  }
}
