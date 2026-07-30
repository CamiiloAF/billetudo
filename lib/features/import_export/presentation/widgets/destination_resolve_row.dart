import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import 'segmented_toggle_option.dart';

/// The `Destination Resolve Row` component (`J2L8Z`, HU-06): a name found in
/// the CSV with no match, resolved to "crear nueva" (default) or "mapear a
/// existente" — never dropped.
///
/// Segment padding is `[14,8]` (≥44pt tall), a fixed correction over the
/// original `[10,8]` (36px, under the tap-target minimum).
class DestinationResolveRow extends StatelessWidget {
  const DestinationResolveRow({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.createLabel,
    required this.mapLabel,
    required this.creatingNew,
    required this.onToggle,
    this.mappedValue,
    this.onTapMapped,
    super.key,
  });

  final IconData icon;
  final String name;

  /// Already localized ("No existe todavía en tu app").
  final String subtitle;
  final String createLabel;
  final String mapLabel;

  /// `true` = "Crear nueva" segment active; `false` = "Mapear a existente".
  final bool creatingNew;
  final ValueChanged<bool> onToggle;

  /// The currently chosen existing entity's name. Only rendered when
  /// [creatingNew] is `false`.
  final String? mappedValue;
  final VoidCallback? onTapMapped;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: colors.muted, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: colors.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedToggleOption(
                    label: createLabel,
                    active: creatingNew,
                    onTap: () => onToggle(true),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: SegmentedToggleOption(
                    label: mapLabel,
                    active: !creatingNew,
                    onTap: () => onToggle(false),
                  ),
                ),
              ],
            ),
          ),
          if (!creatingNew) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onTapMapped,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        mappedValue ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
