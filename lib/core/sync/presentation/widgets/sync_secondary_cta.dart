import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// The hero's low-weight CTA: `Button/Secondary` (`pNjOz`) kept **entirely
/// neutral** — `$surface` fill, `$border` stroke, label and glyph in
/// `$text-primary`.
///
/// A violet glyph here was evaluated and reverted by the user; do not
/// reintroduce it. The hierarchy between "repair" (solid `NeutralButton`) and
/// "force" (this hollow one) is encoded by weight alone, so it survives
/// greyscale.
///
/// Inert (`enabled: false`) it keeps its place with `$muted` fill, its border
/// and `$segment-inactive-text` label: removing the button would shift the
/// layout between states, and never dimmed with opacity.
class SyncSecondaryCta extends StatelessWidget {
  const SyncSecondaryCta({
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
    final foreground =
        enabled ? colors.textPrimary : colors.segmentInactiveText;
    final radius = BorderRadius.circular(AppTheme.radiusMedium);

    return Material(
      color: enabled ? colors.surface : colors.muted,
      borderRadius: radius,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.border),
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
