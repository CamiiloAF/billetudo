import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Import Batch Row` component (`czuGE`): 40x40 icon wrap, file name +
/// meta, chevron and an optional floating "Revertida" badge — 92pt card.
///
/// **Text contract:** [fileName] has no length cap and always renders on one
/// line with an ellipsis (Pencil cannot draw one — the cut-off in the canvas
/// is a tool limitation, not a design defect).
class ImportBatchRow extends StatelessWidget {
  const ImportBatchRow({
    required this.fileName,
    required this.metaLabel,
    required this.onTap,
    this.reverted = false,
    this.revertedLabel,
    super.key,
  });

  final String fileName;

  /// Already localized (e.g. "1.284 movimientos · hace 2 días").
  final String metaLabel;

  final VoidCallback onTap;

  /// `HU-08`: the batch was undone. Shows the floating badge, and the icon
  /// switches to a neutral tone instead of `$mint`.
  final bool reverted;

  /// Already localized, required when [reverted] is `true`.
  final String? revertedLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: reverted ? colors.muted : colors.mintSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.fileCheck2,
                      size: 18,
                      color: reverted ? colors.textSecondary : colors.mint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          metaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ],
              ),
              if (reverted && revertedLabel != null)
                Positioned(
                  top: -22,
                  right: 40,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      revertedLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.segmentInactiveText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
