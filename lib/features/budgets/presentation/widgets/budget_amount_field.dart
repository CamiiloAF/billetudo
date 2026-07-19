import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';

/// The amount input of the budget form (`a3gGPM/k9OW4h`): a 52pt box holding
/// the figure at 22/800 and, anchored inside it, the currency pill
/// (`EA3R5` — `$muted`, radius 10, the ISO code at 13/700 plus a
/// `chevron-down`) that opens the currency picker.
///
/// The typed figure carries the currency's own decimals (COP has none), so a
/// prefilled amount never reads `4.500.000,00`; the placeholder is the
/// currency's zero (`$0`), exactly as the frame shows it.
class BudgetAmountField extends StatelessWidget {
  const BudgetAmountField({
    required this.amountMinor,
    required this.currency,
    required this.onChanged,
    required this.onCurrencyTap,
    super.key,
  });

  final int? amountMinor;
  final String currency;
  final ValueChanged<int?> onChanged;
  final VoidCallback onCurrencyTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    const money = MoneyFormatter();
    final decimals = MoneyFormatter.currencyDecimals(currency);
    final amountMinor = this.amountMinor;
    final style = theme.textTheme.headlineSmall?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w800,
    );

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: amountMinor == null
                  ? null
                  : money.formatAmount(amountMinor, decimalDigits: decimals),
              onChanged: (value) => onChanged(MoneyFormatter.parseMinor(value)),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: style?.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: money.formatSymbol(0, currencyCode: currency),
                hintStyle: style?.copyWith(color: colors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BudgetCurrencyPill(code: currency, onTap: onCurrencyTap),
        ],
      ),
    );
  }
}

/// The currency pill inside [BudgetAmountField] (`a3gGPM/EA3R5`).
class BudgetCurrencyPill extends StatelessWidget {
  const BudgetCurrencyPill({
    required this.code,
    required this.onTap,
    super.key,
  });

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
