import 'package:flutter/material.dart';

import 'onboarding_status_badge.dart';
import 'onboarding_wallet_fan_card.dart';

/// The "billetera que se llena" hero: a fan of [cardCount] `Onboarding
/// Wallet Card`s (1-4) growing toward the viewer, topped by [badge] when the
/// screen has one.
///
/// **Animation note (`pages/onboarding.md`, "Notas de animación para
/// flutter-dev"):** the design calls for the back card entering first, the
/// front one ~80ms later, the badge popping in after, and — across screens —
/// the previous screen's front card morphing into the next screen's back
/// card (a shared-element/hero transition, not a crossfade). This widget
/// implements the **within-screen** stagger (back-to-front entrance + badge
/// pop) with a single, self-contained `AnimationController`. It does
/// **not** implement the cross-screen shared-element morph: each `go_router`
/// push mounts an independent instance, and matching Hero tags across four
/// separate stacked routes with different card counts/positions is a
/// substantial follow-up, not a blocker to understanding any single step
/// (`13-onboarding.md`, "Ninguna animación es bloqueante ni indispensable
/// para entender el paso"). Documented here rather than silently dropped.
///
/// The exact per-card rotation/offset/opacity Pencil hand-tuned per screen
/// (`S7Dgu0` instances in `fRrDQ`/`G7vDVK`/`MydOr`/`Gi0NV`) are not
/// reproduced pixel-for-pixel either: this widget derives them from
/// [cardCount] with one formula, close enough to read as the same fan motif
/// at every step while keeping one implementation instead of four.
class OnboardingWalletFan extends StatefulWidget {
  const OnboardingWalletFan({required this.cardCount, this.badge, super.key});

  /// Between 1 (not used today) and 4 (Cierre).
  final int cardCount;

  /// `null` on Bienvenida, which shows no badge.
  final OnboardingBadgeKind? badge;

  @override
  State<OnboardingWalletFan> createState() => _OnboardingWalletFanState();
}

class _OnboardingWalletFanState extends State<OnboardingWalletFan>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Depth 0 is the frontmost card; higher depths sit further back. Entrance
  /// order is back-to-front, so the card at [depth] starts animating at
  /// `entryIndex * 0.15` of the timeline, where `entryIndex` counts from the
  /// back (0 = back-most, enters first).
  Animation<double> _cardAnimation(int depth) {
    final entryIndex = (widget.cardCount - 1) - depth;
    final start = (entryIndex * 0.15).clamp(0.0, 0.85);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
  }

  Animation<double> get _badgeAnimation {
    final start = (widget.cardCount * 0.15).clamp(0.0, 0.7);
    final end = (start + 0.3).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;

    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var depth = widget.cardCount - 1; depth >= 0; depth--)
            OnboardingWalletFanCard(
              depth: depth,
              animation: _cardAnimation(depth),
            ),
          if (badge != null)
            Positioned(
              left: 56,
              top: 10,
              child: ScaleTransition(
                scale: _badgeAnimation,
                child: OnboardingStatusBadge(kind: badge),
              ),
            ),
        ],
      ),
    );
  }
}
