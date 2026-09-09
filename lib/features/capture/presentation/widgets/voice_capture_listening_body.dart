import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sheet_buttons_row.dart';
import '../cubit/voice_capture_state.dart';
import 'voice_listening_indicator.dart';
import 'voice_transcript_box.dart';

/// The listening surface of the capture sheet (`f8OP8a` and `Z6imP`).
///
/// One body for both frames: they are the same layout, and what differs is
/// whether anything has been transcribed yet — which also swaps the caption,
/// from "el audio no se guarda" while there is nothing to show to "al
/// terminar abrimos el formulario, tú confirmas" once there is.
///
/// "Cancelar" is always available and discards everything. "Listo" ends the
/// session on demand, which is the route that does not require holding a
/// gesture down; the session also ends by itself on silence or on the hard
/// duration cap.
class VoiceCaptureListeningBody extends StatelessWidget {
  const VoiceCaptureListeningBody({
    required this.state,
    required this.onCancel,
    required this.onDone,
    super.key,
  });

  final VoiceCaptureState state;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final isPreparing = state.status == VoiceCaptureStatus.preparing;
    final hasTranscript = state.hasTranscript;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        VoiceListeningIndicator(
          statusLabel: isPreparing
              ? l10n.captureVoicePreparing
              : l10n.captureVoiceListening,
          soundLevel: state.soundLevel,
          soundLevelLabel: l10n.captureVoiceSoundLevelLabel,
        ),
        const SizedBox(height: 16),
        VoiceTranscriptBox(
          text: hasTranscript ? state.transcript : l10n.captureVoiceHint,
          isLive: hasTranscript,
        ),
        const SizedBox(height: 16),
        Text(
          hasTranscript
              ? l10n.captureVoicePartialCaption
              : l10n.captureVoicePrivacyCaption,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SheetButtonsRow(
          left: OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(LucideIcons.x, size: 18),
            label: Text(l10n.captureVoiceCancel),
          ),
          right: FilledButton.icon(
            // Disabled only while the microphone has not opened yet: there is
            // nothing to finish, and Cancelar next to it still leaves.
            onPressed: isPreparing ? null : onDone,
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.captureVoiceDone),
          ),
        ),
      ],
    );
  }
}
