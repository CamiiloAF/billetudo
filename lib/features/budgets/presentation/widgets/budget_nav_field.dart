import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// A navigation row of the budget form: the `Form Field` component (`wOlOA`)
/// with its outer label node **off** (`nunlr: false`), a leading inline icon,
/// the text read inline as "Etiqueta: valor" and a trailing `chevron-right`.
///
/// Every selector of `a3gGPM` is this shape (`dRD7G` Cuentas, `cL0C9`
/// Categorías, `cb5On` Inicio, `lEQXw` Repetir hasta, `kfLey` Umbral). The
/// chevron carries meaning: `chevron-right` says "a sheet opens", while
/// `chevron-down` would promise an inline dropdown — the same distinction
/// already applied in Pagos programados.
///
/// [onCleared] swaps the chevron for a tappable `x` (the optional
/// "Repetir hasta" going back to "Para siempre"), reusing the affordance
/// `TransactionFormFieldButton` established for Pagos programados' `endDate`.
class BudgetNavField extends StatelessWidget {
  const BudgetNavField({
    required this.value,
    required this.icon,
    required this.onTap,
    this.label,
    this.onCleared,
    this.errorText,
    super.key,
  });

  /// Inline prefix, already localized ("Cuentas", "Inicio"). When null the
  /// row shows [value] alone — the threshold row (`kfLey`) is a whole
  /// sentence and takes no prefix.
  final String? label;

  /// The current selection, already localized.
  final String value;

  final IconData icon;
  final VoidCallback onTap;

  /// When set, clears the field in one tap instead of opening the picker.
  final VoidCallback? onCleared;

  /// Set when the field failed validation (e.g. a one-off budget with no end
  /// date). Switches the box border to `$expense` and shows a message below.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final label = this.label;
    final errorText = this.errorText;
    final text = label == null
        ? value
        : AppLocalizations.of(context).budgetFormRowValue(label, value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusField),
                border: Border.all(
                  color: errorText != null ? colors.expense : colors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      // Pencil renders no ellipsis, so a long account name looks
                      // fine on the frame and would wrap here: pin it to one line.
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onCleared != null)
                    InkWell(
                      onTap: onCleared,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  else
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.expense),
          ),
        ],
      ],
    );
  }
}
