import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/money_input_formatter.dart';
import '../../../../core/widgets/keyboard_done_toolbar.dart';

/// The amount héroe shared by the debt form (`fFS01` opening balance) and the
/// abono / actualizar-saldo sheets (`D4eDp`/`iIKjy`): a centered label, the big
/// editable amount at 38px/800, and an optional currency pill.
///
/// The mockup's caret is a "this is editable" convention; in Flutter the real
/// editability is the keyboard, so the value is a centered [TextField] with a
/// `$` prefix and the app's grouping [MoneyInputFormatter] — the same money
/// entry the rest of the app types into, so a long figure never overflows the
/// hero (item: Pencil does not render ellipsis).
///
/// [boxed] wraps the héroe in the form's `$surface` card; the sheets pass
/// `false` for the plain, card-less héroe.
class DebtAmountHeroField extends StatefulWidget {
  const DebtAmountHeroField({
    required this.label,
    required this.currency,
    required this.initialAmountMinor,
    required this.onChanged,
    this.boxed = false,
    this.currencyLabel,
    this.onTapCurrency,
    this.autofocus = false,
    this.fieldKey,
    this.errorText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  /// Already localized ("Saldo de apertura", "Abono", "Nuevo saldo").
  final String label;
  final String currency;

  /// Seeds the field once; later edits are the field's own.
  final int initialAmountMinor;
  final ValueChanged<int> onChanged;

  final bool boxed;

  /// Already localized ("COP · Peso colombiano"). `null` hides the pill (the
  /// sheets take the currency from the debt, so they show none).
  final String? currencyLabel;
  final VoidCallback? onTapCurrency;

  final bool autofocus;

  /// A stable key placed on the inner [TextField] so an e2e test can enter the
  /// amount by context (`opening` / `abono` / `nuevoSaldo`) instead of assuming
  /// a single hero is mounted.
  final Key? fieldKey;

  /// A discreet, already-localized error line shown under the héroe (e.g. the
  /// opening balance must be greater than 0). `null` hides it.
  final String? errorText;

  /// The field's own focus node, so a form can chain focus to the next text
  /// field from the numeric héroe.
  final FocusNode? focusNode;

  /// The keyboard action button ("siguiente"). `null` keeps Flutter's default,
  /// so the abono / actualizar-saldo sheets stay unchanged.
  final TextInputAction? textInputAction;

  /// Fired when the keyboard action is confirmed (used to move focus to the next
  /// text field of the form).
  final VoidCallback? onSubmitted;

  @override
  State<DebtAmountHeroField> createState() => _DebtAmountHeroFieldState();
}

class _DebtAmountHeroFieldState extends State<DebtAmountHeroField> {
  static const MoneyFormatter _money = MoneyFormatter();

  late final TextEditingController _controller = TextEditingController(
    text: _seed(widget.initialAmountMinor, widget.currency),
  );

  static String _seed(int amountMinor, String currency) {
    if (amountMinor <= 0) {
      return '';
    }
    // Seed with "cents only when they exist" (mirror of Transacciones): a whole
    // COP amount shows no decimals, one carrying cents shows them — the field
    // still accepts two decimals for every currency (see the formatter below).
    return _money.formatAmount(
      amountMinor,
      decimalDigits: MoneyFormatter.displayDecimals(amountMinor, currency),
    );
  }

  @override
  void didUpdateWidget(DebtAmountHeroField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-seed when the currency changes (its precision may drop cents);
    // the value itself is the field's own once the user starts typing.
    if (widget.currency != oldWidget.currency) {
      final text = _seed(_currentMinor(), widget.currency);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  int _currentMinor() => MoneyFormatter.parseMinor(_controller.text) ?? 0;

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
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted == null
                ? null
                : (_) => widget.onSubmitted!.call(),
            // The hero mimics a display value; the native selection handle
            // (a violet teardrop) is off-brand under the amount, so drag
            // selection is disabled while the cursor stays visible.
            enableInteractiveSelection: false,
            inputFormatters: [
              // Always allow two decimals for every currency (COP included),
              // shown only once the user presses the "," — the same money entry
              // pattern Transacciones uses (`MoneyFormatter.inputDecimals`).
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
              // The `$` already comes from `prefixText`; the hint must not
              // repeat it, or focusing the field shows a doubled "$$0".
              hintText: '0',
              hintStyle: theme.textTheme.displaySmall?.copyWith(
                color: colors.textSecondary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (widget.currencyLabel case final currencyLabel?) ...[
          const SizedBox(height: 6),
          DebtCurrencyPill(
            label: currencyLabel,
            onTap: widget.onTapCurrency,
          ),
        ],
      ],
    );

    final error = widget.errorText;
    final Widget hero = !widget.boxed
        ? content
        : Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              // A failed opening balance tints the héroe's border, mirroring the
              // form field's error box.
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

/// The currency pill under the form's héroe (`TWlRG`): the ISO code + name on a
/// `$primary-soft` chip, opening the currency picker.
class DebtCurrencyPill extends StatelessWidget {
  const DebtCurrencyPill({required this.label, this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primaryOnSoftStrong,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 5),
                Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: colors.primaryOnSoftStrong,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
