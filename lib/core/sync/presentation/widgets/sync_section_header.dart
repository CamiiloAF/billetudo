import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';

/// `Section Header` (`E2pvO`) as this feature uses it: 15/700 title and an
/// optional trailing link.
///
/// The link is **neutral, not violet**. `E2pvO` ships it in
/// `$primary-on-soft`, but on this screen violet means "the cloud" — a violet
/// navigation link would put the colour exactly where it says nothing.
class SyncSectionHeader extends StatelessWidget {
  const SyncSectionHeader({
    required this.title,
    this.linkLabel,
    this.onLinkTap,
    super.key,
  });

  /// Already localized.
  final String title;

  /// Already localized. `null` renders the title alone.
  final String? linkLabel;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final linkLabel = this.linkLabel;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (linkLabel != null && onLinkTap != null)
          InkWell(
            onTap: onLinkTap,
            child: Padding(
              // 15pt vertical over a 18pt line makes the 48pt tap target the
              // design contracts for this link.
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    linkLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 15,
                    color: colors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
