import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The cross-link banner (`fVmhb`) shown only in the Configurar-cuota mode of
/// the form: a `$primary-soft` card with a `calendar-clock` icon explaining
/// that saving creates a scheduled payment linked to the debt, confirmable or
/// postponable from Pagos programados (HU-03).
class ScheduledPaymentInstallmentBanner extends StatelessWidget {
  const ScheduledPaymentInstallmentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.calendarClock,
            size: 18,
            color: colors.primaryOnSoft,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.scheduledPaymentInstallmentBanner,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: colors.hintText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
