import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The `Segmented Control` component (Pencil `hFu41`): a `muted` pill track
/// holding 2+ segments, the active one lifted onto a `surface` pill with a
/// tighter radius (11) than the track (`AppTheme.radiusField`).
///
/// Generic over the segment value so every feature can reuse the same visual
/// component instead of hand-rolling its own pill (e.g. "Repetir"/
/// "Periodicidad"/"Alcance" in Presupuestos, "Gasto/Ingreso/Transferencia" in
/// Movimientos and Pagos Programados).
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The ordered segments to render.
  final List<SegmentedControlOption<T>> segments;

  /// The currently active segment's value.
  final T selected;

  final ValueChanged<T> onChanged;

  /// `false` disables every segment's tap handling — used for the
  /// conditional lock treatment (e.g. Categorías' "Tipo" field on a
  /// subcategory or a root with subcategories).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: SegmentedControlSegment(
                label: segments[i].label,
                selected: segments[i].value == selected,
                activeColor: segments[i].activeColor,
                onTap: enabled ? () => onChanged(segments[i].value) : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single segment definition for [SegmentedControl].
class SegmentedControlOption<T> {
  const SegmentedControlOption({
    required this.value,
    required this.label,
    this.activeColor,
  });

  final T value;

  /// Already localized.
  final String label;

  /// Label color when this segment is active. Defaults to `textPrimary`.
  final Color? activeColor;
}

/// A single pill segment of [SegmentedControl].
class SegmentedControlSegment extends StatelessWidget {
  const SegmentedControlSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor,
    super.key,
  });

  final String label;
  final bool selected;
  final Color? activeColor;

  /// `null` renders the segment visually the same but disables taps.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: selected ? colors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? (activeColor ?? colors.textPrimary)
                  : colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
