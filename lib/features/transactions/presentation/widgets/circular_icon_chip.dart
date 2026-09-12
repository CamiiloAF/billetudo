import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A 44×44 circular, icon-only utility chip (`F7W1a`/`tqnnw` in the
/// Movimientos "Chips de Cuenta" proposal): `$primary-soft` fill with a
/// `$text-secondary` icon by default.
///
/// Issue #incidencias-pruebas-manuales: the account row's leading chip is
/// now a real toggle ("seleccionar todas" ⇄ "limpiar selección"), so it
/// needs the same active/inactive contrast `FilterChipPill` uses — [active]
/// switches it to the `$primary`-on-`$primary-soft` treatment instead of the
/// former fixed, never-highlighted look.
class CircularIconChip extends StatelessWidget {
  const CircularIconChip({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
    this.tooltip,
    this.active = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Announced to screen readers in place of the icon-only, textless chip.
  final String? semanticLabel;

  /// Shown on long-press/hover — the sighted-user equivalent of
  /// [semanticLabel] for a chip with no visible text.
  final String? tooltip;

  /// Highlights the chip with the same `$primary` treatment
  /// `FilterChipPill` uses for an active filter — e.g. the account row's
  /// leading chip once every account ends up selected.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final button = Material(
      color: colors.primarySoft,
      shape: CircleBorder(
        side: BorderSide(color: active ? colors.primary : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 16,
            color: active ? colors.primaryOnSoftStrong : colors.textSecondary,
          ),
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
