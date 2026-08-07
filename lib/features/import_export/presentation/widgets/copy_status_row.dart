import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Copy Status Row` component (`AGZry`) as this feature uses it: a
/// `clock-3` icon plus a one-line label reporting the last time a local copy
/// (`.billetudo.json`) was saved.
///
/// Both states are content, never an error or an async state (§Nomenclatura,
/// `design-system/billetudo/pages/import-export.md`): [lastSavedLabel] `null`
/// renders "Aún no has guardado una copia" in `$text-secondary` (neutral,
/// it's simply pending); a non-null label renders in `$text-primary` (a
/// consolidated fact, reads like progress). Never `$expense`/`$amber`.
class CopyStatusRow extends StatelessWidget {
  const CopyStatusRow({
    required this.lastSavedLabel,
    required this.neverSavedLabel,
    super.key,
  });

  /// Already localized (e.g. "Última copia: 12 de julio"). `null` when no
  /// copy has ever been saved on this device.
  final String? lastSavedLabel;

  /// Already localized fallback shown when [lastSavedLabel] is `null`.
  final String neverSavedLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final label = lastSavedLabel;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.clock3,
          size: 15,
          color: label == null ? colors.textSecondary : colors.textPrimary,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label ?? neverSavedLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: label == null ? colors.textSecondary : colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
