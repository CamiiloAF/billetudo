import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transaction_form_state.dart';
import 'numeric_keypad.dart';

/// The `Zona Fija` of the transaction form (`transacciones.md`): the amount is
/// the most important datum on the screen, so it is anchored to the bottom and
/// **always visible**, in one of two states.
///
/// - **Expanded** ([expanded] true, keypad shown): a header with the label and
///   a chevron-down to collapse, the big amount value, and the anchored
///   [NumericKeypad]. This is the default when the form opens.
/// - **Collapsed** ([expanded] false): a narrow persistent bar (~72px) that
///   still shows the label + amount and a chevron-up to reopen the keypad. The
///   collapse is never to `height:0` — tapping the bar re-expands.
///
/// [expanded] mirrors `TransactionFormState.isKeypadVisible` (focus on the
/// amount); the collapsed bar is shown whenever the Nota field (or nothing)
/// holds focus, ceding the lower space to the native keyboard.
class TransactionAmountFixedZone extends StatelessWidget {
  const TransactionAmountFixedZone({
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.expanded,
    required this.onExpand,
    required this.onCollapse,
    required this.onDigit,
    required this.onDecimal,
    required this.onOperator,
    required this.onEquals,
    required this.onBackspace,
    this.entryFractionDigits = -1,
    this.onBackspaceLongPress,
    this.errorText,
    super.key,
  });

  final TransactionType type;
  final int amountMinor;
  final String currency;

  /// How many fraction digits the active entry has typed (the cubit's
  /// `entryFractionDigits`): `0` renders the pending decimal separator so the
  /// comma shows the instant it is pressed (item 20). Only meaningful while
  /// [expanded].
  final int entryFractionDigits;

  /// True when the keypad is showing (amount has focus).
  final bool expanded;

  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final ValueChanged<int> onDigit;
  final VoidCallback onDecimal;
  final ValueChanged<CalcOperator> onOperator;
  final VoidCallback onEquals;
  final VoidCallback onBackspace;

  /// Long-pressing backspace clears the whole amount (item 5).
  final VoidCallback? onBackspaceLongPress;

  /// Set when the amount failed validation (HU-01 criterion 8: a movement
  /// needs a positive amount). Shown as a message anchored above the zone so
  /// Guardar no longer feels like a silent no-op.
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
      // Expand <-> collapse is a sober size + cross-fade transition: the amount
      // stays visible while the keypad and the big value grow/shrink, and the
      // zone changes height without a jump. Anchored to the bottom so it grows
      // upward, never nudging the anchored layout.
      child: AnimatedSize(
        duration: AppTheme.motionDuration,
        curve: AppTheme.motionCurve,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.expense),
                ),
              ),
            AnimatedSwitcher(
              duration: AppTheme.motionDuration,
              switchInCurve: AppTheme.motionCurve,
              switchOutCurve: AppTheme.motionCurve,
              child: expanded
                  ? TransactionAmountExpandedZone(
                      key: const ValueKey('expanded'),
                      type: type,
                      amountMinor: amountMinor,
                      currency: currency,
                      entryFractionDigits: entryFractionDigits,
                      onCollapse: onCollapse,
                      onDigit: onDigit,
                      onDecimal: onDecimal,
                      onOperator: onOperator,
                      onEquals: onEquals,
                      onBackspace: onBackspace,
                      onBackspaceLongPress: onBackspaceLongPress,
                    )
                  : TransactionAmountCollapsedBar(
                      key: const ValueKey('collapsed'),
                      type: type,
                      amountMinor: amountMinor,
                      currency: currency,
                      onExpand: onExpand,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// The amount value color per type, mirroring `Transaction Row`
  /// (`transacciones.md`): expense is neutral (never red), income uses the
  /// contrast-safe income text token, transfer uses the brand color.
  static Color amountColor(AppColors colors, TransactionType type) =>
      switch (type) {
        TransactionType.expense => colors.textPrimary,
        TransactionType.income => colors.incomeText,
        TransactionType.transfer => colors.primary,
      };

  static String amountLabel(AppLocalizations l10n, TransactionType type) =>
      type == TransactionType.transfer
          ? l10n.transactionFormTransferAmountLabel
          : l10n.transactionFormAmountLabel;
}

/// The expanded state of the [TransactionAmountFixedZone]: collapse header,
/// the big amount value, and the anchored keypad.
class TransactionAmountExpandedZone extends StatelessWidget {
  const TransactionAmountExpandedZone({
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.onCollapse,
    required this.onDigit,
    required this.onDecimal,
    required this.onOperator,
    required this.onEquals,
    required this.onBackspace,
    this.entryFractionDigits = -1,
    this.onBackspaceLongPress,
    super.key,
  });

  final TransactionType type;
  final int amountMinor;
  final String currency;

  /// See [TransactionAmountFixedZone.entryFractionDigits].
  final int entryFractionDigits;
  final VoidCallback onCollapse;
  final ValueChanged<int> onDigit;
  final VoidCallback onDecimal;
  final ValueChanged<CalcOperator> onOperator;
  final VoidCallback onEquals;
  final VoidCallback onBackspace;

  /// Long-pressing backspace clears the whole amount (item 5).
  final VoidCallback? onBackspaceLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  TransactionAmountFixedZone.amountLabel(l10n, type),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCollapse,
                tooltip: l10n.transactionFormCollapseAmount,
                iconSize: 20,
                color: colors.textSecondary,
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                icon: const Icon(LucideIcons.chevronDown),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            money.formatSymbolEntry(
              amountMinor,
              currencyCode: currency,
              entryFractionDigits: entryFractionDigits,
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: TransactionAmountFixedZone.amountColor(colors, type),
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        NumericKeypad(
          onDigit: onDigit,
          onDecimal: onDecimal,
          onOperator: onOperator,
          onEquals: onEquals,
          onBackspace: onBackspace,
          onBackspaceLongPress: onBackspaceLongPress,
          // Confirm commits the amount by collapsing the Zona Fija, the same
          // action as the header chevron.
          onConfirm: onCollapse,
        ),
      ],
    );
  }
}

/// The collapsed state of the [TransactionAmountFixedZone]: a narrow
/// persistent bar that keeps the amount visible with a chevron-up to reopen.
class TransactionAmountCollapsedBar extends StatelessWidget {
  const TransactionAmountCollapsedBar({
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.onExpand,
    super.key,
  });

  final TransactionType type;
  final int amountMinor;
  final String currency;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    return InkWell(
      onTap: onExpand,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
          child: Row(
            children: [
              // Left spacer matching the 44x44 chevron wrap on the right, so
              // the amount block is genuinely centered on the full width, not
              // just within the space the chevron leaves.
              const SizedBox(width: 44, height: 44),
              Expanded(
                child: Column(
                  // Centered per Pencil `ofg07` (Amount Block Mini,
                  // alignItems:center) — Column's default is center.
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TransactionAmountFixedZone.amountLabel(l10n, type),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      money.formatSymbol(amountMinor, currencyCode: currency),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: TransactionAmountFixedZone.amountColor(
                          colors,
                          type,
                        ),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onExpand,
                tooltip: l10n.transactionFormExpandAmount,
                iconSize: 20,
                color: colors.textSecondary,
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                icon: const Icon(LucideIcons.chevronUp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
