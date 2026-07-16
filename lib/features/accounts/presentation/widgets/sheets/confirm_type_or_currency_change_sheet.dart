import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// HU-06: confirms changing the type or currency of an account that already has
/// transactions.
///
/// Informative, not destructive: `info` icon, and the confirm button carries a
/// `check` — an earlier version had a `trash` copied over from the delete flow,
/// which read as if the change would erase something.
class ConfirmTypeOrCurrencyChangeSheet extends StatelessWidget {
  const ConfirmTypeOrCurrencyChangeSheet({super.key});

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(BuildContext context) => BottomSheetBase.show<bool>(
        context,
        builder: (context) => const ConfirmTypeOrCurrencyChangeSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.info,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: l10n.accountChangeSheetTitle,
          message: l10n.accountChangeSheetMessage,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.check),
            label: Text(l10n.accountChangeConfirm),
          ),
        ),
      ],
    );
  }
}
