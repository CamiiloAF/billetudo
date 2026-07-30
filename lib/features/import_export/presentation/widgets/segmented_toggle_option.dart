import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One option within a two-way segmented toggle (e.g. "Crear nueva" /
/// "Mapear a existente" in `DestinationResolveRow`): a tappable pill that
/// highlights when [active].
class SegmentedToggleOption extends StatelessWidget {
  const SegmentedToggleOption({
    required this.label,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? colors.textPrimary : colors.segmentInactiveText,
          ),
        ),
      ),
    );
  }
}
