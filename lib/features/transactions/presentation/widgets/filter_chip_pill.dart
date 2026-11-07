import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One pill of the `Movimientos` filter row (`B3GGa`/`xAk6Y`): neutral by
/// default, switching to the `primary-soft`/`primary` treatment the instant
/// its own dimension has an active filter — the same rule for all five chips
/// (cuenta, categoría, tipo, fecha, etiqueta).
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.onLongPress,
    this.leadingIcon,
    this.leadingWidget,
    this.trailingIcon,
    this.semanticHint,
    this.enabled = true,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  /// Secondary gesture, e.g. the account chips' "start multi-selection".
  /// `null` on every other chip.
  final VoidCallback? onLongPress;

  /// 14px, e.g. the selected account's type icon.
  ///
  /// Ignored when [leadingWidget] is set.
  final IconData? leadingIcon;

  /// A fully custom leading slot, e.g. the account chips' tinted icon-wrap
  /// (`bIg7X`/`rHkkz`), which needs its own background circle and colour
  /// derived from `AccountType` — something a plain [leadingIcon] can't
  /// express. Takes precedence over [leadingIcon] when both are set.
  final Widget? leadingWidget;

  /// 14px, e.g. the account chip's `chevron-down`.
  final IconData? trailingIcon;

  /// Announced by screen readers as the long-press action's purpose. The
  /// account row's multi-selection is a hidden gesture: without this, a
  /// screen-reader user has no way to discover it (same reasoning as
  /// `AppFab.longPressHint`).
  final String? semanticHint;

  /// When false, the chip is inert (no tap) and rendered dimmed — used when
  /// another active filter makes this dimension meaningless (e.g. the Fecha
  /// chip while a Presupuesto filter is active, which already carries its own
  /// date window).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final foreground =
        active ? colors.primaryOnSoftStrong : colors.textSecondary;

    final chip = Material(
      color: active ? colors.primarySoft : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: active ? colors.primary : colors.border),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingWidget != null) ...[
                leadingWidget!,
                const SizedBox(width: 6),
              ] else if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 14, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: active ? 13 : 12,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(trailingIcon, size: 14, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: semanticHint == null
          ? chip
          : Semantics(hint: semanticHint, child: chip),
    );
  }
}
