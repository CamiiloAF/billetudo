import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// `yX9Qs`/`VLraM`/`m4HYmb` — the "No suma a tu saldo" kicker as plain
/// inline text (11/700 `$primary-on-soft-strong`), used on every chasis that
/// sits directly on `$surface` (`skjlg`, `EqRlj`, `RSizy`).
///
/// Not a pill: the 2026-09-09 rebuild dropped the `$primary-soft` tint these
/// cards used to sit on, and a pill only earns its background when it has to
/// stand out from a tinted fill. The one card that keeps the tint —
/// `MovementPendingCaptureCard` (`vRWd5`) — keeps `CaptureStatusPill`
/// instead; the copy is identical on both, only the chrome differs.
class CaptureGuaranteeKicker extends StatelessWidget {
  const CaptureGuaranteeKicker({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      AppLocalizations.of(context).captureNotBalancePill,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.primaryOnSoftStrong,
          ),
    );
  }
}
