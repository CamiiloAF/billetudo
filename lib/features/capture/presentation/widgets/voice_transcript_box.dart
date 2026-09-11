import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Voice Transcript Box` component (`Uola9`): a `$muted` 16pt-radius box
/// showing the live partial transcription, or an example of what can be said
/// while nothing has been recognized yet.
///
/// **Never truncated.** The component's own note is explicit: this respects
/// the system font size and does not clip to a fixed number of lines (HU-09),
/// so there is no `maxLines`/`ellipsis` here on purpose — a long dictation
/// grows the box and the sheet scrolls. That is the opposite of the default
/// this codebase applies to list rows, and it is deliberate.
class VoiceTranscriptBox extends StatelessWidget {
  const VoiceTranscriptBox({
    required this.text,
    required this.isLive,
    super.key,
  });

  /// Already localized: the live transcript when [isLive], the example hint
  /// otherwise.
  final String text;

  /// Whether [text] is something the user actually said. Live text is
  /// `$text-primary`/600, the resting example `$segment-inactive-text`/500.
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Semantics(
        liveRegion: isLive,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: isLive ? FontWeight.w600 : FontWeight.w500,
            height: 1.45,
            color: isLive ? colors.textPrimary : colors.segmentInactiveText,
          ),
        ),
      ),
    );
  }
}
