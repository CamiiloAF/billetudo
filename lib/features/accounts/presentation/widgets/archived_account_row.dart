import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/account_with_balance.dart';
import 'account_card.dart';

/// The `Archived Account Row` component: an [AccountCard] and its "Desarchivar"
/// footer inside **one** visual container (HU-07).
///
/// They were separate at first and the footer read as orphaned, disconnected
/// from the card it acted on.
class ArchivedAccountRow extends StatelessWidget {
  const ArchivedAccountRow({
    required this.entry,
    required this.onUnarchive,
    super.key,
  });

  final AccountWithBalance entry;
  final VoidCallback onUnarchive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(AppTheme.radiusLarge);

    return Container(
      decoration: BoxDecoration(color: colors.surface, borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AccountCard(entry: entry),
          Divider(height: 1, color: colors.border),
          InkWell(
            onTap: onUnarchive,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.unarchive_outlined,
                    size: 18,
                    // `primary-on-soft` even over `$surface`: plain `primary`
                    // drops to ~3:1 in dark mode (MASTER.md).
                    color: colors.primaryOnSoft,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.accountsUnarchive,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.primaryOnSoft,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
