import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../di/injection.dart';
import '../notes/domain/usecases/get_note_suggestions.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The shared "Nota" field (`taqc1`): a free-text input that also suggests
/// past values from history, typed in exactly once here instead of
/// duplicated across Transacciones, Deudas, Metas y Pagos Programados.
///
/// Structure per `MASTER.md` "Note Autocomplete": a `Field Wrap` (optional
/// label + Input Box, `stroke $primary` 2px while focused) plus a
/// `Suggestions Dropdown` floated below it (`fill $surface`,
/// `stroke $border` 1px, radius 14) that only appears once there is at
/// least one match — with 0 matches this behaves like a plain text field,
/// no overlay and no error message (a new note is neutral, not a mistake).
class NoteAutocompleteField extends StatefulWidget {
  const NoteAutocompleteField({
    required this.initialValue,
    required this.onChanged,
    this.label,
    this.hint,
    this.icon,
    this.errorText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.sentences,
    this.getNoteSuggestions,
    super.key,
  });

  /// The note as loaded into the form (e.g. when editing). Only synced into
  /// the field when it changes externally, never on every keystroke — and
  /// never triggers a suggestions lookup on its own (criterion: no spurious
  /// suggestions when opening a form in edit mode).
  final String initialValue;

  final ValueChanged<String> onChanged;

  /// Optional label rendered above the Input Box (13/600 `$text-secondary`,
  /// matching `Field Wrap`). `null` skips it — some sites (e.g. Metas) render
  /// their own label above this field instead.
  final String? label;

  final String? hint;

  /// Optional leading icon inside the Input Box (e.g. Deudas' `pencil`).
  final IconData? icon;

  final String? errorText;

  /// The field's own focus node. Pass one in when the site needs to react to
  /// focus changes itself (e.g. Transacciones collapsing the amount zone) —
  /// this widget never owns that kind of cross-field behaviour, only the
  /// suggestions overlay.
  final FocusNode? focusNode;

  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final TextCapitalization textCapitalization;

  /// Overrides the use case that resolves suggestions — defaults to
  /// `getIt<GetNoteSuggestions>()`. Exposed so widget/golden tests can inject
  /// a fake without touching the DI container.
  final GetNoteSuggestions? getNoteSuggestions;

  @override
  State<NoteAutocompleteField> createState() => _NoteAutocompleteFieldState();
}

class _NoteAutocompleteFieldState extends State<NoteAutocompleteField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final GetNoteSuggestions _getNoteSuggestions;
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();

  List<String> _suggestions = const [];
  int _requestId = 0;

  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _getNoteSuggestions = widget.getNoteSuggestions ?? getIt<GetNoteSuggestions>();
  }

  @override
  void didUpdateWidget(covariant NoteAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _hideOverlay();
    }
    // Repaint so the box border tracks focus (`$primary` 2px when focused).
    setState(() {});
  }

  Future<void> _handleChanged(String value) async {
    widget.onChanged(value);
    final requestId = ++_requestId;
    final suggestions = await _getNoteSuggestions(value);
    if (!mounted || requestId != _requestId) {
      return;
    }
    setState(() => _suggestions = suggestions);
    if (suggestions.isNotEmpty && _focusNode.hasFocus) {
      _overlayController.show();
    } else {
      _hideOverlay();
    }
  }

  void _hideOverlay() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  void _selectSuggestion(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    widget.onChanged(value);
    _hideOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final focused = _focusNode.hasFocus;

    final fieldWrap = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label case final label?) ...[
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          constraints: const BoxConstraints(minHeight: 50),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            border: Border.all(
              color: widget.errorText != null
                  ? colors.expense
                  : (focused ? colors.primary : colors.border),
              width: focused ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _handleChanged,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted == null
                ? null
                : (_) => widget.onSubmitted!.call(),
            textCapitalization: widget.textCapitalization,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              hintText: widget.hint,
              hintStyle: theme.textTheme.titleMedium?.copyWith(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: widget.icon == null
                  ? null
                  : Icon(widget.icon, color: colors.textSecondary, size: 18),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 18,
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
        if (widget.errorText case final errorText?) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.expense),
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: (context) => CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              offset: const Offset(0, 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: _NoteSuggestionsDropdown(
                    suggestions: _suggestions,
                    onSelected: _selectSuggestion,
                  ),
                ),
              ),
            ),
            child: fieldWrap,
          ),
        );
      },
    );
  }
}

/// The `Suggestions Dropdown`: grows freely up to 4 full rows, then caps at
/// `maxHeight: 200` with internal scroll from the 5th suggestion on, so it
/// never covers the rest of the form on mobile.
class _NoteSuggestionsDropdown extends StatelessWidget {
  const _NoteSuggestionsDropdown({
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  static const double _maxHeight = 200;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scrolls = suggestions.length > 4;

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('note-suggestions-dropdown'),
        constraints: scrolls
            ? const BoxConstraints(maxHeight: _maxHeight)
            : const BoxConstraints(),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: scrolls
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, thickness: 1, color: colors.border),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return _NoteSuggestionRow(
              label: suggestion,
              onTap: () => onSelected(suggestion),
            );
          },
        ),
      ),
    );
  }
}

/// A single `Suggestion Row`: `history` icon (16px, `$text-secondary`) +
/// label (14/500, `$text-primary`).
class _NoteSuggestionRow extends StatelessWidget {
  const _NoteSuggestionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(LucideIcons.history, size: 16, color: colors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
