import 'package:flutter/widgets.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/tutorial_content.dart';
import '../../domain/entities/tutorial_key.dart';

/// Resolves a [TutorialKey] to its localized [TutorialContent] — the "content
/// map" `TutorialContent`'s own class doc refers to. Every one of the 12
/// tutorials' copy comes only from `AppLocalizations` (never a hardcoded
/// literal), per `docs/requirements/fase-1/16-minitutoriales.md`'s "Localizados
/// (es + en)" rule.
///
/// Pure mapping, no state: safe to call from any `build()`.
abstract final class TutorialContentCatalog {
  const TutorialContentCatalog._();

  static TutorialContent of(BuildContext context, TutorialKey key) {
    final l10n = AppLocalizations.of(context);
    return switch (key) {
      TutorialKey.budgetsScreen => TutorialContent(
          key: key,
          title: l10n.tutorialBudgetsTitle,
          iconName: 'wallet',
          points: [
            TutorialPoint(
              heading: l10n.tutorialBudgetsPoint1Heading,
              body: l10n.tutorialBudgetsPoint1Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialBudgetsPoint2Heading,
              body: l10n.tutorialBudgetsPoint2Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialBudgetsPoint3Heading,
              body: l10n.tutorialBudgetsPoint3Body,
            ),
          ],
          ctaLabel: l10n.tutorialBudgetsCta,
        ),
      TutorialKey.goalsScreen => TutorialContent(
          key: key,
          title: l10n.tutorialGoalsTitle,
          iconName: 'target',
          points: [
            TutorialPoint(
              heading: l10n.tutorialGoalsPoint1Heading,
              body: l10n.tutorialGoalsPoint1Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialGoalsPoint2Heading,
              body: l10n.tutorialGoalsPoint2Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialGoalsPoint3Heading,
              body: l10n.tutorialGoalsPoint3Body,
            ),
          ],
          ctaLabel: l10n.tutorialGoalsCta,
        ),
      TutorialKey.debtsScreen => TutorialContent(
          key: key,
          title: l10n.tutorialDebtsTitle,
          iconName: 'landmark',
          points: [
            TutorialPoint(
              heading: l10n.tutorialDebtsPoint1Heading,
              body: l10n.tutorialDebtsPoint1Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialDebtsPoint2Heading,
              body: l10n.tutorialDebtsPoint2Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialDebtsPoint3Heading,
              body: l10n.tutorialDebtsPoint3Body,
            ),
          ],
          ctaLabel: l10n.tutorialDebtsCta,
        ),
      TutorialKey.scheduledPaymentsScreen => TutorialContent(
          key: key,
          title: l10n.tutorialScheduledPaymentsTitle,
          iconName: 'calendar-clock',
          points: [
            TutorialPoint(
              heading: l10n.tutorialScheduledPaymentsPoint1Heading,
              body: l10n.tutorialScheduledPaymentsPoint1Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialScheduledPaymentsPoint2Heading,
              body: l10n.tutorialScheduledPaymentsPoint2Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialScheduledPaymentsPoint3Heading,
              body: l10n.tutorialScheduledPaymentsPoint3Body,
            ),
          ],
          ctaLabel: l10n.tutorialScheduledPaymentsCta,
        ),
      TutorialKey.debtLinkMovement => TutorialContent(
          key: key,
          title: l10n.tutorialDebtLinkMovementTitle,
          iconName: 'link',
          points: [
            TutorialPoint(
              heading: l10n.tutorialDebtLinkMovementPoint1Heading,
              body: l10n.tutorialDebtLinkMovementPoint1Body,
            ),
          ],
        ),
      TutorialKey.goalLinkMovement => TutorialContent(
          key: key,
          title: l10n.tutorialGoalLinkMovementTitle,
          iconName: 'link',
          points: [
            TutorialPoint(
              heading: l10n.tutorialGoalLinkMovementPoint1Heading,
              body: l10n.tutorialGoalLinkMovementPoint1Body,
            ),
          ],
        ),
      TutorialKey.debtPaymentToggle => TutorialContent(
          key: key,
          title: l10n.tutorialDebtPaymentToggleTitle,
          iconName: 'hand-coins',
          points: [
            TutorialPoint(
              heading: l10n.tutorialDebtPaymentTogglePoint1Heading,
              body: l10n.tutorialDebtPaymentTogglePoint1Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialDebtPaymentTogglePoint2Heading,
              body: l10n.tutorialDebtPaymentTogglePoint2Body,
            ),
          ],
        ),
      TutorialKey.goalContributionToggle => TutorialContent(
          key: key,
          title: l10n.tutorialGoalContributionToggleTitle,
          iconName: 'arrow-left-right',
          points: [
            TutorialPoint(
              heading: l10n.tutorialGoalContributionTogglePoint1Heading,
              body: l10n.tutorialGoalContributionTogglePoint1Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialGoalContributionTogglePoint2Heading,
              body: l10n.tutorialGoalContributionTogglePoint2Body,
            ),
          ],
        ),
      TutorialKey.debtScheduledInstallment => TutorialContent(
          key: key,
          title: l10n.tutorialDebtScheduledInstallmentTitle,
          iconName: 'calendar-clock',
          points: [
            TutorialPoint(
              heading: l10n.tutorialDebtScheduledInstallmentPoint1Heading,
              body: l10n.tutorialDebtScheduledInstallmentPoint1Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialDebtScheduledInstallmentPoint2Heading,
              body: l10n.tutorialDebtScheduledInstallmentPoint2Body,
            ),
          ],
        ),
      TutorialKey.budgetableTransfer => TutorialContent(
          key: key,
          title: l10n.tutorialBudgetableTransferTitle,
          iconName: 'wallet',
          points: [
            TutorialPoint(
              heading: l10n.tutorialBudgetableTransferPoint1Heading,
              body: l10n.tutorialBudgetableTransferPoint1Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialBudgetableTransferPoint2Heading,
              body: l10n.tutorialBudgetableTransferPoint2Body,
            ),
          ],
        ),
      TutorialKey.envelopeMode => TutorialContent(
          key: key,
          title: l10n.tutorialEnvelopeModeTitle,
          iconName: 'target',
          points: [
            TutorialPoint(
              heading: l10n.tutorialEnvelopeModePoint1Heading,
              body: l10n.tutorialEnvelopeModePoint1Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialEnvelopeModePoint2Heading,
              body: l10n.tutorialEnvelopeModePoint2Body,
            ),
          ],
        ),
      TutorialKey.budgetFeaturedChoice => TutorialContent(
          key: key,
          title: l10n.tutorialBudgetFeaturedChoiceTitle,
          iconName: 'star',
          points: [
            TutorialPoint(
              heading: l10n.tutorialBudgetFeaturedChoicePoint1Heading,
              body: l10n.tutorialBudgetFeaturedChoicePoint1Body,
            ),
            TutorialPoint(
              heading: l10n.tutorialBudgetFeaturedChoicePoint2Heading,
              body: l10n.tutorialBudgetFeaturedChoicePoint2Body,
            ),
          ],
        ),
    };
  }
}
