import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Privacy Note Strip` component (`YAUFx`): a `$muted` pill carrying a
/// `lock` icon and the HU-03 privacy disclaimer — the copy goes unencrypted
/// and without the account number, said once, without alarm.
class PrivacyNoteStrip extends StatelessWidget {
  const PrivacyNoteStrip({required this.text, super.key});

  /// Already localized.
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.lock, size: 16, color: colors.textPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
