import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The Nota field of the transaction form — the only free-text input, so
/// focusing it collapses the anchored amount zone and brings up the native
/// keyboard (`transacciones.md`).
///
/// Stateful on purpose: it owns a stable [TextEditingController] and
/// [FocusNode] for the lifetime of the field, instead of rebuilding a throwaway
/// controller on every cubit emission (which fought the user's typing).
class TransactionNoteField extends StatefulWidget {
  const TransactionNoteField({
    required this.initialNote,
    required this.amountHasFocus,
    required this.onChanged,
    required this.onFocused,
    super.key,
  });

  /// The note as loaded into the form (e.g. when editing). Only synced into the
  /// controller when it changes externally, never on every keystroke.
  final String initialNote;

  /// When true the amount zone reclaimed focus (e.g. the collapsed bar was
  /// tapped), so this field drops the native keyboard.
  final bool amountHasFocus;

  final ValueChanged<String> onChanged;
  final VoidCallback onFocused;

  @override
  State<TransactionNoteField> createState() => _TransactionNoteFieldState();
}

class _TransactionNoteFieldState extends State<TransactionNoteField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onFocused();
    }
    // Repaint so the box border tracks focus (`$primary` 2px when focused).
    setState(() {});
  }

  @override
  void didUpdateWidget(TransactionNoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync an external change (edit prefill) without clobbering live typing.
    if (widget.initialNote != oldWidget.initialNote &&
        widget.initialNote != _controller.text) {
      _controller.text = widget.initialNote;
    }
    // The amount zone took focus: hide the native keyboard for this field.
    if (widget.amountHasFocus &&
        !oldWidget.amountHasFocus &&
        _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final focused = _focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.transactionFormNoteLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 50),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            border: Border.all(
              color: focused ? colors.primary : colors.border,
              width: focused ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              hintText: l10n.transactionFormNoteHint,
              hintStyle: theme.textTheme.titleMedium?.copyWith(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
