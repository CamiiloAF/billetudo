import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../cubit/voice_capture_state.dart';

/// "El dictado no está disponible aquí".
///
/// **Not a designed frame.** `billetudo.pen` covers listening, partial
/// transcription, "no captamos el monto" and "sin permiso", but no surface for
/// a device that cannot transcribe at all. It reuses `lLKTv`'s exact shape
/// (muted `mic-off` header + exits) rather than inventing a look, and it is
/// flagged here so the gap is visible instead of silently settled in code.
///
/// The reason is spelled out honestly, including the one that matters most:
/// when on-device recognition is unavailable the app refuses to route the
/// audio through the vendor's cloud on its own (HU-06), and says so — it does
/// not pretend the phone simply cannot listen.
class VoiceCaptureUnavailableBody extends StatelessWidget {
  const VoiceCaptureUnavailableBody({
    required this.reason,
    required this.onRetry,
    required this.onWriteByHand,
    super.key,
  });

  final VoiceCaptureUnavailableReason? reason;
  final VoidCallback onRetry;
  final VoidCallback onWriteByHand;

  /// Retrying only makes sense for a condition that can change on its own.
  /// Offering it for a missing recognizer would just fail again identically.
  bool get _canRetry =>
      reason == VoiceCaptureUnavailableReason.network ||
      reason == VoiceCaptureUnavailableReason.busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.micOff,
          iconColor: colors.textSecondary,
          iconBackground: colors.muted,
          title: l10n.captureVoiceUnavailableTitle,
          message: _messageFor(l10n),
          messageColor: colors.textSecondary,
        ),
        const SizedBox(height: 16),
        if (_canRetry) ...[
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.mic, size: 18),
            label: Text(l10n.captureVoiceRetry),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onWriteByHand,
            icon: const Icon(LucideIcons.pencilLine, size: 18),
            label: Text(l10n.captureVoiceWriteByHand),
          ),
        ] else
          FilledButton.icon(
            onPressed: onWriteByHand,
            icon: const Icon(LucideIcons.pencilLine, size: 18),
            label: Text(l10n.captureVoiceWriteByHand),
          ),
      ],
    );
  }

  String _messageFor(AppLocalizations l10n) => switch (reason) {
        VoiceCaptureUnavailableReason.onDeviceUnavailable =>
          l10n.captureVoiceOnDeviceUnavailableMessage,
        VoiceCaptureUnavailableReason.network =>
          l10n.captureVoiceNoConnectionMessage,
        VoiceCaptureUnavailableReason.busy => l10n.captureVoiceBusyMessage,
        VoiceCaptureUnavailableReason.recognizer ||
        null =>
          l10n.captureVoiceUnavailableMessage,
      };
}
