import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../utils/budget_adjustment_windows.dart';
import '../../utils/budget_format.dart';
import '../budget_adjust_explainer.dart';
import '../budget_amount_field.dart';
import '../budget_info_row.dart';

/// What [BudgetAdjustAmountSheet] resolves with when the user confirms an
/// action. `null` (the sheet dismissed with no result) means "did nothing".
sealed class BudgetAdjustAmountResult {
  const BudgetAdjustAmountResult();
}

/// "Aplicar cambios": the amount to schedule (crear) or save (editar).
class BudgetAdjustAmountApplied extends BudgetAdjustAmountResult {
  const BudgetAdjustAmountApplied(this.newAmountMinor);

  final int newAmountMinor;
}

/// "Quitar ajuste": cancel the pending fork.
class BudgetAdjustAmountRemoved extends BudgetAdjustAmountResult {
  const BudgetAdjustAmountRemoved();
}

/// "Ajustar monto — solo el próximo período" (`A8ZfHd`/`D0EoN` crear,
/// `k6fKsZ`/`PPzUv` editar/cancelar): one field (the next period's amount)
/// over a read-only `Info Row` with the current one, and an explainer tira
/// that always spells out the whole "fork de 3 partes" mechanic in one
/// sentence — no separate confirmation sheet, same criterion as the
/// threshold sheet (`m3jomu`): the effect is reversible, so it does not
/// warrant one.
///
/// [pendingAmountMinor] switches the CTA row: `null` renders the single
/// primary "Aplicar cambios" (crear); non-null adds the secondary "Quitar
/// ajuste" (editar/cancelar) and prefills the field with it instead of
/// [currentAmountMinor].
class BudgetAdjustAmountSheet extends StatefulWidget {
  const BudgetAdjustAmountSheet({
    required this.currentAmountMinor,
    required this.currency,
    required this.windows,
    this.pendingAmountMinor,
    super.key,
  });

  /// The budget's amount for its still-running (vigente) cycle.
  final int currentAmountMinor;
  final String currency;

  /// The three cycles the fork touches.
  final BudgetAdjustmentWindows windows;

  /// The already-scheduled amount, when reopened in "editar/cancelar" mode.
  final int? pendingAmountMinor;

  static Future<BudgetAdjustAmountResult?> show(
    BuildContext context, {
    required int currentAmountMinor,
    required String currency,
    required BudgetAdjustmentWindows windows,
    int? pendingAmountMinor,
  }) =>
      BottomSheetBase.show<BudgetAdjustAmountResult>(
        context,
        builder: (context) => BudgetAdjustAmountSheet(
          currentAmountMinor: currentAmountMinor,
          currency: currency,
          windows: windows,
          pendingAmountMinor: pendingAmountMinor,
        ),
      );

  @override
  State<BudgetAdjustAmountSheet> createState() =>
      _BudgetAdjustAmountSheetState();
}

class _BudgetAdjustAmountSheetState extends State<BudgetAdjustAmountSheet> {
  late int? _amountMinor =
      widget.pendingAmountMinor ?? widget.currentAmountMinor;

  bool get _isEditing => widget.pendingAmountMinor != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    const money = MoneyFormatter();
    final amountMinor = _amountMinor;
    final canApply = amountMinor != null && amountMinor > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHead(
          title: l10n.budgetAdjustSheetTitle,
          hint: l10n.budgetAdjustSheetHint,
        ),
        const SizedBox(height: 16),
        BudgetInfoRow(
          label: l10n.budgetAdjustCurrentAmountLabel(
            BudgetFormat.rangeLabel(widget.windows.current),
          ),
          value: money.formatSymbol(
            widget.currentAmountMinor,
            currencyCode: widget.currency,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.budgetAdjustNewAmountLabel(
            BudgetFormat.rangeLabel(widget.windows.current),
          ),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        BudgetAmountField(
          amountMinor: amountMinor,
          currency: widget.currency,
          onChanged: (value) => setState(() => _amountMinor = value),
          // The currency itself never changes in this flow — only the
          // amount does — so the pill has nothing to open.
          onCurrencyTap: () {},
        ),
        const SizedBox(height: 16),
        BudgetAdjustExplainer(
          text: l10n.budgetAdjustExplainer(
            BudgetFormat.dayMonth(widget.windows.current.start),
            money.formatSymbol(
              amountMinor ?? 0,
              currencyCode: widget.currency,
            ),
            BudgetFormat.dayMonth(widget.windows.next.start),
            money.formatSymbol(
              widget.currentAmountMinor,
              currencyCode: widget.currency,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isEditing)
          SheetButtonsRow(
            left: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(const BudgetAdjustAmountRemoved()),
              icon: const Icon(LucideIcons.rotateCcw),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l10n.budgetAdjustRemoveCta, maxLines: 1),
              ),
            ),
            right: FilledButton.icon(
              onPressed: canApply
                  ? () => Navigator.of(context)
                      .pop(BudgetAdjustAmountApplied(amountMinor))
                  : null,
              icon: const Icon(LucideIcons.repeat1),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l10n.budgetAdjustApplyCta, maxLines: 1),
              ),
            ),
          )
        else
          FilledButton.icon(
            onPressed: canApply
                ? () => Navigator.of(context)
                    .pop(BudgetAdjustAmountApplied(amountMinor))
                : null,
            icon: const Icon(LucideIcons.repeat1),
            label: Text(l10n.budgetAdjustApplyCta),
          ),
      ],
    );
  }
}
