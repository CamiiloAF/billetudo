import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';

/// The `Reminder Option Row` component (`vWslR`, `reusable:true`): one option
/// of the reminder picker sheet.
///
/// Follows MASTER's list-row pattern: the check sits on the right and the row
/// background is **never** tinted by selection. The whole 56px row is the tap
/// target, not the check.
///
/// [icon] carries a redundant signal so the state does not depend on the check
/// alone — `bell-off` on "Sin recordatorio", `bell` on every real option.
class ReminderOptionRow extends StatelessWidget {
  const ReminderOptionRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;

  /// Already localized.
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.muted,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: colors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 24,
                height: 24,
                child: selected
                    ? Icon(
                        LucideIcons.check,
                        size: 20,
                        color: colors.primaryOnSoft,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
