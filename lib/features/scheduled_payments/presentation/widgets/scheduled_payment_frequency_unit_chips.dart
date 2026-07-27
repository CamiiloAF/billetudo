import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/scheduled_payment.dart';

/// The template form's frequency picker: a row of chips (Único / Día /
/// Semana / Mes / Año), replacing the previous `DropdownButtonFormField`.
/// Drives `ScheduledPaymentFormState.showRecurrenceOptions` the same as
/// before — the cubit itself decides whether "Único" hides the interval
/// stepper/end date.
class ScheduledPaymentFrequencyUnitChips extends StatelessWidget {
  const ScheduledPaymentFrequencyUnitChips({
    required this.frequency,
    required this.onChanged,
    super.key,
  });

  final ScheduledPaymentFrequency frequency;
  final ValueChanged<ScheduledPaymentFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <ScheduledPaymentFrequency, String>{
      ScheduledPaymentFrequency.once: l10n.scheduledFrequencyChipOnce,
      ScheduledPaymentFrequency.daily: l10n.scheduledFrequencyChipDaily,
      ScheduledPaymentFrequency.weekly: l10n.scheduledFrequencyChipWeekly,
      ScheduledPaymentFrequency.monthly: l10n.scheduledFrequencyChipMonthly,
      ScheduledPaymentFrequency.yearly: l10n.scheduledFrequencyChipYearly,
    };
    // The five units live on a single line in Pencil and keep their natural
    // width (a fifth of the row each would clip "Semana"). On a narrow phone
    // or with a large text scale the strip **scrolls** instead of shrinking:
    // scaling the labels down would silently push the type below MASTER.md's
    // minimum without failing anything.
    final entries = labels.entries.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            ScheduledPaymentFrequencyUnitChip(
              label: entries[i].value,
              selected: entries[i].key == frequency,
              onTap: () => onChanged(entries[i].key),
            ),
          ],
        ],
      ),
    );
  }
}

/// One chip of `ScheduledPaymentFrequencyUnitChips`.
class ScheduledPaymentFrequencyUnitChip extends StatelessWidget {
  const ScheduledPaymentFrequencyUnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    // `J0DSIm`: the selected chip is **solid** `$primary`. An outline over
    // the same `$muted` fill left it lighter than its unselected neighbours.
    return Material(
      color: selected ? colors.primary : colors.muted,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? colors.onPrimary : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
