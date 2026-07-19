import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// An action row inside a `Bottom Sheet Base` sheet (`PqTUt`): a neutral
/// `$muted` icon-wrap (38pt, radius 12), a 15/600 title and an optional 12/500
/// subtitle, in a `[13, 4]` padded row.
///
/// This is the shape every option sheet of the app uses, so a menu never falls
/// back to a Material `PopupMenuButton` (which brings its own radius, border
/// and elevation, all outside the palette).
///
/// Two shapes exist in `billetudo.pen`, both with the same type scale: the
/// default one with the `$muted` icon-wrap (list menus, e.g. `TmOGV`) and the
/// [SheetActionRow.bare] one, a plain 20pt icon in a `[14, 4]` row (detail
/// menus, e.g. `G26c4T`).
class SheetActionRow extends StatelessWidget {
  const SheetActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.foreground,
    super.key,
  }) : _bare = false;

  /// The wrap-less variant (`G26c4T/Jp1Pn`): no icon-wrap, 20pt icon, `[14, 4]`
  /// padding and no subtitle.
  const SheetActionRow.bare({
    required this.icon,
    required this.title,
    required this.onTap,
    this.foreground,
    super.key,
  })  : subtitle = null,
        _bare = true;

  final IconData icon;

  /// Already localized.
  final String title;

  /// Already localized. `null` renders a single-line row.
  final String? subtitle;

  final VoidCallback onTap;

  /// Overrides the icon and title color; used by destructive actions, which
  /// wear the semantic `expense` family.
  final Color? foreground;

  final bool _bare;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final tint = foreground ?? colors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: _bare ? 14 : 13,
          horizontal: 4,
        ),
        child: Row(
          children: [
            if (_bare)
              Icon(icon, size: 20, color: tint)
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: tint),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tint,
                    ),
                  ),
                  if (subtitle case final subtitle?) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The head of an option sheet (`TmOGV/N03UGA`): the screen's name plus the
/// "Opciones" subtitle, left-aligned above the rows.
class SheetActionsHead extends StatelessWidget {
  const SheetActionsHead({
    required this.title,
    required this.subtitle,
    super.key,
  });

  /// Already localized.
  final String title;

  /// Already localized.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            // The title can be user content (the budget's own name), so it
            // stays on one line instead of pushing the rows down.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
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
    );
  }
}
