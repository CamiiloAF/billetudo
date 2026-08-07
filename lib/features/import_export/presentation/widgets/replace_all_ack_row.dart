import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The escalated-confirmation checkbox that gates "Reemplazar todo" (HU-04):
/// a single "OK" is never enough for a destructive, irreversible action.
/// Mirrors the auth feature's `DeleteOptInRow` shape without importing
/// across features.
class ReplaceAllAckRow extends StatelessWidget {
  const ReplaceAllAckRow({
    required this.text,
    required this.checked,
    required this.onTap,
    super.key,
  });

  /// Already localized.
  final String text;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      checked: checked,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: checked ? colors.expenseSoft : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: checked ? colors.expense : colors.border,
              width: checked ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: checked ? colors.expense : colors.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: checked ? colors.expense : colors.textSecondary,
                    width: 2,
                  ),
                ),
                child: checked
                    ? Icon(LucideIcons.check, size: 16, color: colors.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: checked ? colors.expenseText : colors.textPrimary,
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
