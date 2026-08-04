import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// `Onboarding Wallet Card` (Pencil `S7Dgu0`): the `$primary` → `$primary-deep`
/// gradient card of the "billetera que se llena" motif. `OnboardingWalletFan`
/// instantiates several of these, rotated and faded, to build each screen's
/// hero.
///
/// Only the frontmost card in a fan shows its content (wallet icon + two
/// placeholder bars); the ones behind it render as a plain gradient card
/// ([showContent]`: false`), matching how Pencil disables `Icon`/`Bars` on
/// every "Card Back" instance.
class OnboardingWalletCard extends StatelessWidget {
  const OnboardingWalletCard({
    this.width = 210,
    this.height = 126,
    this.showContent = true,
    super.key,
  });

  final double width;
  final double height;
  final bool showContent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: showContent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.wallet, color: colors.onPrimary, size: 22),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 70,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
