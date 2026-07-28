import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';

/// `Copy Status Row` (`AGZry`): a clock glyph plus one line of time.
///
/// **It is shown in every state, healthy included.** If it only appeared when
/// something went wrong the user would have nothing to compare against — that
/// is the literal lesson of the incident that produced this feature.
///
/// The difference between "fine" and "worth a look" is carried by the colour
/// weight of the label (and its glyph), never by an alarm colour: `$expense`
/// is forbidden in this component.
class SyncTimeRow extends StatelessWidget {
  const SyncTimeRow({
    required this.label,
    this.icon = LucideIcons.clock3,
    this.color,
    this.iconColor,
    super.key,
  });

  /// Already localized.
  final String label;
  final IconData icon;

  /// Defaults to `$text-primary`. Pass `$amber-text` past the 24 h threshold,
  /// or `$text-secondary` for the informative "never synced" case.
  final Color? color;

  /// Defaults to [color]. The detail sheet's "8 intentos de subida" keeps the
  /// glyph dimmer than its label, so the pair is separable.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final foreground = color ?? colors.textPrimary;

    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor ?? foreground),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ],
    );
  }
}
