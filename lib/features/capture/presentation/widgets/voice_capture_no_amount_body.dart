import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import 'voice_transcript_box.dart';

/// The "no captamos el monto" surface (`lLKTv`).
///
/// Describes the state of the app, never how the user spoke: no "hablaste
/// mal", no "habla más despacio". Nothing the user said is thrown away —
/// the transcript stays on screen and travels to the form as a note — so the
/// two exits are both real: dictate again, or write it by hand.
///
/// The icon is deliberately `$muted`/`$text-secondary`, not the brand violet
/// and not `$expense`: this is an outcome, not an error and not a warning.
class VoiceCaptureNoAmountBody extends StatelessWidget {
  const VoiceCaptureNoAmountBody({
    required this.transcript,
    required this.onRetry,
    required this.onWriteByHand,
    super.key,
  });

  /// What was recognized. Empty when the recognizer heard nothing at all, in
  /// which case the box falls back to the example hint.
  final String transcript;

  final VoidCallback onRetry;
  final VoidCallback onWriteByHand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final hasTranscript = transcript.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.micOff,
          iconColor: colors.textSecondary,
          iconBackground: colors.muted,
          title: l10n.captureVoiceNoAmountTitle,
          message: l10n.captureVoiceNoAmountMessage,
          messageColor: colors.textSecondary,
        ),
        const SizedBox(height: 16),
        VoiceTranscriptBox(
          text: hasTranscript ? transcript : l10n.captureVoiceHint,
          isLive: hasTranscript,
        ),
        const SizedBox(height: 16),
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
      ],
    );
  }
}
