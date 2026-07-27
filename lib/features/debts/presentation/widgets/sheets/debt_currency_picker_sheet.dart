import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';

/// Picks the debt's currency (HU-01). Multi-currency for debts is Fase 0 (the
/// summary never cross-sums), so the list stays the app's short supported set;
/// COP is the default.
class DebtCurrencyPickerSheet extends StatelessWidget {
  const DebtCurrencyPickerSheet({required this.selected, super.key});

  /// ISO-4217 codes offered here, in display order.
  static const List<String> supportedCurrencies = ['COP', 'USD'];

  final String selected;

  /// Resolves to the chosen ISO-4217 code, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String selected,
  }) =>
      BottomSheetBase.show<String>(
        context,
        builder: (context) => DebtCurrencyPickerSheet(selected: selected),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetHead(title: l10n.debtCurrencySheetTitle),
        const SizedBox(height: 12),
        for (final code in supportedCurrencies) ...[
          DebtCurrencyRow(
            code: code,
            name: _nameOf(code, l10n),
            selected: code == selected,
            onTap: () => Navigator.of(context).pop(code),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  static String _nameOf(String code, AppLocalizations l10n) =>
      code == 'USD' ? l10n.currencyUsdName : l10n.currencyCopName;
}

/// One currency option: the code, its name, and a check when it is the current
/// choice.
class DebtCurrencyRow extends StatelessWidget {
  const DebtCurrencyRow({
    required this.code,
    required this.name,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String code;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: selected ? colors.primarySoft : colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Text(
                  code,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Icon(LucideIcons.check, size: 18, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
