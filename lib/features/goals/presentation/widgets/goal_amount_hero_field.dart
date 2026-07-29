import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/money_input_formatter.dart';
import '../../../../core/widgets/keyboard_done_toolbar.dart';

/// The amount héroe shared by the crear/editar meta form (saldo objetivo /
/// avance inicial) and the aportar/retirar sheets: a centered label, the big
/// editable amount at 38px/800. Same pattern as Deudas' `DebtAmountHeroField`.
class GoalAmountHeroField extends StatefulWidget {
  const GoalAmountHeroField({
    required this.label,
    required this.currency,
    required this.initialAmountMinor,
    required this.onChanged,
    this.boxed = false,
    this.autofocus = false,
    this.fieldKey,
    this.errorText,
    this.compact = false,
    this.compactLeadingIcon,
    this.compactTrailing,
    super.key,
  });

  final String label;
  final String currency;
  final int initialAmountMinor;
  final ValueChanged<int> onChanged;
  final bool boxed;
  final bool autofocus;
  final Key? fieldKey;
  final String? errorText;

  /// Switches to the compact row shape crear/editar meta uses for "Objetivo"
  /// and "¿Ya tienes algo ahorrado?" (`PjBCt`'s `U7V5pb`/`BKgCe` Input Box
  /// rows): a single 52pt bordered row instead of the big centered héroe, with
  /// [label] rendered by the caller's own `GoalFieldLabel` above it instead of
  /// internally. `false` keeps the héroe shape (sheets' amount field).
  final bool compact;

  /// Only meaningful when [compact] is `true`: the row's leading icon
  /// (Avance's `piggy-bank`). `null` omits it (Objetivo has none).
  final IconData? compactLeadingIcon;

  /// Only meaningful when [compact] is `true`: an optional trailing widget
  /// (Objetivo's locked/tappable currency chip). `null` renders no trailing
  /// slot.
  final Widget? compactTrailing;

  @override
  State<GoalAmountHeroField> createState() => _GoalAmountHeroFieldState();
}

class _GoalAmountHeroFieldState extends State<GoalAmountHeroField> {
  static const MoneyFormatter _money = MoneyFormatter();

  late final TextEditingController _controller = TextEditingController(
    text: _seed(widget.initialAmountMinor, widget.currency),
  );

  static String _seed(int amountMinor, String currency) {
    if (amountMinor <= 0) {
      return '';
    }
    return _money.formatAmount(
      amountMinor,
      decimalDigits: MoneyFormatter.displayDecimals(amountMinor, currency),
    );
  }

  @override
  void didUpdateWidget(GoalAmountHeroField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentMinor = MoneyFormatter.parseMinor(_controller.text) ?? 0;
    final currencyChanged = widget.currency != oldWidget.currency;
    // Resyncing on every `initialAmountMinor` change would fight normal
    // typing: each keystroke round-trips through `onChanged` ->
    // `cubit.amountChanged` -> a rebuild with `initialAmountMinor` already
    // equal to what the controller holds, so that case is a no-op guarded by
    // the `currentMinor` comparison below. Only an *external* change (e.g.
    // "Usar todo" pushing a new max) actually differs from the controller's
    // parsed value and needs to reformat the visible text.
    final externalAmountChange =
        widget.initialAmountMinor != oldWidget.initialAmountMinor &&
            widget.initialAmountMinor != currentMinor;
    if (currencyChanged || externalAmountChange) {
      final minor = currencyChanged ? currentMinor : widget.initialAmountMinor;
      final text = _seed(minor, widget.currency);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) =>
      widget.onChanged(MoneyFormatter.parseMinor(text) ?? 0);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final error = widget.errorText;

    if (widget.compact) {
      return CompactGoalAmountField(
        controller: _controller,
        onChanged: _onChanged,
        currency: widget.currency,
        fieldKey: widget.fieldKey,
        autofocus: widget.autofocus,
        errorText: error,
        compactLeadingIcon: widget.compactLeadingIcon,
        compactTrailing: widget.compactTrailing,
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        KeyboardDoneToolbar(
          child: TextField(
            key: widget.fieldKey,
            controller: _controller,
            autofocus: widget.autofocus,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enableInteractiveSelection: false,
            inputFormatters: [
              MoneyInputFormatter(
                decimals: MoneyFormatter.inputDecimals(widget.currency),
              ),
            ],
            onChanged: _onChanged,
            cursorColor: colors.primary,
            style: theme.textTheme.displaySmall?.copyWith(
              color: colors.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              prefixText: MoneyFormatter.currencySymbol,
              prefixStyle: theme.textTheme.displaySmall?.copyWith(
                color: colors.textPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
              hintText: '0',
              hintStyle: theme.textTheme.displaySmall?.copyWith(
                color: colors.textSecondary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );

    final Widget hero = !widget.boxed
        ? content
        : Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: error == null ? colors.border : colors.expense,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: content,
          );

    if (error == null) {
      return hero;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hero,
        const SizedBox(height: 6),
        Text(
          error,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.expenseText),
        ),
      ],
    );
  }
}

/// The compact row (`U7V5pb`/`BKgCe`): a single 52pt bordered "Input Box"
/// with an optional leading icon, the editable amount, and an optional
/// trailing widget — no internal label (the caller renders its own
/// `GoalFieldLabel` above, so "Objetivo" dominates and the optional Avance
/// field reads as a plain compact row next to it, matching `PjBCt`).
///
/// Extracted from [GoalAmountHeroField]'s compact branch so it has its own
/// element in the tree and can be tested in isolation.
class CompactGoalAmountField extends StatelessWidget {
  const CompactGoalAmountField({
    required this.controller,
    required this.onChanged,
    required this.currency,
    this.fieldKey,
    this.autofocus = false,
    this.errorText,
    this.compactLeadingIcon,
    this.compactTrailing,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String currency;
  final Key? fieldKey;
  final bool autofocus;
  final String? errorText;

  /// The row's leading icon (Avance's `piggy-bank`). `null` omits it
  /// (Objetivo has none).
  final IconData? compactLeadingIcon;

  /// An optional trailing widget (Objetivo's locked/tappable currency chip).
  /// `null` renders no trailing slot.
  final Widget? compactTrailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final error = errorText;

    // Objetivo (no leading icon) is the bold 22/800 hero of the form; Avance
    // (piggy-bank icon) is deliberately smaller/lighter — same type scale the
    // `wOlOA` Form Field row uses for its own value text.
    final bold = compactLeadingIcon == null;
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colors.textPrimary,
      fontSize: bold ? 22 : 15,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );

    final row = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: error == null ? colors.border : colors.expense,
        ),
      ),
      child: Row(
        children: [
          if (compactLeadingIcon case final icon?) ...[
            Icon(icon, size: 18, color: colors.textSecondary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              key: fieldKey,
              controller: controller,
              autofocus: autofocus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              enableInteractiveSelection: false,
              inputFormatters: [
                MoneyInputFormatter(
                  decimals: MoneyFormatter.inputDecimals(currency),
                ),
              ],
              onChanged: onChanged,
              cursorColor: colors.primary,
              style: textStyle,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                prefixText: MoneyFormatter.currencySymbol,
                prefixStyle: textStyle,
                hintText: '0',
                hintStyle: textStyle?.copyWith(color: colors.textSecondary),
              ),
            ),
          ),
          if (compactTrailing case final trailing?) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );

    if (error == null) {
      return row;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        const SizedBox(height: 6),
        Text(
          error,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.expenseText),
        ),
      ],
    );
  }
}
