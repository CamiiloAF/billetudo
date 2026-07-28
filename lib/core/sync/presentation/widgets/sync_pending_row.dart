import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../models/pending_sync_change.dart';

/// `Sync Pending Row` (`VtiBc`): one write that has not reached the cloud.
///
/// Tone: this is a **pending** change, not a user error and not lost data —
/// hence `$amber`/`$amber-soft`, attention without blame, and never
/// `$expense`.
///
/// Text contract: the title names the row in the user's language (kind + its
/// description), never a table name or an error code. The meta line carries
/// how long it has been waiting and how many attempts it took — the datum
/// whose absence let three days go unnoticed. Both are one line with an
/// ellipsis: a real movement note is far longer than the mockup's.
///
/// The **whole row** is the tap target (≥72pt) and it opens the change's
/// detail sheet; the chevron is not the target. There is deliberately no
/// "Discard": nothing here destroys data that only exists on this phone.
class SyncPendingRow extends StatelessWidget {
  const SyncPendingRow({required this.change, required this.onTap, super.key});

  final PendingSyncChange change;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final radius = BorderRadius.circular(AppTheme.radiusMedium);
    final kind = change.kind.label(l10n);
    final title = change.label == null
        ? kind
        : l10n.syncPendingRowTitle(kind, change.label!);

    return Material(
      color: colors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.amberSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(change.kind.icon, size: 20, color: colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.syncPendingRowMeta(
                        change.attempts,
                        DateFormat.MMMd(locale).format(change.pendingSince),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(LucideIcons.chevronRight, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
