import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/page_header.dart';
import '../cubit/sync_status_cubit.dart';
import '../cubit/sync_status_state.dart';
import '../utils/sync_relative_time.dart';
import '../widgets/discard_all_link.dart';
import '../widgets/sheets/confirm_discard_all_quarantined_changes_sheet.dart';
import '../widgets/sheets/pending_change_detail_sheet.dart';
import '../widgets/sync_pending_row.dart';

/// "Cambios sin subir" (`rxUil`): the full list, reached from the counted link
/// of the attention state.
///
/// This is the one screen of the family where scrolling is expected — on the
/// status screen the risk and "Guardar una copia" have to fit without it.
///
/// No selection and no per-row bulk actions: the hero's "Reintentar ahora"
/// already replays the whole queue, and there is no "Descartar" on individual
/// rows here (that lives only in the detail sheet, gated by `attempts >= 3`).
/// The one bulk action this screen does offer is "Descartar todo" (`OgoAn`),
/// a link under the summary line — added 2026-08-25 for the case where
/// discarding one write at a time is not viable (hundreds in quarantine).
/// Unlike the per-row discard it has no threshold, and is protected only by
/// its own confirmation sheet. The amber is not repeated here either — the
/// previous hero already said it, and repeating an alarm on every surface
/// turns it into noise.
class PendingSyncChangesPage extends StatelessWidget {
  const PendingSyncChangesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.syncPendingListTitle),
            Expanded(
              child: BlocBuilder<SyncStatusCubit, SyncStatusState>(
                builder: (context, state) {
                  final changes = state.pending;
                  final oldest = changes.isEmpty
                      ? null
                      : SyncRelativeTime.since(
                          l10n,
                          changes.first.pendingSince,
                          now: clock.now(),
                        );

                  // Reaching this screen with nothing waiting is good news, so
                  // it gets a composed empty state (`wcrqA`/`Z1ws4n`) instead
                  // of the bare grey line it used to render — which read as an
                  // unfinished screen, and is a shape no other surface of the
                  // product uses. No CTA: there is no action to take, and
                  // "Volver" would duplicate the header's back arrow. No amber
                  // either: in this family amber means something is waiting.
                  if (changes.isEmpty) {
                    return Center(
                      child: EmptyState(
                        icon: LucideIcons.cloudCheck,
                        message: l10n.syncPendingEmptyMessage,
                        description: l10n.syncPendingEmptyDescription,
                      ),
                    );
                  }

                  final cubit = context.read<SyncStatusCubit>();

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                    itemCount: changes.length + 2,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Text(
                          oldest == null
                              ? l10n.syncHeroSyncedKicker
                              : l10n.syncPendingListSummary(
                                  changes.length,
                                  oldest,
                                ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: colors.textSecondary,
                          ),
                        );
                      }
                      if (index == 1) {
                        return DiscardAllLink(
                          count: changes.length,
                          onTap: () => unawaited(
                            _discardAll(context, cubit, changes.length),
                          ),
                        );
                      }
                      final change = changes[index - 2];
                      return SyncPendingRow(
                        change: change,
                        onTap: () => unawaited(
                          PendingChangeDetailSheet.show(
                            context,
                            cubit,
                            change,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the bulk confirmation sheet and, once confirmed, empties the
  /// quarantine. Same fire-and-forget shape as the per-row discard: the rows
  /// disappear as the quarantine stream confirms the deletion, not
  /// optimistically.
  Future<void> _discardAll(
    BuildContext context,
    SyncStatusCubit cubit,
    int count,
  ) async {
    final confirmed = await ConfirmDiscardAllQuarantinedChangesSheet.show(
      context,
      count: count,
    );
    if (confirmed != true) {
      return;
    }
    unawaited(cubit.discardAll());
  }
}
