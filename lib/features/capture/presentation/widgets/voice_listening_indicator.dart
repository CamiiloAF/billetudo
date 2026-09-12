import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Voice Listening Indicator` component (`ayjtW`): a 112pt `$primary-soft`
/// halo around an 84pt `$primary` microphone circle, 14 level bars, and a
/// status label.
///
/// The state is **never** communicated by colour or motion alone: the halo and
/// the circle give it a shape, the bars give the live level, and [statusLabel]
/// says it in words — which is also what the screen reader announces. With
/// "reduce motion" on, the bars freeze at their design heights and the label
/// stays the primary signal, so it can never be switched off (HU-09).
class VoiceListeningIndicator extends StatelessWidget {
  const VoiceListeningIndicator({
    required this.statusLabel,
    required this.soundLevel,
    required this.soundLevelLabel,
    super.key,
  });

  /// Already localized: "Escuchando…". Announced as the live region.
  final String statusLabel;

  /// Normalized 0..1 microphone level. Values outside the range are clamped,
  /// so a recognizer that reports raw decibels cannot blow the layout up.
  final double soundLevel;

  /// Already localized accessible name for the bars, which carry no text.
  final String soundLevelLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 112,
          height: 112,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.mic, size: 36, color: colors.onPrimary),
          ),
        ),
        const SizedBox(height: 16),
        VoiceWaveBars(
          soundLevel: soundLevel,
          semanticsLabel: soundLevelLabel,
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            statusLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The 14 `$primary-data` level bars of [VoiceListeningIndicator] (`ZbMwT`).
///
/// The frame's heights are read as the **peak**: at a full level every bar
/// renders exactly what `ayjtW` draws (46pt tallest inside a 48pt row), and a
/// quieter room dips them down to 40% — wide enough that speaking visibly
/// moves the bars instead of just nudging them. Never to zero — a flat line
/// reads as "the microphone is off", and this indicator has to look alive
/// from the moment it appears, before the user has said a word.
class VoiceWaveBars extends StatelessWidget {
  const VoiceWaveBars({
    required this.soundLevel,
    required this.semanticsLabel,
    super.key,
  });

  final double soundLevel;
  final String semanticsLabel;

  /// The resting heights drawn in `ayjtW`, bar 1 to bar 14.
  static const List<double> restingHeights = [
    12,
    22,
    34,
    46,
    28,
    40,
    18,
    32,
    46,
    24,
    14,
    26,
    36,
    20,
  ];

  static const double _minHeight = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // "Reduce motion" freezes the bars at their design heights: the label and
    // the microphone circle already carry the state, so nothing is lost.
    final animate = !MediaQuery.disableAnimationsOf(context);
    final level = soundLevel.clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < restingHeights.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: 5,
                height: animate
                    ? _heightFor(restingHeights[i], level)
                    : restingHeights[i],
                decoration: BoxDecoration(
                  color: colors.primaryData,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 40% of the design height at silence, exactly the design height at peak.
  ///
  /// Widened from the original 70%-100% range, which read as nearly static
  /// even while speaking. The fine calibration of the level this multiplies
  /// against still lives in `SpeechToTextRecognizer._normalizeLevel` and has
  /// not been re-verified against real `onSoundLevelChange` values on device
  /// — see that method's doc comment.
  static double _heightFor(double resting, double level) {
    final scaled = resting * (0.4 + 0.6 * level);
    return scaled < _minHeight ? _minHeight : scaled;
  }
}
