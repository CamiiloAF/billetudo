import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/page_header.dart';
import '../cubit/sync_status_cubit.dart';
import '../cubit/sync_status_state.dart';
import '../utils/sync_relative_time.dart';
import '../widgets/sheets/pending_change_detail_sheet.dart';
import '../widgets/sync_pending_row.dart';

/// "Cambios sin subir" (`rxUil`): the full list, reached from the counted link
/// of the attention state.
///
/// This is the one screen of the family where scrolling is expected — on the
/// status screen the risk and "Guardar una copia" have to fit without it.
///
/// No bulk actions and no selection: the hero's "Reintentar ahora" already
/// replays the whole queue, and there is no "Descartar" anywhere in this flow.
/// Each row opens its own detail. The amber is not repeated here either — the
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
                          now: DateTime.now(),
                        );

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                    itemCount: changes.length + 1,
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
                      final change = changes[index - 1];
                      return SyncPendingRow(
                        change: change,
                        onTap: () => unawaited(
                          PendingChangeDetailSheet.show(
                            context,
                            context.read<SyncStatusCubit>(),
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
}
