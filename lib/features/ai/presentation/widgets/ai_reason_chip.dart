import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_report.dart';
import '../utils/ai_report_reason_appearance.dart';

/// The `Reason Chip` component (`Afl5e`): icon + label, single-select.
///
/// Takes [reason] itself, not a resolved icon/label pair: resolving
/// [AiReportReasonAppearance] here (rather than in the caller) keeps
/// `AiReasonGrid.build` a plain list of `AiReasonChip(...)` instances, with
/// no widget-returning helper method in between (`avoid_widget_functions`).
///
/// "Entidad sin color" pattern (same as Presupuestos' icon selector,
/// documented in `design-system/billetudo/pages/asistente-ia.md`): a reason
/// has no color pairing of its own, so selection is a hollow outline —
/// `$surface` fill + `$primary` stroke, icon/label in
/// `$primary-on-soft`/`$primary-on-soft-strong` — never a filled `-soft`
/// background (that would be indistinguishable from `$muted` at rest).
class AiReasonChip extends StatelessWidget {
  const AiReasonChip({
    required this.reason,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final AiReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final foreground = selected ? colors.primaryOnSoft : colors.textSecondary;
    final labelColor =
        selected ? colors.primaryOnSoftStrong : colors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AiReportReasonAppearance.icon(reason),
              size: 18,
              color: foreground,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AiReportReasonAppearance.label(l10n, reason),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
