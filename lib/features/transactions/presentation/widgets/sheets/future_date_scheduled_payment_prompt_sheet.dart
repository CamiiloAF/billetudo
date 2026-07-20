import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// HU-06/criterion 14: asked right before persisting a movement whose date
/// is in the future — "¿Es un pago programado?". Lives in Transacciones'
/// own presentation, with no import of anything from Pagos Programados: the
/// caller only learns whether the user accepted or declined, and decides
/// what to do about it (navigate to the scheduled-payment form prefilled, or
/// save the movement as usual).
class FutureDateScheduledPaymentPromptSheet extends StatelessWidget {
  const FutureDateScheduledPaymentPromptSheet({
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// Returns `true` when the user accepted turning the movement into a
  /// scheduled payment, `false` when they declined, `null` if dismissed.
  // Not `BottomSheetBase.show`: this widget's `build` returns its content
  // unwrapped (no `BottomSheetBase` padding/handle chrome around it), so
  // this keeps `showModalBottomSheet` as-is and just opts into the root
  // navigator.
  static Future<bool?> show(BuildContext context) => showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (context) => FutureDateScheduledPaymentPromptSheet(
          onAccept: () => Navigator.of(context).pop(true),
          onDecline: () => Navigator.of(context).pop(false),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.calendarClock,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: l10n.scheduledPaymentBridgeTitle,
          message: l10n.scheduledPaymentBridgeMessage,
        ),
        const SizedBox(height: 20),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: onDecline,
            child: Text(l10n.scheduledPaymentBridgeDecline),
          ),
          right: FilledButton(
            onPressed: onAccept,
            child: Text(l10n.scheduledPaymentBridgeAccept),
          ),
        ),
      ],
    );
  }
}
