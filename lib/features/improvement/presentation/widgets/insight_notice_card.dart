import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/insight.dart';
import 'notice_card.dart';

/// Renders one [Insight] as a [NoticeCard] (`Bk8zW`/`Z38Eox`).
///
/// The entity carries **facts, not sentences** — name, amount in minor units,
/// day count, percentage — so every word on screen is assembled here from
/// `AppLocalizations`. Domain has no business holding UI text, and the same
/// insight has to read differently in Spanish and in English.
class InsightNoticeCard extends StatelessWidget {
  const InsightNoticeCard({
    required this.insight,
    required this.onOpen,
    required this.onDismiss,
    super.key,
  });

  final Insight insight;

  /// Opens what the insight is about: the template for a charge or a pending
  /// occurrence, the goal for a milestone.
  final ValueChanged<Insight> onOpen;

  /// "Recordar después" / "Todavía no": puts the card away for now. Never
  /// offered on a milestone — there is nothing to postpone about something
  /// that already happened.
  final ValueChanged<Insight> onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final amount = _amount();

    return switch (insight.type) {
      InsightType.upcomingCharge => NoticeCard(
          icon: LucideIcons.calendarClock,
          iconColor: colors.sky,
          iconBackground: colors.skySoft,
          title: _upcomingChargeTitle(l10n),
          subtitle: l10n.insightUpcomingChargeSubtitle(amount),
          primaryActionLabel: l10n.insightActionViewPayment,
          onPrimaryAction: () => onOpen(insight),
          secondaryActionLabel: l10n.insightActionRemindLater,
          onSecondaryAction: () => onDismiss(insight),
        ),
      InsightType.pendingConfirmation => NoticeCard(
          icon: LucideIcons.circleCheckBig,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: _pendingConfirmationTitle(l10n),
          subtitle: l10n.insightPendingConfirmationSubtitle(amount),
          primaryActionLabel: l10n.insightActionConfirmPayment,
          onPrimaryAction: () => onOpen(insight),
          secondaryActionLabel: l10n.insightActionNotYet,
          onSecondaryAction: () => onDismiss(insight),
        ),
      InsightType.goalMilestone => NoticeCard(
          icon: LucideIcons.partyPopper,
          iconColor: colors.mint,
          iconBackground: colors.mintSoft,
          title: insight.isGoalCompletion
              ? l10n.insightGoalCompletedTitle(insight.subject)
              : l10n.insightGoalMilestoneTitle(
                  insight.subject,
                  insight.progressPercent ?? 0,
                ),
          subtitle: l10n.insightGoalMilestoneBody(amount, _target()),
          primaryActionLabel: l10n.insightActionViewGoal,
          onPrimaryAction: () => onOpen(insight),
        ),
    };
  }

  /// "Netflix se cobra hoy / mañana / en 3 días". The day count moves into
  /// the title because that is the fact the card is about; the amount goes
  /// below it.
  String _upcomingChargeTitle(AppLocalizations l10n) {
    final days = insight.daysUntil ?? 0;
    if (days <= 0) {
      return l10n.insightUpcomingChargeTitleToday(insight.subject);
    }
    if (days == 1) {
      return l10n.insightUpcomingChargeTitleTomorrow(insight.subject);
    }
    // gen-l10n orders positional placeholders alphabetically: (days, name).
    return l10n.insightUpcomingChargeTitleInDays(days, insight.subject);
  }

  /// "El arriendo estaba programado para ayer". Past tense on purpose: it
  /// states what the calendar said, it does not scold anyone for not having
  /// confirmed it yet.
  String _pendingConfirmationTitle(AppLocalizations l10n) {
    // `daysUntil` is 0 or negative here: the occurrence is already due.
    final daysAgo = -(insight.daysUntil ?? 0);
    if (daysAgo <= 0) {
      return l10n.insightPendingConfirmationTitleToday(insight.subject);
    }
    if (daysAgo == 1) {
      return l10n.insightPendingConfirmationTitleYesterday(insight.subject);
    }
    return l10n.insightPendingConfirmationTitleDaysAgo(
      daysAgo,
      insight.subject,
    );
  }

  // Every insight that reaches a card carries its currency; `?? 'COP'` is the
  // same fallback the sync detail sheet uses, not a real code path.
  String _amount() => const MoneyFormatter().formatSymbol(
        insight.amountMinor ?? 0,
        currencyCode: insight.currency ?? 'COP',
      );

  String _target() => const MoneyFormatter().formatSymbol(
        insight.targetAmountMinor ?? 0,
        currencyCode: insight.currency ?? 'COP',
      );
}
