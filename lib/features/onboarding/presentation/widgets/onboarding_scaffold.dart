import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'onboarding_secondary_link.dart';
import 'onboarding_top_bar.dart';

/// The chrome every onboarding screen shares: [OnboardingTopBar], a
/// scrollable body and a bottom actions block (primary CTA + secondary link)
/// that stays fixed outside the scroll — same pattern the `Zona fija` note on
/// `O2QbEF` documents for the one screen dense enough to need it, applied
/// consistently to all four so a long device-locale string never pushes the
/// CTA off-screen (`cta-hoja-bajo-teclado` project convention).
///
/// [centerContent] vertically centers [content] when it fits the available
/// height (Bienvenida, Respalda tus datos, Cierre — all `justifyContent:
/// "center"` in Pencil) while still scrolling if it does not (a long locale
/// string, a large text-scale factor). `false` (Tu primera cuenta, whose
/// Pencil frame starts its content at the top) just lets it flow top-down.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    required this.stepIndex,
    required this.content,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.showBack = true,
    this.onBack,
    this.isPrimaryLoading = false,
    this.centerContent = true,
    super.key,
  });

  final int stepIndex;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget content;
  final bool centerContent;

  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onPrimary;
  final bool isPrimaryLoading;

  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingTopBar(
              stepIndex: stepIndex,
              showBack: showBack,
              onBack: onBack,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: centerContent
                        ? Center(child: content)
                        : content,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isPrimaryLoading ? null : onPrimary,
                      icon: isPrimaryLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(primaryIcon),
                      label: Text(primaryLabel),
                    ),
                  ),
                  OnboardingSecondaryLink(
                    label: secondaryLabel,
                    onPressed: onSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
