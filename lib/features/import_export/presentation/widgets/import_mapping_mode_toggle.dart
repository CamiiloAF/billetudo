import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/import_mapping_mode.dart';
import 'segmented_toggle_option.dart';

/// The mapping step's "Automático"/"Manual" segmented toggle (HU-05/06): a
/// `$muted`-track pill in the same shape as `RestoreChoiceToggle`, built from
/// the shared [SegmentedToggleOption] (same piece `DestinationResolveRow`
/// uses for its own two-way toggle) so this feature never grows a second
/// segmented-control shape.
class ImportMappingModeToggle extends StatelessWidget {
  const ImportMappingModeToggle({
    required this.mode,
    required this.onChanged,
    required this.automaticLabel,
    required this.manualLabel,
    super.key,
  });

  final ImportMappingMode mode;
  final ValueChanged<ImportMappingMode> onChanged;
  final String automaticLabel;
  final String manualLabel;

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
          Expanded(
            child: SegmentedToggleOption(
              label: automaticLabel,
              active: mode == ImportMappingMode.automatic,
              onTap: () => onChanged(ImportMappingMode.automatic),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SegmentedToggleOption(
              label: manualLabel,
              active: mode == ImportMappingMode.manual,
              onTap: () => onChanged(ImportMappingMode.manual),
            ),
          ),
        ],
      ),
    );
  }
}
