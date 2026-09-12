import 'dart:async';
import 'dart:math' as math;

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
/// "reduce motion" on, everything below freezes at its design/resting shape
/// and the label stays the primary signal, so it can never be switched off
/// (HU-09).
///
/// Two animations layer on top of that static design, both purely
/// decorative (never the only signal of state, per the invariant above):
/// a slow continuous "breathing" halo so the indicator reads as alive the
/// instant it appears, before a word is said, and a [soundLevel]-reactive
/// pulse on the microphone circle itself so speaking visibly moves the
/// circle, not just the bars underneath it.
class VoiceListeningIndicator extends StatefulWidget {
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
  State<VoiceListeningIndicator> createState() =>
      _VoiceListeningIndicatorState();
}

class _VoiceListeningIndicatorState extends State<VoiceListeningIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce motion also stops the ticker itself, not just its visual
    // effect — a paused controller costs nothing, one running in the
    // background for a hidden animation is a pointless battery draw.
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      unawaited(_breath.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final level = widget.soundLevel.clamp(0.0, 1.0);
    // Reactive pulse: the louder the room, the bigger the circle — on top of
    // (not instead of) the halo's own idle breathing below.
    final micScale = 1 + (animate ? level * 0.12 : 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _breath,
          builder: (context, child) {
            // Halo breathes 100%-106% on a slow loop regardless of level —
            // the "still alive, still listening" cue before any sound
            // arrives — while the inner circle additionally pulses with the
            // live level via `micScale`.
            final breathScale = animate ? 1 + _breath.value * 0.06 : 1.0;
            return Transform.scale(scale: breathScale, child: child);
          },
          child: Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: AnimatedScale(
              scale: micScale.toDouble(),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
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
          ),
        ),
        const SizedBox(height: 16),
        VoiceWaveBars(
          soundLevel: widget.soundLevel,
          semanticsLabel: widget.soundLevelLabel,
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            widget.statusLabel,
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
/// from the moment it appears, before the user has said a word: a slow idle
/// ripple (a few px, staggered per bar) keeps it moving even at silence, on
/// top of the level-driven height below.
class VoiceWaveBars extends StatefulWidget {
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

  @override
  State<VoiceWaveBars> createState() => _VoiceWaveBarsState();
}

class _VoiceWaveBarsState extends State<VoiceWaveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      unawaited(_idle.repeat());
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // "Reduce motion" freezes the bars at their design heights: the label and
    // the microphone circle already carry the state, so nothing is lost.
    final animate = !MediaQuery.disableAnimationsOf(context);
    final level = widget.soundLevel.clamp(0.0, 1.0);
    return Semantics(
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: 48,
        child: AnimatedBuilder(
          animation: _idle,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0;
                    i < VoiceWaveBars.restingHeights.length;
                    i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOutCubic,
                    width: 5,
                    height: animate
                        ? _liveHeightFor(i, level)
                        : VoiceWaveBars.restingHeights[i],
                    decoration: BoxDecoration(
                      color: colors.primaryData,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Level-driven height, plus a small staggered idle ripple (a sine wave
  /// per bar, out of phase with its neighbours) so the row keeps a visible
  /// pulse of its own instead of sitting dead-still between level updates —
  /// most recognizers report `onSoundLevelChange` too sparsely for the bars
  /// to look alive on that signal alone.
  double _liveHeightFor(int index, double level) {
    final base = VoiceWaveBars._heightFor(
      VoiceWaveBars.restingHeights[index],
      level,
    );
    final phase = _idle.value * 2 * math.pi + index * 0.9;
    final ripple = (0.5 + 0.5 * math.sin(phase)) * 3;
    return base + ripple;
  }
}
