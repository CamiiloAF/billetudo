import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';

/// Where the "Personalizado ›" chevron of `m3jomu/bWlly` leads.
///
/// **Pending design:** `billetudo.pen` draws the chevron but has no frame for
/// its destination, so this screen is assembled only out of already-designed
/// primitives (`Bottom Sheet Base` head + `Button/Primary`) and holds no
/// invented ornament. Replace it with the real frame once design ships one.
class BudgetThresholdCustomSheet extends StatefulWidget {
  const BudgetThresholdCustomSheet({required this.initial, super.key});

  /// Whole percent 1-100 the stepper opens on.
  final int initial;

  /// Resolves to the chosen percent, or `null` if dismissed.
  static Future<int?> show(BuildContext context, {required int initial}) =>
      BottomSheetBase.show<int>(
        context,
        builder: (context) => BudgetThresholdCustomSheet(initial: initial),
      );

  @override
  State<BudgetThresholdCustomSheet> createState() =>
      _BudgetThresholdCustomSheetState();
}

class _BudgetThresholdCustomSheetState
    extends State<BudgetThresholdCustomSheet> {
  late int _value = widget.initial.clamp(5, 100);

  void _nudge(int delta) =>
      setState(() => _value = (_value + delta).clamp(5, 100));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHead(
          title: l10n.budgetThresholdCustomTitle,
          hint: l10n.budgetThresholdCustomHint,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _value > 5 ? () => _nudge(-5) : null,
              tooltip: l10n.budgetThresholdDecrease,
              icon: const Icon(LucideIcons.minus),
            ),
            SizedBox(
              width: 96,
              child: Text(
                l10n.budgetPercent(_value),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: _value < 100 ? () => _nudge(5) : null,
              tooltip: l10n.budgetThresholdIncrease,
              icon: const Icon(LucideIcons.plus),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: Text(l10n.commonApply),
        ),
      ],
    );
  }
}
