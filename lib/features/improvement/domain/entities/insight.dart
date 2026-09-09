import 'package:equatable/equatable.dart';

import '../../../../core/notifications/domain/entities/notification_kind.dart';

/// The kinds of **terminal** insight billetudo derives locally.
///
/// Terminal means self-contained: "Netflix se cobra en 3 días" closes the
/// question it answers. Open insights ("llevás 60% más en mercado que tu
/// promedio") are not here — those belong to the assistant card in Inicio,
/// where continuing the conversation is the natural next step
/// (`docs/requirements/fase-3/22-centro-notificaciones.md`).
///
/// Deliberately absent: "suscripción detectada". It is a heuristic over
/// merchant/amount/cadence with guaranteed false positives, and a wrong
/// insight destroys more trust than a good one builds.
enum InsightType {
  /// A scheduled payment coming due inside the horizon.
  upcomingCharge(NotificationKind.upcomingCharges),

  /// A manual-mode occurrence already due and waiting for confirmation.
  pendingConfirmation(NotificationKind.pendingConfirmations),

  /// A goal that crossed a celebration threshold. Positive reinforcement.
  goalMilestone(NotificationKind.goalMilestones);

  const InsightType(this.notificationKind);

  /// The Ajustes switch that governs this type.
  final NotificationKind notificationKind;
}

/// One locally-derived, terminal insight.
///
/// **Structured, not pre-rendered.** The entity carries the raw facts
/// (subject name, amount in minor units, day count, percentage) and never a
/// localized sentence: the copy belongs to `AppLocalizations`, and domain has
/// no business holding UI text. The notification center formats it.
///
/// [id] is stable and derived from what the insight is *about*, so the same
/// fact does not appear twice, and a "already shown/dismissed" store can key
/// on it later without a schema change today.
class Insight extends Equatable {
  const Insight({
    required this.id,
    required this.type,
    required this.subject,
    required this.relevantOn,
    required this.targetId,
    this.amountMinor,
    this.currency,
    this.daysUntil,
    this.progressPercent,
    this.targetAmountMinor,
  });

  final String id;
  final InsightType type;

  /// The user's own name for the thing (template note, goal name). Never a
  /// translated string — it is their data.
  final String subject;

  /// The date the insight is about (the due date, the milestone date). Used
  /// for ordering and for expiry: an insight whose moment passed stops being
  /// derived, which is exactly why this lives in a notification center and
  /// not in a permanent Home card.
  final DateTime relevantOn;

  /// Id of the entity to open when the card is tapped (template id, goal id).
  final String targetId;

  /// Always minor units. Null when the insight is not about an amount.
  final int? amountMinor;
  final String? currency;

  /// Whole days from today to [relevantOn]; 0 means today. Null when the
  /// insight is not time-relative.
  final int? daysUntil;

  /// 0-100 progress, only for [InsightType.goalMilestone].
  final int? progressPercent;

  /// The goal's target, so the card can read "llevás X de Y".
  final int? targetAmountMinor;

  /// Whether this milestone is the goal being finished, rather than an
  /// intermediate threshold.
  bool get isGoalCompletion =>
      type == InsightType.goalMilestone && progressPercent == 100;

  @override
  List<Object?> get props => [
        id,
        type,
        subject,
        relevantOn,
        targetId,
        amountMinor,
        currency,
        daysUntil,
        progressPercent,
        targetAmountMinor,
      ];
}
