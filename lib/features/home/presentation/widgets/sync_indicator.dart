import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/home_state.dart';

/// The discreet sync-status icon of the Home header (`saRZW`, HU-10/HU-08),
/// with its four states and a fixed 44x44 tap area — the glyph itself stays
/// 18px, only the touch target grows.
///
/// The fourth state (attention) is `$amber`, never `$expense`: there are
/// changes waiting, nothing is broken and nobody is being scolded.
///
/// **The dot is the non-chromatic signal, and it is not optional.** At 18px
/// `cloud-alert` and `cloud-check` have nearly the same silhouette, and in
/// light mode `$amber` and `$text-secondary` sit at similar luminance — in
/// greyscale the glyph alone does not distinguish anything. The ring behind
/// the dot is painted in `$background` and works by *cutting*: it opens ~2px
/// of air between the dot and the glyph. That only holds while the indicator
/// sits on `$background`; over a `$surface` card the ring would have to be
/// repointed at the real fill.
///
/// While syncing, the refresh icon rotates so the user can tell something is
/// happening (notably during the post-login merge, where a static "synced"
/// icon read as the app being stuck). Stateful only for that rotation.
class SyncIndicator extends StatefulWidget {
  const SyncIndicator({required this.status, this.onTap, super.key});

  final HomeSyncStatus status;

  /// When non-null, the icon becomes interactive with a 44pt tap target.
  /// `null` keeps it passive (its earlier HU-10 behaviour, still used by the
  /// widget tests in isolation).
  final VoidCallback? onTap;

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
    final isAttention = widget.status == HomeSyncStatus.attention;
    final (icon, label) = switch (widget.status) {
      HomeSyncStatus.synced => (LucideIcons.cloudCheck, l10n.homeSyncSynced),
      HomeSyncStatus.syncing => (LucideIcons.refreshCw, l10n.homeSyncSyncing),
      HomeSyncStatus.offline => (LucideIcons.cloudOff, l10n.homeSyncOffline),
      HomeSyncStatus.attention => (
          LucideIcons.cloudAlert,
          l10n.homeSyncAttention,
        ),
    };
    final indicator = RotationTransition(
      turns: _controller,
      child: Icon(
        icon,
        size: 18,
        color: isAttention ? colors.amber : colors.textSecondary,
      ),
    );

    final content = SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          indicator,
          if (isAttention)
            Positioned(
              top: 7,
              right: 4,
              child: Container(
                width: 12,
                height: 12,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.background,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final onTap = widget.onTap;
    if (onTap == null) {
      return Semantics(label: label, child: content);
    }

    return Semantics(
      label: label,
      button: true,
      child: InkResponse(onTap: onTap, radius: 22, child: content),
    );
  }
}
