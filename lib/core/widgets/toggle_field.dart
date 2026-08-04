import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_switch.dart';

/// The `Toggle Field` component (`gZyEC`, `reusable:true` in `billetudo.pen`):
/// a `$surface`/`$border` card with a leading icon + label on the left, an
/// [AppSwitch] on the right, and a one-line hint below that explains the
/// current OFF/ON state. First used by the transferencia presupuestable
/// toggle (`design-system/billetudo/pages/transacciones.md`, Adición
/// 2026-07-24), generic enough to reuse anywhere a single boolean setting
/// needs this pattern (e.g. Metas' own toggle sheets per the same doc).
///
/// **Accessibility:** the whole row (icon + label + switch + hint) is the tap
/// target, not just the 48x28 [AppSwitch] — that alone falls under the 44x44
/// minimum. This was a hallway finding on the transferencia design, corrected
/// here rather than left to each call site.
///
/// **Disabled state:** no frame in `billetudo.pen` shows this component
/// disabled (`gZyEC` only has its ON look). `enabled: false` mutes the whole
/// row — icon, label and [AppSwitch] all render with `$text-secondary`
/// instead of `$text-primary`/`$primary`, matching the app's existing dimmed
/// treatment for disabled controls (e.g. `CalendarDayCell`'s disabled days)
/// — and disables the tap target, so a gated toggle (e.g. Metas' "mover
/// dinero" without a linked account) looks, not just behaves, non-interactive.
class ToggleField extends StatelessWidget {
  const ToggleField({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool value;
  final String hint;
  final ValueChanged<bool> onChanged;

  /// When `false`, the toggle renders dimmed and ignores taps. Defaults to
  /// `true` so existing call sites keep their current behaviour.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Semantics(
      toggled: value,
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InkWell(
          onTap: enabled ? () => onChanged(!value) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(icon, size: 18, color: colors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: enabled
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppSwitch(value: value, enabled: enabled),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
