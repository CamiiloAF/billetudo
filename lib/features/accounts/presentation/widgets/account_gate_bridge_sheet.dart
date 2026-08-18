import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../core/widgets/sheet_buttons_row.dart';
import 'account_gate_copy.dart';

/// The "puente, no muro" hoja every surface of the account gate shares
/// (`docs/requirements/fase-1/15-gate-cuenta.md` HU-01, Variante B in
/// `design-system/billetudo/pages/gate-cuenta.md`): `Bottom Sheet Base` +
/// `Sheet Icon Header` + `Sheet Buttons Row` (`Zjsfz`/`XYfSq`/`goGwA`/
/// `G0mfgY`/`K6bGhq`/`xU4uz`/`oHAVJ`), parametrized by [AccountGateCopy] so
/// there is exactly one implementation for every surface, never one per
/// feature.
///
/// Never dressed as a warning: the icon lives in `$primary`/`$primary-soft`,
/// never `$expense`, and both buttons are "positive" actions — closing the
/// sheet either way, never blocking anything.
class AccountGateBridgeSheet extends StatelessWidget {
  const AccountGateBridgeSheet({required this.copy, super.key});

  final AccountGateCopy copy;

  /// Opens the sheet and resolves to `true` when the user tapped "Crear
  /// cuenta", `false` when they tapped "Ahora no" or dismissed the sheet
  /// (tap on scrim) — cancelling always leaves the caller exactly where it
  /// was (HU-01).
  static Future<bool> show(BuildContext context, AccountGateCopy copy) async {
    final result = await BottomSheetBase.show<bool>(
      context,
      builder: (context) => AccountGateBridgeSheet(copy: copy),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: copy.icon,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: copy.title,
          message: copy.message,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.accountGateNotNow),
          ),
          right: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.plus),
            label: Text(l10n.accountGateCreateAccount),
          ),
        ),
      ],
    );
  }
}
