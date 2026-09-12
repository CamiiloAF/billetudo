import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// `oKokr` — "Sugerida: {categoría}", a proposal, never a confirmed fact
/// (category stays required at confirmation). Deliberately not the 44px
/// colored circle a real `TransactionRow` uses for its category: that circle
/// is the visual signature of an ALREADY-REGISTERED movement, and giving it
/// to a capture would spend the strongest signal that tells the two apart.
class SuggestedCategoryChip extends StatelessWidget {
  const SuggestedCategoryChip({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.tag, size: 12, color: colors.textSecondary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              AppLocalizations.of(context).captureSuggestedCategoryLabel(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
