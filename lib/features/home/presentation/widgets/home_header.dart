import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../cubit/home_state.dart';

/// The Home header (HU-07/HU-10): avatar + greeting, a passive sync indicator
/// and the notifications bell.
///
/// Local-first: with no session the greeting is generic and the avatar is a
/// neutral person icon — it never blocks or nags. With a session it greets by
/// name and the avatar shows the name's initial (the design uses an initial,
/// not a network photo). The sync indicator is informative only (not a tap
/// target).
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.syncStatus,
    required this.onBellTap,
    this.user,
    super.key,
  });

  final HomeSyncStatus syncStatus;
  final VoidCallback onBellTap;

  /// The signed-in user, or null when local-first with no session (HU-07).
  final AuthUser? user;

  /// The uppercase initial of the display name, or null when it can't be
  /// derived (no session, or a blank name) — then the avatar falls back to the
  /// person icon.
  String? get _initial {
    final name = user?.displayName.trim() ?? '';
    return name.isEmpty ? null : name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final initial = _initial;
    final greeting = user != null
        ? l10n.homeGreetingNamed(user!.displayName.split(' ').first)
        : l10n.homeGreeting;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, colors.primaryDeep],
            ),
            shape: BoxShape.circle,
          ),
          child: initial != null
              ? Text(
                  initial,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Icon(LucideIcons.user, color: colors.onPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            greeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        SyncIndicator(status: syncStatus),
        const SizedBox(width: 4),
        IconButton(
          onPressed: onBellTap,
          tooltip: l10n.homeNotificationsTooltip,
          style: IconButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.textPrimary,
          ),
          icon: const Icon(LucideIcons.bell),
        ),
      ],
    );
  }
}

/// The discreet sync-status icon (HU-10). Passive: it carries a semantics
/// label but is not interactive.
///
/// While syncing, the refresh icon rotates so the user can tell something is
/// happening (notably during the post-login merge, where a static "synced"
/// icon read as the app being stuck). Stateful only for that rotation.
class SyncIndicator extends StatefulWidget {
  const SyncIndicator({required this.status, super.key});

  final HomeSyncStatus status;

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator>
    with SingleTickerProviderStateMixin {
  /// One turn every 2s: slow enough to read as calm progress rather than an
  /// alarm, fast enough to be visibly moving at 20px.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  /// False when the OS asks for reduced motion (MASTER.md accessibility): the
  /// icon then stays static and only the semantics label reports progress.
  bool _motionAllowed = true;

  bool get _shouldSpin =>
      widget.status == HomeSyncStatus.syncing && _motionAllowed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionAllowed = !MediaQuery.disableAnimationsOf(context);
    _applySpin();
  }

  @override
  void didUpdateWidget(SyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applySpin();
  }

  /// Never leaves the controller ticking outside [HomeSyncStatus.syncing] —
  /// an endless repeat in the background burns frames and battery.
  void _applySpin() {
    if (_shouldSpin) {
      if (!_controller.isAnimating) {
        // The ticker future only completes on dispose; nothing to await.
        unawaited(_controller.repeat());
      }
    } else if (_controller.isAnimating || _controller.value != 0) {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final (icon, label) = switch (widget.status) {
      HomeSyncStatus.synced => (LucideIcons.cloudCheck, l10n.homeSyncSynced),
      HomeSyncStatus.syncing => (LucideIcons.refreshCw, l10n.homeSyncSyncing),
      HomeSyncStatus.offline => (LucideIcons.cloudOff, l10n.homeSyncOffline),
    };
    return Semantics(
      label: label,
      child: RotationTransition(
        turns: _controller,
        child: Icon(icon, size: 18, color: colors.textSecondary),
      ),
    );
  }
}
