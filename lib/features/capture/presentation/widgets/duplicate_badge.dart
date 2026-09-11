import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// `v7U26p` — the "Posible duplicado" pill.
///
/// `$amber-soft`/`$amber-text` (4.70:1, passes AA for 11/700) — attention,
/// never alarm, and never `$expense`, which here would read as an accusation
/// about something the user has not even done yet. Keeps the "Posible": HU-07
/// is heuristic and the app never asserts a duplicate on its own.
class DuplicateBadge extends StatelessWidget {
  const DuplicateBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.amberSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.gitCompare, size: 12, color: colors.amberText),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context).captureDuplicatePill,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.amberText,
                ),
          ),
        ],
      ),
    );
  }
}
