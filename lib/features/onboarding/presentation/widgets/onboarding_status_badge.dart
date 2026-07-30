import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Which badge sits on top of the wallet-card hero, matching what that
/// screen's action does: `+` on "Tu primera cuenta", a cloud on "Respalda tus
/// datos", a check on "Cierre". Bienvenida shows no badge.
enum OnboardingBadgeKind { plus, cloud, check }

/// The small pop-in badge over the frontmost `Onboarding Wallet Card`
/// (Pencil: `Plus Badge` in `G7vDVK`/`O2QbEF`, `Cloud Badge` in `MydOr`,
/// `Check Badge` in `Gi0NV`/`bAKS6`).
///
/// `pages/onboarding.md`, "Contraste de badges Plus/Check sobre `$income`":
/// the plus/check glyph is a fixed dark `#1C1B29`, not a themed token — white
/// measured ~2:1 on `$income` in both themes, so the design deliberately
/// pins it instead of binding it to `$on-primary`. The cloud badge is a
/// different shape (an outlined `$surface` circle, `$primary-on-soft` icon)
/// and does stay themed, since it never sits on `$income`.
class OnboardingStatusBadge extends StatelessWidget {
  const OnboardingStatusBadge({required this.kind, super.key});

  final OnboardingBadgeKind kind;

  /// `pages/onboarding.md`: fixed glyph colour for the plus/check badges,
  /// verified ~7.4:1 (light) / ~8.8:1 (dark) over `$income` — not themed on
  /// purpose, same exception `MASTER.md` already documents for the check over
  /// an account-colour swatch.
  static const Color _fixedDarkGlyph = Color(0xFF1C1B29);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (double size, Color background, Color? border, Widget icon) =
        switch (kind) {
      OnboardingBadgeKind.plus => (
          32.0,
          colors.income,
          null,
          const Icon(LucideIcons.plus, size: 16, color: _fixedDarkGlyph),
        ),
      OnboardingBadgeKind.check => (
          52.0,
          colors.income,
          colors.background,
          const Icon(LucideIcons.check, size: 24, color: _fixedDarkGlyph),
        ),
      OnboardingBadgeKind.cloud => (
          56.0,
          colors.surface,
          colors.border,
          Icon(LucideIcons.cloud, size: 26, color: colors.primaryOnSoft),
        ),
    };

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: border == null ? null : Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: icon,
    );
  }
}
