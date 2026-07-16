import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'device_preview_phone.dart';

/// `Illustration/Device Preview` (`a0FOYN`): two overlapping "phone" mockups
/// connected by a sync badge — communicates multi-device sync visually
/// instead of with text. Centered composition, ~248x160 within a 350px block
/// (Login, `fTetG`/`RSzD1`); reused on the merge confirmation screen
/// (`vexqA`) with the badge icon swapped to a checkmark.
class DevicePreviewIllustration extends StatelessWidget {
  const DevicePreviewIllustration({this.badgeIcon = Icons.sync, super.key});

  final IconData badgeIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 350,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 60,
            top: 15,
            child: DevicePreviewPhone(
              width: 108,
              height: 160,
              background: colors.surface,
              border: colors.border,
              accent: colors.border,
            ),
          ),
          Positioned(
            right: 60,
            bottom: 15,
            child: DevicePreviewPhone(
              width: 108,
              height: 160,
              background: colors.surface,
              border: colors.border,
              accent: colors.primary,
              highlightAmount: true,
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colors.background, width: 3),
            ),
            child: Icon(badgeIcon, color: colors.onPrimary, size: 20),
          ),
        ],
      ),
    );
  }
}
