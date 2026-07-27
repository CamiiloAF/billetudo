import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/zero_based_summary.dart';
import 'budget_progress_bar.dart';
import 'envelope_mode_pill.dart';
import 'envelope_nudge_strip.dart';

/// The "Modo sobres" hero (`D1G5hl/w6P0W`, HU-06): a `$surface` card with a
/// `$border` outline — a summary surface, not a CTA row — holding the mode
/// pill, the info entry point, the amount still **unassigned**
/// (income − assigned), the assignment track, the two caption anchors and the
/// motivational nudge.
///
/// "Sin asignar" tends to zero but never blocks anything — it is guidance, not
/// an obstacle. Tone stays positive: at zero it celebrates, and over-assigning
/// is stated neutrally, never as a scolding. Sober `$primary` family only — no
/// traffic-light colors.
class EnvelopeHero extends StatelessWidget {
  const EnvelopeHero({required this.summary, required this.onInfo, super.key});

  final ZeroBasedSummary summary;

  /// Opens the "¿Qué es el modo sobres?" sheet (`eBwb0`).
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    const money = MoneyFormatter();
    final unassigned = summary.unassignedMinor;

    final headlineLabel = summary.isOverAssigned
        ? l10n.budgetsEnvelopeOverLabel
        : l10n.budgetsEnvelopeUnassignedLabel;
    final headlineAmount = money.formatSymbol(
      unassigned.abs(),
      currencyCode: summary.currency,
    );
    final nudge = summary.isAllAssigned
        ? l10n.budgetsEnvelopeAllAssigned
        : summary.isOverAssigned
            ? l10n.budgetsEnvelopeNudgeOver(headlineAmount)
            : l10n.budgetsEnvelopeNudge(headlineAmount);

    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: colors.textSecondary,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const EnvelopeModePill(),
              EnvelopeInfoButton(onPressed: onInfo),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            headlineLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            headlineAmount,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          BudgetProgressBar(
            fraction: summary.assignedFraction,
            overspent: false,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.budgetsEnvelopeIncome(
                    money.formatSymbol(
                      summary.incomeMinor,
                      currencyCode: summary.currency,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: captionStyle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.budgetsEnvelopeAssigned(
                    money.formatSymbol(
                      summary.assignedMinor,
                      currencyCode: summary.currency,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: captionStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          EnvelopeNudgeStrip(message: nudge),
        ],
      ),
    );
  }
}

/// The hero's circular info button (`YXLex`): the entry point to the
/// "¿Qué es el modo sobres?" sheet.
class EnvelopeInfoButton extends StatelessWidget {
  const EnvelopeInfoButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).envelopeInfoTitle,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(LucideIcons.info, size: 16, color: colors.textSecondary),
        ),
      ),
    );
  }
}
