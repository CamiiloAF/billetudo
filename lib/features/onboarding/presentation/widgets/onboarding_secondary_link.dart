import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// `Onboarding Secondary Link` (Pencil `f3Zbo`): the never-hidden, never-first
/// secondary action of every onboarding screen ("Ya tengo cuenta", "Omitir
/// por ahora", "Después", "Lo hago después").
///
/// `padding:[14,16]` gives it a ~46pt tap target — the touch-target fix
/// `pages/onboarding.md` documents from the first round of concepts.
class OnboardingSecondaryLink extends StatelessWidget {
  const OnboardingSecondaryLink({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
