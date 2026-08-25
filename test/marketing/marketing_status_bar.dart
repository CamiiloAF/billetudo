import 'package:billetudo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Which store a capture is destined for, which decides the status bar.
///
/// Play and App Store get separate PNG sets: a screenshot showing Android
/// chrome on an App Store listing (or the reverse) reads as a mockup of the
/// wrong app.
enum MarketingPlatform { android, ios }

/// The device status bar the store screenshots need.
///
/// Why it exists: a capture rendered by `flutter_test` has no system chrome at
/// all, so the app content starts at y=0. Dropped into the Pencil device
/// mockup that framing reads as an amputated screen — the phone has a bezel
/// but no clock, no battery, nothing.
///
/// ## What actually differs between the two platforms
///
/// **Not the clock position.** Both put it on the left. iOS only centered it
/// up to the iPhone 8; every notched iPhone since — including the 6.9" device
/// whose 1290x2796 frame the App Store listing targets — moved it left, with
/// the notch occupying the middle. `Status Bar/iOS` (`YX2tK`) in
/// `billetudo.pen` still centers it, so **that component is wrong** and should
/// be corrected there; this file deliberately does not reproduce the mistake.
///
/// What differs is the iconography:
///
/// | | Android | iOS |
/// |---|---|---|
/// | Signal | one filled triangle | four discrete bars, rising |
/// | Battery | upright, cap on top | on its side, outlined, with a nub |
///
/// Both keep the 390x62 box, padding [16, 24, 0, 24], `9:41` at 16pt/600 in
/// `$text-primary`, and a 6pt gap between icons, which is what the design
/// system specifies for both variants.
///
/// `9:41` is hardcoded on purpose: it is the conventional mockup time, and
/// deriving it from the clock would make every regeneration produce a
/// different PNG.
class MarketingStatusBar extends StatelessWidget {
  const MarketingStatusBar({required this.platform, super.key});

  final MarketingPlatform platform;

  static const double height = 62;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isIos = platform == MarketingPlatform.ios;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isIos)
                  IosSignalBars(color: colors.textPrimary)
                else
                  Icon(
                    Icons.signal_cellular_4_bar,
                    size: 16,
                    color: colors.textPrimary,
                  ),
                const SizedBox(width: 6),
                Icon(Icons.wifi, size: 16, color: colors.textPrimary),
                const SizedBox(width: 6),
                if (isIos)
                  IosBatteryIcon(color: colors.textPrimary)
                else
                  // Android draws the battery upright, cap on top — which is
                  // exactly how Material ships the glyph, so it is used as is.
                  Icon(
                    Icons.battery_full,
                    size: 16,
                    color: colors.textPrimary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS cellular signal: four discrete bars of rising height, bottom-aligned.
///
/// Material has no equivalent — its `signal_cellular_*` glyphs are a single
/// filled triangle, which is the Android shape. Drawing it is what keeps the
/// two platforms telling apart.
class IosSignalBars extends StatelessWidget {
  const IosSignalBars({required this.color, super.key});

  final Color color;

  static const List<double> _heights = [5, 7.5, 10, 12.5];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (index, barHeight) in _heights.indexed) ...[
            if (index > 0) const SizedBox(width: 1.5),
            Container(
              width: 3,
              height: barHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// iOS battery: a rounded outline lying on its side, a filled core, and the
/// small nub on the right.
///
/// Material's `battery_full` is a solid upright glyph — the Android shape.
class IosBatteryIcon extends StatelessWidget {
  const IosBatteryIcon({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 12,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            borderRadius: BorderRadius.circular(3.5),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
        const SizedBox(width: 1),
        Container(
          width: 1.5,
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}
