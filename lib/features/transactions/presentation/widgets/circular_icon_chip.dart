import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A 44×44 circular, icon-only utility chip (`F7W1a`/`tqnnw` in the
/// Movimientos "Chips de Cuenta" proposal): fixed `$primary-soft` fill with a
/// `$text-secondary` icon, never binary active/inactive like
/// `FilterChipPill` — this is a one-shot action (e.g. "select all" or
/// "clear"), not a filter with a selected state.
class CircularIconChip extends StatelessWidget {
  const CircularIconChip({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Announced to screen readers in place of the icon-only, textless chip.
  final String? semanticLabel;

  /// Shown on long-press/hover — the sighted-user equivalent of
  /// [semanticLabel] for a chip with no visible text.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final button = Material(
      color: colors.primarySoft,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 16, color: colors.textSecondary),
        ),
      ),
    );

    final withTooltip =
        tooltip == null ? button : Tooltip(message: tooltip!, child: button);

    return Semantics(
      label: semanticLabel,
      button: true,
      excludeSemantics: semanticLabel != null,
      child: withTooltip,
    );
  }
}
