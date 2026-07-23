import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debt.dart';
import '../utils/debt_format.dart';

/// The interactive direction toggle (`qCUup`, `reusable:true`): "Yo debo" /
/// "Me deben" on a `$muted` track, the active segment lifted onto a `$surface`
/// pill. Direction reads by text + directional icon + selected shape, never by
/// color alone (MASTER: tone of voice, no `$expense` alarm).
class DebtDirectionToggle extends StatelessWidget {
  const DebtDirectionToggle({
    required this.direction,
    required this.onChanged,
    super.key,
  });

  final DebtDirection direction;
  final ValueChanged<DebtDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: DebtDirectionSegment(
              direction: DebtDirection.iOwe,
              selected: direction == DebtDirection.iOwe,
              onTap: () => onChanged(DebtDirection.iOwe),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: DebtDirectionSegment(
              direction: DebtDirection.owedToMe,
              selected: direction == DebtDirection.owedToMe,
              onTap: () => onChanged(DebtDirection.owedToMe),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single segment of [DebtDirectionToggle]: the directional icon + its label,
/// centered, on a `$surface` pill when selected.
class DebtDirectionSegment extends StatelessWidget {
  const DebtDirectionSegment({
    required this.direction,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final DebtDirection direction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final foreground = selected ? colors.textPrimary : colors.textSecondary;

    return Material(
      color: selected ? colors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          alignment: Alignment.center,
          // 44px tap target (padding 14 + 16px content), MASTER accessibility.
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                DebtFormat.directionIcon(direction),
                size: 16,
                color: foreground,
              ),
              const SizedBox(width: 6),
              Text(
                DebtFormat.directionLabel(l10n, direction),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
