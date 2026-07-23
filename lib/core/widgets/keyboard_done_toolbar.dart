import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';

/// Shows a "Listo" bar above the iOS system keyboard while a descendant input
/// is focused, giving keyboards without a return key (numeric/decimal) a way to
/// dismiss.
///
/// Wrap the field — not the page — so only inputs that open the system keyboard
/// get the bar; the custom amount keypads, which never focus a system input,
/// stay untouched. It observes descendant focus through a non-focusable
/// [Focus] node without owning the field's own [FocusNode], so it composes over
/// any existing input.
///
/// No-op off iOS: Android's number keyboards dismiss with the system back
/// gesture and the design system defines no accessory bar there.
class KeyboardDoneToolbar extends StatefulWidget {
  const KeyboardDoneToolbar({required this.child, super.key});

  final Widget child;

  @override
  State<KeyboardDoneToolbar> createState() => _KeyboardDoneToolbarState();
}

class _KeyboardDoneToolbarState extends State<KeyboardDoneToolbar> {
  OverlayEntry? _entry;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void dispose() {
    _removeBar();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    if (!_isIOS) {
      return;
    }
    if (hasFocus) {
      _showBar();
    } else {
      _removeBar();
    }
  }

  void _showBar() {
    if (_entry != null) {
      return;
    }
    final OverlayState overlay = Overlay.of(context);
    final OverlayEntry entry = OverlayEntry(builder: _buildBar);
    _entry = entry;
    overlay.insert(entry);
  }

  void _removeBar() {
    _entry?.remove();
    _entry = null;
  }

  Widget _buildBar(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    // Rebuilds as the keyboard animates in/out, so the bar rides just above it.
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: keyboardInset,
      child: Material(
        color: colors.surface,
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: TextButton(
            onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Text(
              l10n.commonDone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: _handleFocusChange,
      child: widget.child,
    );
  }
}
