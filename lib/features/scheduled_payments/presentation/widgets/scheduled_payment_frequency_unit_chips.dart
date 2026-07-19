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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in labels.entries)
          ScheduledPaymentFrequencyUnitChip(
            label: entry.value,
            selected: entry.key == frequency,
            onTap: () => onChanged(entry.key),
          ),
      ],
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
    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? colors.primary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? colors.primaryDeep : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
