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
  const MergeConfirmationPage({required this.onDone, super.key});

  /// "Ir a mis finanzas".
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

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
                        style: Theme.of(context).textTheme.titleMedium,
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
                      FilledButton(
                        onPressed: onDone,
                        child: Text(l10n.authMergeCta),
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
                      label: Text(l10n.authMergeCta),
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
