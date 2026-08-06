import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// The `Nota interés` strip (HU-02): a debt's interest lowers net worth but
/// never shows in Flujo, since it is not cash leaving an account.
class NetWorthInterestNote extends StatelessWidget {
  const NetWorthInterestNote({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 16, color: colors.hintText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.reportsNetWorthInterestNote,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.hintText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
