import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The `Notice Card · Con acción` component (`cYVQm`, `reusable:true`): one
/// card of the notice centre's "Avisos" section.
///
/// **Always carries a direct action.** A notice that only informs wastes the
/// moment of attention it just bought, so this component has no
/// "chevron-only" mode — that is a different component.
///
/// **No orb, no AI language anywhere.** These are figures the app computed
/// from the user's own data, not a model's output; lending them the
/// assistant's visual identity would blur what each surface can actually do.
///
/// Tone: inform and enable, never alarm. "Netflix se cobra en 3 días" is a
/// fact and a date; it never warns and never implies the user cannot afford
/// it.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  /// Already localized.
  final String title;

  /// Already localized.
  final String subtitle;

  /// Already localized.
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

  /// Already localized. `null` renders the card with the primary action
  /// alone — the frame's "meta alcanzada" case, where there is nothing
  /// sensible to postpone.
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final secondaryActionLabel = this.secondaryActionLabel;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                decoration: BoxDecoration(
                  color: iconBackground,
                  // 12, tighter than the card's own 16 (`o0U86y`): the wrap
                  // is not a small card, it nests inside one.
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The title wraps (the frame's own copy runs to two
                    // lines) but the subtitle does not: a long template name
                    // must not push the actions off the card.
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: NoticeCardAction(
                  label: primaryActionLabel,
                  onPressed: onPrimaryAction,
                  background: colors.primary,
                  foreground: colors.onPrimary,
                ),
              ),
              if (secondaryActionLabel != null &&
                  onSecondaryAction != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: NoticeCardAction(
                    label: secondaryActionLabel,
                    onPressed: onSecondaryAction!,
                    background: colors.muted,
                    foreground: colors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One button of a [NoticeCard]'s action row (`l30zH`/`goqj0`).
///
/// 44px tall on both variants — the frame is explicit that the secondary
/// action is a full tap target too, not a text link.
class NoticeCardAction extends StatelessWidget {
  const NoticeCardAction({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    super.key,
  });

  /// Already localized.
  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppTheme.radiusField);

    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
