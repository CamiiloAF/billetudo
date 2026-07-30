import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/merge_cubit.dart';
import '../cubit/merge_state.dart';
import '../widgets/device_preview_illustration.dart';
import '../widgets/merge_stats_card.dart';

/// HU-04's "Tus datos están a salvo" (`vexqA`): shown right after a
/// successful first sign-in that had local data to fold in. Same centered
/// language as Login, for continuity across the Auth flow.
class MergeConfirmationPage extends StatelessWidget {
  const MergeConfirmationPage({required this.onDone, this.ctaLabel, super.key});

  /// Called when the user taps the CTA. What it actually does depends on the
  /// caller: from Ajustes it always goes to Home, but from the onboarding's
  /// "Respalda tus datos" (HU-07) step it goes back to Cierre (the flow
  /// isn't done yet) — see `_finishOnboardingAfterLogin` in `app_router.dart`.
  final VoidCallback onDone;

  /// Overrides the CTA's label, which otherwise defaults to
  /// `l10n.authMergeCta` ("Ir a mis finanzas"). The onboarding caller passes
  /// `l10n.commonContinue` when `onDone` does NOT go to Home/finances (HU-07,
  /// `closesFlow: false`) — showing "Ir a mis finanzas" for a button that
  /// actually returns to another onboarding step would mislead the user.
  final String? ctaLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final label = ctaLabel ?? l10n.authMergeCta;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<MergeCubit, MergeState>(
          builder: (context, state) {
            if (state.status == MergeStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == MergeStatus.failure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.wifiOff,
                          size: 40, color: colors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        l10n.authMergeErrorTitle,
                        textAlign: TextAlign.center,
                        // `Error State`'s `Title` (`awFv1`) is 16/700.
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.authMergeErrorMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onDone,
                          child: Text(label),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final summary = state.summary;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const DevicePreviewIllustration(
                              badgeIcon: LucideIcons.check,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.authMergeTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.authMergeSubtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colors.textSecondary),
                            ),
                            if (summary != null) ...[
                              const SizedBox(height: 20),
                              MergeStatsCard(summary: summary, l10n: l10n),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              l10n.authMergeCaption,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onDone,
                      icon: const Icon(LucideIcons.arrowRight),
                      label: Text(label),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
