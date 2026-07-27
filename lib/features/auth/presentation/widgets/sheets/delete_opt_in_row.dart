import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';

/// The `Delete Opt-in Row` component (`S533j9`): the checkbox that turns
/// "Cerrar sesión" into "Cerrar sesión y borrar este teléfono" (HU-06).
///
/// Not a `LocalDataChoiceRow`: that one is a pair of exclusive radios with no
/// default (HU-07 paso 2). Here wiping is a *modifier* of signing out, so it
/// is a single opt-in that starts off. The two were deliberately not unified.
///
/// Two rules from the component's contract, both easy to break by accident:
/// - **The tap target is the whole row**, never the 24x24 box — 24px misses
///   MASTER's 44px minimum.
/// - **The state is carried by three redundant signals** (box fill, the
///   `check` glyph, and a 2px border), not by colour alone (WCAG 1.4.1).
class DeleteOptInRow extends StatelessWidget {
  const DeleteOptInRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Already localized.
  final String title;

  /// Already localized.
  final String subtitle;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      checked: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? colors.expenseSoft : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.expense : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DeleteOptInCheckbox(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color:
                            selected ? colors.expenseText : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 24x24 box of [DeleteOptInRow]. Purely decorative: it has no gesture of
/// its own on purpose — the whole row is the target.
class DeleteOptInCheckbox extends StatelessWidget {
  const DeleteOptInCheckbox({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? colors.expense : colors.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected ? colors.expense : colors.textSecondary,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(LucideIcons.check, size: 16, color: colors.onPrimary)
          : null,
    );
  }
}
