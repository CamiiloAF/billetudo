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
          child: Text(
            l10n.scheduledPaymentFormIntervalStepperLabel,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        IconButton(
          onPressed: interval > _min ? () => onChanged(interval - 1) : null,
          icon: const Icon(LucideIcons.minus),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$interval',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: interval < _max ? () => onChanged(interval + 1) : null,
          icon: const Icon(LucideIcons.plus),
        ),
      ],
    );
  }
}
