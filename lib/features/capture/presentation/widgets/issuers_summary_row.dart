import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// `bYlVW`/`cuFuz` — how many issuers are on, plus "Apagar todas".
///
/// Both halves are HU-02 requirements: the screen has to say how many are
/// active and let the user turn every one of them off in a single tap,
/// without going out to Android to revoke the system permission.
///
/// With nothing on, the action stays **visible but inert** in
/// `$segment-inactive-text` rather than disappearing: a control that appears
/// and vanishes as the count crosses zero is harder to trust than one that is
/// always in the same place.
class IssuersSummaryRow extends StatelessWidget {
  const IssuersSummaryRow({
    required this.enabledCount,
    required this.totalCount,
    required this.onTurnOffAll,
    super.key,
  });

  final int enabledCount;
  final int totalCount;
  final VoidCallback onTurnOffAll;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);
    final bool hasEnabled = enabledCount > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Text(
            hasEnabled
                ? l10n.captureIssuersActiveCount(enabledCount, totalCount)
                : l10n.captureIssuersNoneActive,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 13pt of vertical padding brings the 18pt label to the 44pt minimum
        // tap height without a box around it.
        InkWell(
          onTap: hasEnabled ? onTurnOffAll : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Text(
              l10n.captureIssuersTurnOffAll,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: hasEnabled
                    ? colors.primaryOnSoft
                    : colors.segmentInactiveText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
