import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../budget_threshold_option.dart';
import 'budget_threshold_custom_sheet.dart';

/// The user's alert-threshold choice. A distinct type because "no alert" (`pct`
/// null) is a real, savable value — not the same as dismissing the sheet, which
/// returns a null [BudgetThresholdChoice].
class BudgetThresholdChoice {
  const BudgetThresholdChoice(this.pct);

  /// Whole percent 1-100, or null for "don't alert me" (HU-08).
  final int? pct;
}

/// The alert threshold sheet (`m3jomu` / `GNQ49`): presets 70/80/90 + Custom +
/// "No avisarme", default 80 (HU-08).
///
/// Picking an option only moves the check; nothing is saved until "Aplicar" —
/// the frame's `Button/Primary` at the foot of the sheet.
class BudgetThresholdSheet extends StatefulWidget {
  const BudgetThresholdSheet({required this.selected, super.key});

  final int? selected;

  static const List<int> presets = [70, 80, 90];

  /// The preset the frame flags as "Recomendado".
  static const int recommended = 80;

  static Future<BudgetThresholdChoice?> show(
    BuildContext context, {
    required int? selected,
  }) =>
      BottomSheetBase.show<BudgetThresholdChoice>(
        context,
        builder: (context) => BudgetThresholdSheet(selected: selected),
      );

  @override
  State<BudgetThresholdSheet> createState() => _BudgetThresholdSheetState();
}

class _BudgetThresholdSheetState extends State<BudgetThresholdSheet> {
  late int? _pct = widget.selected;

  bool get _customActive =>
      _pct != null && !BudgetThresholdSheet.presets.contains(_pct);

  Future<void> _openCustom() async {
    final picked = await BudgetThresholdCustomSheet.show(
      context,
      initial: _customActive ? _pct! : 85,
    );
    if (picked != null) {
      setState(() => _pct = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHead(
          title: l10n.budgetThresholdTitle,
          hint: l10n.budgetThresholdHint,
        ),
        const SizedBox(height: 12),
        for (final preset in BudgetThresholdSheet.presets)
          BudgetThresholdOption(
            label: l10n.budgetPercent(preset),
            subtitle: preset == BudgetThresholdSheet.recommended
                ? l10n.budgetThresholdRecommended
                : null,
            selected: _pct == preset,
            onTap: () => setState(() => _pct = preset),
          ),
        BudgetThresholdOption(
          label: l10n.budgetThresholdCustom,
          subtitle: _customActive
              ? l10n.budgetPercent(_pct!)
              : l10n.budgetThresholdCustomSubtitle,
          selected: _customActive,
          trailing: BudgetThresholdTrailing.chevron,
          onTap: _openCustom,
        ),
        BudgetThresholdOption(
          label: l10n.budgetFormThresholdOff,
          subtitle: l10n.budgetThresholdOffSubtitle,
          selected: _pct == null,
          onTap: () => setState(() => _pct = null),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(BudgetThresholdChoice(_pct)),
          child: Text(l10n.commonApply),
        ),
      ],
    );
  }
}
