import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Privacy Note Strip` component (`YAUFx`): a `$muted` pill carrying a
/// `lock` icon and the HU-03 privacy disclaimer — the copy goes unencrypted
/// and without the account number, said once, without alarm.
class PrivacyNoteStrip extends StatelessWidget {
  const PrivacyNoteStrip({
    required this.text,
    this.icon = LucideIcons.lock,
    this.iconColor,
    this.textColor,
    this.background,
    super.key,
  });

  /// Already localized.
  final String text;

  /// `null` keeps the component's own default (`lock`) — the HU-06 "plantilla
  /// reconocida" banner (`HBdCo`/`lHG0E`) overrides to `badge-check` via
  /// `descendants`, same component reused, not a new one.
  final IconData icon;
  final Color? iconColor;
  final Color? textColor;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: background ?? colors.muted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor ?? colors.textPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: textColor ?? colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
