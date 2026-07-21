import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/transaction_form_state.dart';

/// The anchored calculator keypad of the transaction form (Pencil `Keypad`
/// node `gHDTi`): a 4-column grid in calculator order (7-8-9 on top) with the
/// four operators down the right edge, and a last row where the `=` fills the
/// width alongside a fixed-width primary Confirm key (`IBiRL`, `check`).
///
/// Purely a dumb input widget: it only reports which key was tapped. Whether it
/// shows at all is up to the caller (`TransactionFormState.isKeypadVisible`);
/// collapsing it lives in the Zona Fija header chevron, not here.
///
/// When [onConfirm] is null or [confirmEnabled] is false (e.g. the payment
/// confirmation sheet, which carries its own Confirmar), the Confirm key is
/// dropped and the `=` returns to full width.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    required this.onDigit,
    required this.onDecimal,
    required this.onOperator,
    required this.onEquals,
    required this.onBackspace,
    this.onConfirm,
    this.confirmEnabled = true,
    super.key,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onDecimal;
  final ValueChanged<CalcOperator> onOperator;
  final VoidCallback onEquals;
  final VoidCallback onBackspace;

  /// Commits the amount and collapses/closes the amount zone. Null where the
  /// keypad has no Confirm key of its own.
  final VoidCallback? onConfirm;

  /// Hides the Confirm key when false, letting the `=` span the full width.
  final bool confirmEnabled;

  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeypadRow(
              keys: [
                KeypadKey.digit(digit: 7, onTap: () => onDigit(7)),
                KeypadKey.digit(digit: 8, onTap: () => onDigit(8)),
                KeypadKey.digit(digit: 9, onTap: () => onDigit(9)),
                KeypadKey.icon(
                  icon: LucideIcons.divide,
                  semanticLabel: l10n.transactionFormKeypadDivide,
                  onTap: () => onOperator(CalcOperator.divide),
                ),
              ],
            ),
            const SizedBox(height: gap),
            KeypadRow(
              keys: [
                KeypadKey.digit(digit: 4, onTap: () => onDigit(4)),
                KeypadKey.digit(digit: 5, onTap: () => onDigit(5)),
                KeypadKey.digit(digit: 6, onTap: () => onDigit(6)),
                KeypadKey.icon(
                  icon: LucideIcons.x,
                  semanticLabel: l10n.transactionFormKeypadMultiply,
                  onTap: () => onOperator(CalcOperator.multiply),
                ),
              ],
            ),
            const SizedBox(height: gap),
            KeypadRow(
              keys: [
                KeypadKey.digit(digit: 1, onTap: () => onDigit(1)),
                KeypadKey.digit(digit: 2, onTap: () => onDigit(2)),
                KeypadKey.digit(digit: 3, onTap: () => onDigit(3)),
                KeypadKey.icon(
                  icon: LucideIcons.minus,
                  semanticLabel: l10n.transactionFormKeypadSubtract,
                  onTap: () => onOperator(CalcOperator.subtract),
                ),
              ],
            ),
            const SizedBox(height: gap),
            KeypadRow(
              keys: [
                KeypadKey.decimal(
                  semanticLabel: l10n.transactionFormKeypadDecimal,
                  onTap: onDecimal,
                ),
                KeypadKey.digit(digit: 0, onTap: () => onDigit(0)),
                KeypadKey.icon(
                  icon: LucideIcons.delete,
                  semanticLabel: l10n.transactionFormKeypadBackspace,
                  onTap: onBackspace,
                ),
                KeypadKey.icon(
                  icon: LucideIcons.plus,
                  semanticLabel: l10n.transactionFormKeypadAdd,
                  onTap: () => onOperator(CalcOperator.add),
                ),
              ],
            ),
            const SizedBox(height: gap),
            Row(
              children: [
                Expanded(
                  child: KeypadKey.icon(
                    icon: LucideIcons.equal,
                    semanticLabel: l10n.transactionFormKeypadEquals,
                    onTap: onEquals,
                  ),
                ),
                if (onConfirm != null && confirmEnabled) ...[
                  const SizedBox(width: gap),
                  KeypadConfirmKey(
                    onTap: onConfirm!,
                    semanticLabel: l10n.transactionFormKeypadConfirm,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The primary Confirm key (`IBiRL`): a fixed ~44px `$primary` square with a
/// `check` glyph in `$on-primary`, pinned to the bottom-right of the last row.
/// The painted box stays ~44 to match the design, but the tap target is padded
/// out to ≥48dp (the `AI Question Chip` criterion) via an outer [SizedBox].
class KeypadConfirmKey extends StatelessWidget {
  const KeypadConfirmKey({
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  final VoidCallback onTap;
  final String semanticLabel;

  static const double _visual = 44;
  static const double _hitTarget = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: _hitTarget,
        height: _hitTarget,
        child: Center(
          child: Material(
            color: colors.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: _visual,
                height: _visual,
                child: Center(
                  child: Icon(
                    LucideIcons.check,
                    size: 20,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One row of the [NumericKeypad]: equal-width keys separated by [NumericKeypad.gap].
class KeypadRow extends StatelessWidget {
  const KeypadRow({required this.keys, super.key});

  final List<Widget> keys;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: NumericKeypad.gap),
            Expanded(child: keys[i]),
          ],
        ],
      );
}

/// A single calculator key: a boxless glyph (no border, no fill) showing
/// either a digit, the decimal point, or a lucide icon, all in `textPrimary`.
/// Only the [InkWell] ripple marks the tappable area.
class KeypadKey extends StatelessWidget {
  const KeypadKey._({
    required this.onTap,
    this.digit,
    this.isDecimal = false,
    this.icon,
    this.semanticLabel,
  });

  /// A digit key (`0`–`9`).
  const KeypadKey.digit({required int digit, required VoidCallback onTap})
      : this._(digit: digit, onTap: onTap);

  /// The decimal-point key.
  const KeypadKey.decimal({
    required String semanticLabel,
    required VoidCallback onTap,
  }) : this._(isDecimal: true, semanticLabel: semanticLabel, onTap: onTap);

  /// An operator / action key rendered as a lucide icon, with a spoken label.
  const KeypadKey.icon({
    required IconData icon,
    required String semanticLabel,
    required VoidCallback onTap,
  }) : this._(icon: icon, semanticLabel: semanticLabel, onTap: onTap);

  final int? digit;
  final bool isDecimal;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onTap;

  static const double _height = 44;
  static const String _decimalGlyph = '.';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final Widget child;
    if (icon != null) {
      child = Icon(icon, size: 18, color: colors.textPrimary);
    } else {
      final text = isDecimal ? _decimalGlyph : '$digit';
      child = Text(
        text,
        style: theme.textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: SizedBox(
            height: _height,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
