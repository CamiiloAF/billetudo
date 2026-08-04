import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The `Button/Neutral` component (`xncgz`): a solid, high-contrast CTA with
/// no brand colour — `$text-primary` fill, `$background` label and glyph.
///
/// It weighs the same as `Button/Primary`; it is not a lesser or disabled
/// button. Use it where `$primary` already carries a meaning that tinting the
/// CTA violet would blur — in "Estado de sincronización" the violet means
/// *the cloud*, so no sync action may wear it.
///
/// [enabled] renders the inert treatment the design contracts (`z6MVC`):
/// `$muted` fill, the `$border` stroke **kept** (without it the button loses
/// its shape) and label/glyph in `$segment-inactive-text`. Never opacity —
/// MASTER forbids encoding "off" as transparency. The button stays in place
/// instead of disappearing, so the layout does not shift between states.
class NeutralButton extends StatelessWidget {
  const NeutralButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  /// Already localized.
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final foreground = enabled ? colors.background : colors.segmentInactiveText;
    final radius = BorderRadius.circular(AppTheme.radiusMedium);

    return Material(
      color: enabled ? colors.textPrimary : colors.muted,
      borderRadius: radius,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: enabled ? null : Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: foreground,
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
