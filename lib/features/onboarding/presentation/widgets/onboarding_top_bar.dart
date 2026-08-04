import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import 'onboarding_progress_dot.dart';

/// `Onboarding Top Bar` (Pencil `s6LXJ`): a 44pt back button (hidden on the
/// first step), 4 progress dots and a matching spacer on the right so the
/// dots stay centered.
///
/// The dot at [stepIndex] is drawn wide (22pt) and `$primary`; earlier dots
/// are narrow (8pt) and `$primary` too (already completed); later dots are
/// narrow and `$border` (not reached yet) — the exact rule the four onboarding
/// frames encode via their `Top Bar` descendant overrides.
///
/// The back button, when [showBack], defaults to popping the current
/// onboarding step (same fallback `PageHeader` uses) — every step but
/// Bienvenida just needs "go to the previous screen", so callers do not have
/// to wire that up themselves.
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    required this.stepIndex,
    this.showBack = true,
    this.onBack,
    super.key,
  });

  /// 0-based index of the step currently shown (0=Bienvenida .. 3=Cierre).
  final int stepIndex;

  /// `false` hides the back button entirely — only Bienvenida, the first
  /// step, where the system back button minimizes the app instead
  /// (`13-onboarding.md`, "Navegación").
  final bool showBack;

  /// Overrides the default pop-current-step behavior. Rarely needed.
  final VoidCallback? onBack;

  static const int _stepCount = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBack)
            PageHeaderCircleButton(
              icon: LucideIcons.arrowLeft,
              background: colors.muted,
              foreground: colors.textPrimary,
              tooltip: AppLocalizations.of(context).commonBack,
              iconSize: 20,
              onPressed: onBack ?? () => context.pop(),
            )
          else
            const SizedBox(width: 44, height: 44),
          Row(
            children: [
              for (var dot = 0; dot < _stepCount; dot++) ...[
                if (dot > 0) const SizedBox(width: 6),
                OnboardingProgressDot(
                  active: dot <= stepIndex,
                  current: dot == stepIndex,
                ),
              ],
            ],
          ),
          const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }
}
