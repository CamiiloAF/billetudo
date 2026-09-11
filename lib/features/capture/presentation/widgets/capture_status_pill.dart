import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// `vbhYb` — the "No suma a tu saldo" pill.
///
/// The single most important signal on a capture card, and the reason it is
/// its own widget: the label is **identical on every surface**. In the
/// movements list it sits beside real transactions, which is precisely where
/// mistaking a proposal for money costs the most, so it must never degrade
/// into loose caption text there.
class CaptureStatusPill extends StatelessWidget {
  const CaptureStatusPill({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        AppLocalizations.of(context).captureNotBalancePill,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.primaryOnSoftStrong,
            ),
      ),
    );
  }
}
