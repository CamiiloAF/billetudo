import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../models/pending_sync_change.dart';
import 'sync_pending_row.dart';
import 'sync_section_header.dart';

/// "Qué está esperando": a **sample** of the queue, never a summary.
///
/// From 3 to 89 held-back changes the list does not grow — it stays at the
/// three that have been waiting longest, with a counted link into the full
/// screen. Measured reason: with the list expanded, "Guardar una copia" — the
/// only protection that works while the cloud is failing — falls below the
/// fold exactly when it matters most. The counter deliberately lives in two
/// places (the hero's title and this link): "Ver todos" alone would not say
/// how many are missing.
class SyncPendingSection extends StatelessWidget {
  const SyncPendingSection({
    required this.changes,
    required this.onOpenChange,
    required this.onSeeAll,
    super.key,
  });

  /// The whole queue, oldest first. Only [visibleLimit] of them are rendered.
  final List<PendingSyncChange> changes;
  final ValueChanged<PendingSyncChange> onOpenChange;
  final VoidCallback onSeeAll;

  static const int visibleLimit = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible = changes.take(visibleLimit).toList();
    final hasMore = changes.length > visibleLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SyncSectionHeader(
          title: l10n.syncSectionPending,
          linkLabel:
              hasMore ? l10n.syncSectionPendingLink(changes.length) : null,
          onLinkTap: hasMore ? onSeeAll : null,
        ),
        for (final change in visible) ...[
          const SizedBox(height: 10),
          SyncPendingRow(
            change: change,
            onTap: () => onOpenChange(change),
          ),
        ],
      ],
    );
  }
}
