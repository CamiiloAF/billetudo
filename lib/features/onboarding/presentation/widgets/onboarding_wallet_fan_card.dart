import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'onboarding_wallet_card.dart';

/// One positioned, animated card used by `OnboardingWalletFan` — see that
/// widget for the animation rationale.
class OnboardingWalletFanCard extends StatelessWidget {
  const OnboardingWalletFanCard({
    required this.depth,
    required this.animation,
    super.key,
  });

  /// 0 = frontmost card (the one that shows its content), higher = further
  /// back.
  final int depth;

  /// Drives this card's entrance (fade + scale-bounce).
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final width = 210.0 - depth * 20;
    final height = 126.0 - depth * 10;
    final rotationDeg = depth == 0 ? -7.0 : 4.0 * depth;
    final left = depth == 0 ? 40.0 : 40.0 + 40.0 * depth;
    final top = math.max(0.0, depth == 0 ? 40.0 : 40.0 - 15.0 * depth);

    return Positioned(
      left: left,
      top: top,
      child: ScaleTransition(
        scale: animation,
        child: FadeTransition(
          opacity: animation,
          child: Transform.rotate(
            angle: rotationDeg * math.pi / 180,
            child: OnboardingWalletCard(
              width: width,
              height: height,
              showContent: depth == 0,
            ),
          ),
        ),
      ),
    );
  }
}
