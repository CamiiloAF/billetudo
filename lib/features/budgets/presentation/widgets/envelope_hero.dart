import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/zero_based_summary.dart';

/// The "Modo sobres" hero on top of the budgets list (HU-06): the amount still
/// **unassigned** (income − assigned), with a caption breaking it down.
///
/// "Sin asignar" tends to zero but never blocks anything — it is guidance, not
/// an obstacle. Tone stays positive: at zero it celebrates ("Cada peso tiene un
/// trabajo"), and over-assigning is stated neutrally, never as a scolding. Uses
/// the sober `$primary` family only — no traffic-light colors.
class EnvelopeHero extends StatelessWidget {
  const EnvelopeHero({required this.summary, super.key});

  final ZeroBasedSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    const money = MoneyFormatter();
    final unassigned = summary.unassignedMinor;
    final isAllAssigned = unassigned == 0;
    final isOverAssigned = unassigned < 0;

    final headlineLabel = isOverAssigned
        ? l10n.budgetsEnvelopeOverLabel
        : l10n.budgetsEnvelopeUnassignedLabel;
    final headlineAmount = money.formatSymbol(
      unassigned.abs(),
      currencyCode: summary.currency,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headlineLabel,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.primaryOnSoftStrong),
          ),
          const SizedBox(height: 4),
          Text(
            headlineAmount,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.primaryOnSoftStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAllAssigned
                ? l10n.budgetsEnvelopeAllAssigned
                : l10n.budgetsEnvelopeCaption(
                    money.formatSymbol(
                      summary.incomeMinor,
                      currencyCode: summary.currency,
                    ),
                    money.formatSymbol(
                      summary.assignedMinor,
                      currencyCode: summary.currency,
                    ),
                  ),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.primaryOnSoft),
          ),
        ],
      ),
    );
  }
}
