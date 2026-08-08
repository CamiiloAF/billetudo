import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/neutral_button.dart';
import '../../domain/entities/sync_state.dart';
import '../cubit/sync_status_state.dart';
import '../models/sync_screen_state.dart';
import '../utils/sync_freshness.dart';
import '../utils/sync_relative_time.dart';
import 'sync_hero.dart';
import 'sync_secondary_cta.dart';
import 'sync_time_row.dart';

/// Picks the [SyncHero] variant for the current screen state.
///
/// The hero is written from what the repository confirms, never from what the
/// user just tapped: while a retry runs, the copy still says the changes are
/// only on this phone, because until the server confirms, they are. Rewriting
/// it optimistically is the exact failure mode of the incident behind HU-08.
class SyncStatusHero extends StatelessWidget {
  const SyncStatusHero({
    required this.screenState,
    required this.state,
    required this.onRetry,
    required this.onSignIn,
    super.key,
  });

  final SyncScreenState screenState;
  final SyncStatusState state;
  final VoidCallback onRetry;
  final VoidCallback onSignIn;

  /// The CTA goes inert — never hidden — while something is actually moving
  /// or while there is nothing to move it over.
  bool get _ctaEnabled =>
      !state.isRetrying &&
      state.syncState != SyncState.syncing &&
      screenState != SyncScreenState.offline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final now = clock.now();
    final lastSyncedAt = state.snapshot.lastSyncedAt;
    final isStale = SyncFreshness.isStale(lastSyncedAt, now: now);
    final relative = lastSyncedAt == null
        ? null
        : SyncRelativeTime.since(l10n, lastSyncedAt, now: now);

    final timeRow = switch (screenState) {
      SyncScreenState.signedOut => SyncTimeRow(
          icon: LucideIcons.cloudOff,
          label: l10n.syncNoActiveSyncLabel,
          color: colors.textSecondary,
        ),
      _ when relative == null => SyncTimeRow(
          label: l10n.syncNeverSyncedLabel,
          color: colors.textSecondary,
        ),
      _ => SyncTimeRow(
          label: l10n.syncLastSyncLabel(relative),
          color: isStale ? colors.amberText : colors.textPrimary,
        ),
    };

    final syncCta = SyncSecondaryCta(
      label: _ctaEnabled ? l10n.syncSyncNowCta : _inertLabel(l10n),
      icon: _ctaEnabled ? LucideIcons.refreshCw : _inertIcon,
      onPressed: onRetry,
      enabled: _ctaEnabled,
    );

    return switch (screenState) {
      SyncScreenState.attention => SyncHero(
          attention: true,
          icon: LucideIcons.cloudAlert,
          iconColor: colors.amber,
          iconBackground: colors.surface,
          title: l10n.syncHeroAttentionTitle(state.pendingCount),
          kicker: relative == null
              ? l10n.syncHeroAttentionKickerNever
              : l10n.syncHeroAttentionKicker(relative),
          kickerColor: colors.amberText,
          body: l10n.syncHeroAttentionBody(state.pendingCount),
          // The 24 h threshold has no exception per state: an attention hero
          // whose last sync was five minutes ago is not the same story as one
          // that has been silent for three days, and burning the amber on the
          // first would stop it meaning anything on the second.
          timeRow: timeRow,
          cta: NeutralButton(
            label: _ctaEnabled ? l10n.syncRetryNowCta : _inertLabel(l10n),
            icon: _ctaEnabled ? LucideIcons.refreshCw : _inertIcon,
            onPressed: onRetry,
            enabled: _ctaEnabled,
          ),
        ),
      // Amber like `attention`, but its own copy: nothing is held back here,
      // so the attention wording ("N changes live only on this phone") would
      // be false. What is at risk is what the user records *from now on*.
      // The CTA is "Sincronizar ahora", not "Reintentar": there were no
      // failed attempts to retry.
      SyncScreenState.stale => SyncHero(
          attention: true,
          icon: LucideIcons.cloudOff,
          iconColor: colors.amber,
          iconBackground: colors.surface,
          title: l10n.syncHeroStaleTitle,
          // The kicker says what distinguishes this state — nothing is held
          // back — instead of repeating the timestamp the row below already
          // carries. And it stays neutral: the good news here is that there
          // is no backlog; what deserves amber is the silence, which is what
          // the time row shows.
          kicker: l10n.syncHeroSyncedKicker,
          body: l10n.syncHeroStaleBody,
          // Amber here too, but derived — not pinned. This state *is* older
          // than 24 h by definition, so the shared row already resolves to
          // amber; hardcoding it would leave two sources of truth for the
          // same threshold.
          timeRow: timeRow,
          cta: syncCta,
        ),
      SyncScreenState.healthy => SyncHero(
          icon: LucideIcons.cloudCheck,
          iconColor: colors.mint,
          iconBackground: colors.mintSoft,
          title: l10n.syncHeroSyncedTitle,
          kicker: l10n.syncHeroSyncedKicker,
          body: l10n.syncHeroSyncedBody,
          timeRow: timeRow,
          cta: syncCta,
        ),
      SyncScreenState.neverSynced => SyncHero(
          icon: LucideIcons.cloudUpload,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: l10n.syncHeroNeverTitle,
          kicker: l10n.syncHeroNeverKicker,
          body: l10n.syncHeroNeverBody,
          timeRow: timeRow,
          cta: syncCta,
        ),
      SyncScreenState.offline => SyncHero(
          icon: LucideIcons.cloudOff,
          iconColor: colors.textSecondary,
          iconBackground: colors.muted,
          title: l10n.syncHeroOfflineTitle,
          kicker: l10n.syncHeroOfflineKicker,
          body: l10n.syncHeroOfflineBody,
          caption: l10n.syncHeroOfflineCaption,
          timeRow: timeRow,
          cta: syncCta,
        ),
      SyncScreenState.signedOut => SyncHero(
          icon: LucideIcons.userRoundX,
          iconColor: colors.textSecondary,
          iconBackground: colors.muted,
          title: l10n.syncHeroSignedOutTitle,
          kicker: l10n.syncHeroSignedOutKicker,
          body: l10n.syncHeroSignedOutBody,
          timeRow: timeRow,
          cta: FilledButton.icon(
            onPressed: onSignIn,
            icon: const Icon(LucideIcons.cloudUpload, size: 18),
            label: Text(l10n.syncSignInCta),
          ),
        ),
    };
  }

  /// Two signals at once, neither of them chromatic: the glyph changes and so
  /// does the label.
  String _inertLabel(AppLocalizations l10n) =>
      state.isRetrying || state.syncState == SyncState.syncing
          ? l10n.syncSyncingCta
          : l10n.syncSyncNowCta;

  IconData get _inertIcon =>
      state.isRetrying || state.syncState == SyncState.syncing
          ? LucideIcons.loaderCircle
          : LucideIcons.refreshCw;
}
