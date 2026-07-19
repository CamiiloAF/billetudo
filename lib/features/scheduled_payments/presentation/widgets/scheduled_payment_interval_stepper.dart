import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// "Repetir cada [− N +]": the template form's interval stepper, replacing
/// the previous free-text `TextFormField`. Hidden/disabled by the caller
/// when the frequency unit is "Único" (`interval` is ignored for a `once`
/// template — see `ScheduledPayment.interval` doc).
class ScheduledPaymentIntervalStepper extends StatelessWidget {
  const ScheduledPaymentIntervalStepper({
    required this.interval,
    required this.onChanged,
    super.key,
  });

  final int interval;
  final ValueChanged<int> onChanged;

  static const int _min = 1;
  static const int _max = 99;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          // Same treatment as its neighbours ("Cuenta", "Frecuencia",
          // "Primer pago", "Termina"): a small `text-secondary` field label,
          // not a section title.
          child: Text(
            l10n.scheduledPaymentFormIntervalStepperLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Pencil groups `− N +` inside a single `$muted` capsule instead of
        // letting the three controls float on the row.
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed:
                    interval > _min ? () => onChanged(interval - 1) : null,
                iconSize: 18,
                constraints:
                    const BoxConstraints.tightFor(width: 44, height: 44),
                icon: const Icon(LucideIcons.minus),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$interval',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    interval < _max ? () => onChanged(interval + 1) : null,
                iconSize: 18,
                constraints:
                    const BoxConstraints.tightFor(width: 44, height: 44),
                icon: const Icon(LucideIcons.plus),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
