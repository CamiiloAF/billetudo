import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'scheduled_payment_editable_amount_field.dart';

/// The template form's own "Zona Fija" (`transacciones.md`'s `Rslzk`/`ofg07`
/// pattern, mirrored by `TransactionAmountFixedZone`): the amount is anchored
/// to the bottom of the screen, outside the scrollable list of fields,
/// instead of being one more `TextFormField` between Categoría and
/// Frecuencia.
///
/// Reuses [ScheduledPaymentEditableAmountField] — the same tap-to-expand
/// calculator keypad the confirmation sheet already uses — so both places
/// that edit an amount in this feature behave identically; only the anchored
/// surface/border chrome around it is specific to the form.
class ScheduledPaymentAmountFixedZone extends StatelessWidget {
  const ScheduledPaymentAmountFixedZone({
    required this.amountMinor,
    required this.currency,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final int amountMinor;
  final String currency;
  final ValueChanged<int> onChanged;

  /// Set when the amount failed validation (HU-01: a template needs a positive
  /// amount). Shown as a message anchored above the zone so Guardar no longer
  /// feels like a silent no-op.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final errorText = this.errorText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    errorText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.expense),
                  ),
                ),
              ScheduledPaymentEditableAmountField(
                amountMinor: amountMinor,
                currency: currency,
                // Pencil paints the anchored amount in `$text-primary`: the
                // brand violet is for the keypad/actions, not for the value.
                valueColor: colors.textPrimary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
