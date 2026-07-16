import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Currency Row` component: a row of the currency picker.
///
/// Selection shows as a check on the right, without tinting the whole row —
/// the pattern MASTER.md documents for text/list rows.
class CurrencyRow extends StatelessWidget {
  const CurrencyRow({
    required this.code,
    required this.name,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// ISO-4217 code, e.g. 'COP'.
  final String code;

  /// Localized name of the currency.
  final String name;

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primarySoft : colors.muted,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  code,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? colors.primaryOnSoftStrong
                        : colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              if (isSelected)
                Icon(Icons.check, color: colors.primaryOnSoft, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
