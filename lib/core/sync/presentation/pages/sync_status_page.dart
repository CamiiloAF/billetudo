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
        // A plain `SnackBar` (no `action`) auto-hides on its own; one with a
        // `SnackBarAction` — this one — does not, in the Flutter version this
        // app builds against: `ScaffoldMessengerState`'s internal dismiss
        // timer is only (re)armed by a `setState` its `SnackBar`'s entrance
        // `AnimationController` triggers on completion, and that path never
        // fires here once an action is present, confirmed against a bare
        // `MaterialApp`/`SnackBarAction` reproduction with no app code
        // involved. The user hit exactly this: the "Sigue guardado en este
        // teléfono" snackbar (the only one with an action) stayed up
        // forever, while the plain "Todo al día" one always closed itself.
        // Driving the hide explicitly sidesteps the SDK's broken timer
        // instead of depending on it.
        final controller = messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.syncRetryPartial),
            action: SnackBarAction(
              label: l10n.syncRetryPartialAction,
              onPressed: onSeeAllPending,
            ),
          ),
        );
        // `SnackBar`'s default duration (4s) is private to `snack_bar.dart`,
        // so it is repeated here explicitly.
        //
        // Guarding on `context.mounted` here was wrong: that is
        // `SyncStatusPage`'s context, but the `SnackBar` lives in the
        // `ScaffoldMessenger` above the `Navigator` (`MaterialApp` inserts
        // it there by default), which survives navigating back from this
        // page. With `context.mounted`, popping back before the 4s deadline
        // left the snackbar stuck forever — the `Timer` bailed out on a
        // widget that was never the one holding the snackbar. `messenger`
        // is a `State` (`ScaffoldMessengerState`), so its own `mounted`
        // reflects whether it — and therefore the snackbar — is still
        // around.
        Timer(const Duration(milliseconds: 4000), () {
          if (!messenger.mounted) {
            return;
          }
          // `messenger.mounted` only proves the `ScaffoldMessengerState`
          // itself is still alive, not that *this* snackbar is still the
          // one it is showing. A burst of partial retries in a row (real
          // logcat: several in a row, seconds apart) calls
          // `hideCurrentSnackBar()` again on line above before this old
          // `Timer` gets to fire. There is no public API to ask "is this
          // still the active snackbar" before calling `close()`, and
          // `ScaffoldFeatureController.close()`'s own internal check —
          // `assert(_snackBars.first == controller)` inside
          // `ScaffoldMessengerState.showSnackBar` — fails in one of two
          // ways depending on timing, neither guarded before it runs:
          // `_snackBars` can be completely empty by then (`ListQueue.first`
          // throws `StateError: Bad state: No element`, the exact crash
          // from the field) or non-empty but already pointing at the
          // *next* snackbar (the `assert` itself throws `AssertionError`,
          // only possible in debug/test builds — release builds strip
          // asserts, so this second branch cannot fire in production, but
          // is still worth swallowing here so it doesn't flake this app's
          // own debug runs or widget tests). Both mean the same thing: the
          // snackbar this `Timer` was guarding is already gone, which is
          // the outcome it wanted anyway.
          try {
            controller.close();
            // ignore: avoid_catching_errors
          } on StateError {
            // Queue was already empty — nothing left to close.
          }
          // ignore: avoid_catching_errors
          on AssertionError {
            // Queue now points at a newer snackbar — nothing left to close.
          }
        });
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
