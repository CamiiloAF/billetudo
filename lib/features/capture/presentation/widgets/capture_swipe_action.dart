import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The action revealed behind a capture card when it is swiped towards the
/// start edge — the approved design (`IMs3M` light, `bkNc1` dark).
///
/// It is not a control of its own: `CaptureSwipeDismissible` paints it as the
/// `Dismissible` background, so the gesture is the only way to reach it (plus
/// the card's accessibility action). Geometry comes from the frame: a 96 x
/// card-height slice on the trailing edge, `$expense` fill and the card's own
/// 16pt radius on the visible corner.
class CaptureSwipeAction extends StatelessWidget {
  const CaptureSwipeAction({super.key});

  /// Width of the revealed slice, measured in the approved frame.
  static const double width = 96;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.onPrimary,
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        alignment: Alignment.center,
        color: colors.expense,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.trash2, size: 16, color: colors.onPrimary),
            const SizedBox(height: 3),
            Text(
              l10n.captureDiscardSwipeLabel,
              maxLines: 1,
              style: labelStyle,
            ),
          ],
        ),
      ),
    );
  }
}
