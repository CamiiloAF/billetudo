import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/data_action_row.dart';
import '../../../widgets/page_header.dart';
import '../cubit/sync_status_cubit.dart';
import '../cubit/sync_status_state.dart';
import '../models/pending_sync_change.dart';
import '../models/sync_screen_state.dart';
import '../widgets/sheets/pending_change_detail_sheet.dart';
import '../widgets/sync_diagnostics_section.dart';
import '../widgets/sync_hero_skeleton.dart';
import '../widgets/sync_pending_section.dart';
import '../widgets/sync_section_header.dart';
import '../widgets/sync_skeleton_row.dart';
import '../widgets/sync_status_hero.dart';

/// "Estado de sincronización" (HU-08): the screen that exists so "syncing" and
/// "syncing for three days" can never look the same again.
///
/// It never asks the network to paint itself — it reads the local queue — so
/// it has no error state of its own, and its skeleton covers SQLite latency
/// only.
///
/// [isSignedIn] arrives from above instead of being watched here: the sync
/// core must not depend on the auth feature, and the router already knows the
/// session.
class SyncStatusPage extends StatelessWidget {
  const SyncStatusPage({
    required this.isSignedIn,
    required this.onSaveCopy,
    required this.onSignIn,
    required this.onSeeAllPending,
    required this.onOpenComingSoon,
    super.key,
  });

  final bool isSignedIn;

  /// Navigates to "Importar y exportar" — this screen never opens a copy sheet
  /// of its own, so the two surfaces cannot drift apart on the wording that
  /// keeps *copy* (file) and *backup* (cloud) distinct.
  final VoidCallback onSaveCopy;

  final VoidCallback onSignIn;
  final VoidCallback onSeeAllPending;
  final ValueChanged<String> onOpenComingSoon;

  void _openDetail(BuildContext context, PendingSyncChange change) {
    unawaited(
      PendingChangeDetailSheet.show(
        context,
        context.read<SyncStatusCubit>(),
        change,
      ),
    );
  }

  void _onRetryOutcome(BuildContext context, SyncStatusState state) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (state.retryOutcome) {
      case SyncRetryOutcome.allUploaded:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.syncRetrySuccess(state.retriedCount))),
        );
      case SyncRetryOutcome.partial:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.syncRetryPartial),
            action: SnackBarAction(
              label: l10n.syncRetryPartialAction,
              onPressed: onSeeAllPending,
            ),
          ),
        );
      case SyncRetryOutcome.none:
        break;
    }
    context.read<SyncStatusCubit>().acknowledgeRetryOutcome();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.syncStatusTitle),
            Expanded(
              child: BlocConsumer<SyncStatusCubit, SyncStatusState>(
                listenWhen: (previous, current) =>
                    previous.retryOutcome != current.retryOutcome &&
                    current.retryOutcome != SyncRetryOutcome.none,
                listener: _onRetryOutcome,
                builder: (context, state) {
                  if (state.isLoading) {
                    return const SyncStatusSkeleton();
                  }
                  final screenState = SyncScreenState.resolve(
                    state,
                    isSignedIn: isSignedIn,
                    now: clock.now(),
                  );
                  final cubit = context.read<SyncStatusCubit>();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                    children: [
                      SyncStatusHero(
                        screenState: screenState,
                        state: state,
                        onRetry: () => unawaited(cubit.retryAll()),
                        onSignIn: onSignIn,
                      ),
                      const SizedBox(height: 16),
                      // In the attention states the copy row answers, right
                      // there, the risk the hero just named — it does not wait
                      // its turn inside the diagnostics section.
                      // `attention` only, not `isAttention`: `stale` shares the
                      // amber but has nothing held back, so the pending list
                      // would render an empty section under a header, and the
                      // copy row would read "Esos 0 cambios viven solo aquí".
                      if (screenState == SyncScreenState.attention) ...[
                        DataActionRow(
                          icon: LucideIcons.hardDriveDownload,
                          iconColor: colors.teal,
                          iconBackground: colors.tealSoft,
                          title: l10n.syncSaveCopyTitle,
                          description: l10n.syncSaveCopyDescriptionAttention(
                            state.pendingCount,
                          ),
                          onTap: onSaveCopy,
                        ),
                        const SizedBox(height: 16),
                        SyncPendingSection(
                          changes: state.pending,
                          onOpenChange: (change) =>
                              _openDetail(context, change),
                          onSeeAll: onSeeAllPending,
                        ),
                        const SizedBox(height: 16),
                        SyncDiagnosticsSection(
                          title: l10n.syncSectionDiagnostics,
                          showExcel: false,
                          onOpenComingSoon: onOpenComingSoon,
                        ),
                      ] else if (screenState == SyncScreenState.stale) ...[
                        // Same offer, different reason: nothing is held back
                        // yet, but anything recorded from now on will be.
                        DataActionRow(
                          icon: LucideIcons.hardDriveDownload,
                          iconColor: colors.teal,
                          iconBackground: colors.tealSoft,
                          title: l10n.syncSaveCopyTitle,
                          description: l10n.syncSaveCopyDescriptionStale,
                          onTap: onSaveCopy,
                        ),
                        const SizedBox(height: 16),
                        SyncDiagnosticsSection(
                          title: l10n.syncSectionDiagnostics,
                          showExcel: false,
                          onOpenComingSoon: onOpenComingSoon,
                        ),
                      ] else if (screenState == SyncScreenState.signedOut) ...[
                        SyncSectionHeader(title: l10n.syncSectionMeanwhile),
                        const SizedBox(height: 10),
                        DataActionRow(
                          icon: LucideIcons.hardDriveDownload,
                          iconColor: colors.teal,
                          iconBackground: colors.tealSoft,
                          title: l10n.syncSaveCopyTitle,
                          description: l10n.syncSaveCopyDescriptionSignedOut,
                          chipLabel: l10n.syncSaveCopyChip,
                          onTap: onSaveCopy,
                        ),
                      ] else ...[
                        SyncSectionHeader(
                          title: l10n.syncSectionBackupAndDiagnostics,
                        ),
                        const SizedBox(height: 10),
                        DataActionRow(
                          icon: LucideIcons.hardDriveDownload,
                          iconColor: colors.teal,
                          iconBackground: colors.tealSoft,
                          title: l10n.syncSaveCopyTitle,
                          description: l10n.syncSaveCopyDescription,
                          chipLabel: l10n.syncSaveCopyChip,
                          onTap: onSaveCopy,
                        ),
                        const SizedBox(height: 10),
                        SyncDiagnosticsSection(
                          showExcel: true,
                          onOpenComingSoon: onOpenComingSoon,
                        ),
                      ],
                    ],
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

/// The loading face of [SyncStatusPage] (`KgGHB`): hero skeleton, a section
/// header block and three rows with the real row geometry.
class SyncStatusSkeleton extends StatelessWidget {
  const SyncStatusSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      children: const [
        SyncHeroSkeleton(),
        SizedBox(height: 16),
        // Left-aligned on purpose: as a direct `ListView` child the block gets
        // a tight cross-axis constraint and stretches to the full width, which
        // reads as a paragraph instead of the section header word it stands in
        // for (`m85JY`, 150×15).
        Align(
          alignment: Alignment.centerLeft,
          child: SyncSkeletonBlock(width: 150, height: 15),
        ),
        SizedBox(height: 10),
        SyncSkeletonRow(),
        SizedBox(height: 10),
        SyncSkeletonRow(firstLineWidth: 210, secondLineWidth: 96),
        SizedBox(height: 10),
        SyncSkeletonRow(firstLineWidth: 150, secondLineWidth: 124),
      ],
    );
  }
}
