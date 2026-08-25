import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';

/// "Descartar todo (N)" (`CXdn5`, inside `OgoAn`): the entry point for the
/// bulk discard on the full pending list (`rxUil`).
///
/// Same visual weight as the rest of this family's secondary links (700,
/// `trash-2` at 15px), but `$expense-text` instead of `$text-primary` — this
/// one is a real destructive action, unlike "Ver los N pendientes". No
/// threshold gates it: it is visible whenever there is at least one pending
/// change, protected only by the confirmation sheet the caller opens on tap.
class DiscardAllLink extends StatelessWidget {
  const DiscardAllLink({required this.count, required this.onTap, super.key});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.trash2, size: 15, color: colors.expenseText),
              const SizedBox(width: 4),
              Text(
                l10n.syncDiscardAllLinkLabel(count),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.expenseText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
