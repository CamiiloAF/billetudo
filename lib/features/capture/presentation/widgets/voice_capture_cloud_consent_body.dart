import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../core/widgets/permission_fact_row.dart';
import '../utils/cloud_transcription_vendor.dart';

/// The cloud-transcription consent sheet (`kJG43`).
///
/// It exists because on plenty of Android phones the offline language pack is
/// simply not installed, and without this surface dictation is dead there:
/// the session asks for on-device recognition, cannot get it, and stops. The
/// product decision is that the audio *may* travel — but never quietly. This
/// is that "never quietly", and it is shown **before** anything leaves the
/// phone, since the failed on-device attempt sent nothing.
///
/// Three things it is careful about:
///
/// - **It names the third party.** Google on Android, Apple on iOS, resolved
///   by [CloudTranscriptionVendor] rather than duplicated into two sheets.
/// - **Both exits weigh the same.** "Escribir a mano" is Nivel 0 and can
///   never read as a punishment or a dead end, so it is a full-width button
///   next to the other, not a link underneath it.
/// - **It promises reversibility and the app keeps it** — the caption points
///   at Ajustes, where the switch actually exists.
///
/// Tone is informative, not cautionary: no red, no alarm glyphs, no apology.
class VoiceCaptureCloudConsentBody extends StatelessWidget {
  const VoiceCaptureCloudConsentBody({
    required this.onAllow,
    required this.onWriteByHand,
    super.key,
  });

  final VoidCallback onAllow;

  /// Also records the refusal — see `VoiceCaptureCubit.declineCloudTranscription`.
  final VoidCallback onWriteByHand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final vendor = CloudTranscriptionVendor.nameFor(l10n, theme.platform);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.cloud,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: l10n.captureVoiceCloudConsentTitle(vendor),
          message: l10n.captureVoiceCloudConsentMessage(vendor),
          messageColor: colors.textSecondary,
        ),
        const SizedBox(height: 16),
        PermissionFactList(
          facts: [
            PermissionFactRow(
              icon: LucideIcons.cloudUpload,
              title: l10n.captureVoiceCloudConsentFact1Title,
              body: l10n.captureVoiceCloudConsentFact1Body(vendor),
            ),
            PermissionFactRow(
              icon: LucideIcons.shieldCheck,
              title: l10n.captureVoiceCloudConsentFact2Title,
              body: l10n.captureVoiceCloudConsentFact2Body,
            ),
            PermissionFactRow(
              icon: LucideIcons.listChecks,
              title: l10n.captureVoiceCloudConsentFact3Title,
              body: l10n.captureVoiceCloudConsentFact3Body,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAllow,
          icon: const Icon(LucideIcons.mic, size: 18),
          label: Text(l10n.captureVoiceCloudConsentAllow),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onWriteByHand,
          icon: const Icon(LucideIcons.pencilLine, size: 18),
          label: Text(l10n.captureVoiceWriteByHand),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.captureVoiceCloudConsentReversible,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
