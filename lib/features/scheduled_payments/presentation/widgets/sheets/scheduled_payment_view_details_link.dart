import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// The "Ver historial y detalles" link row of the confirmation sheet: a
/// full-width 44px row directly under the sheet head that opens the pending
/// template's detail page (history + config).
///
/// It exists so a template with a pending occurrence — hidden from "Activos"
/// while pending — is still reachable without confirming, skipping or
/// snoozing first. It only navigates: it must never apply the occurrence, so
/// the mandatory confirmation (criterion 7) stays intact.
///
/// Colour is `$primary-on-soft-strong` for icon, label and chevron: this is
/// an action of the sheet, not body copy, and the tint keeps it readable on
/// both themes.
class ScheduledPaymentViewDetailsLink extends StatelessWidget {
  const ScheduledPaymentViewDetailsLink({required this.onTap, super.key});

  /// `null` disables the link without changing its layout (it stays rendered,
  /// but inert), used while the sheet is writing a confirmation so a tap can
  /// never pop the sheet out from under the in-flight write.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Icon(
              LucideIcons.history,
              size: 16,
              color: colors.primaryOnSoftStrong,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.scheduledConfirmationSheetViewDetails,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryOnSoftStrong,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: colors.primaryOnSoftStrong,
            ),
          ],
        ),
      ),
    );
  }
}
