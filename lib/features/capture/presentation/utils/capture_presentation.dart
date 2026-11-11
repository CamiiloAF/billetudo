import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../cubit/capture_review_item.dart';

/// The amount label of a pending capture (`Rhix1`).
///
/// Deliberately **not** `signedAmountLabel`: the frame prints an expense
/// capture unsigned (`$58.470`) and only an income keeps its `+`. A `-` would
/// read as money already subtracted, which is exactly what a capture is not.
/// The attenuation to `$text-secondary` is the widget's job, not this
/// function's.
String captureAmountLabel({
  required int amountMinor,
  required String currencyCode,
  required TransactionType type,
}) {
  final formatted = const MoneyFormatter().formatSymbol(
    amountMinor,
    currencyCode: currencyCode,
  );
  return type == TransactionType.income ? '+$formatted' : formatted;
}

/// "Hoy, 8:32 a. m." — the day, relative when it is today or yesterday, plus
/// the time the issuer said the movement was posted.
///
/// [localeName] defaults to `es_CO` so the capture cards keep their committed
/// goldens; surfaces whose approved copy is lower-case after a colon (the
/// "última captura" footers: "Última captura: hoy, 9:19 a. m.") pass
/// [lowercaseRelativeDay] and their own locale, so an English build prints
/// "Last capture: today, 9:19 AM" instead of the Spanish format.
String captureWhenLabel(
  AppLocalizations l10n,
  DateTime postedAt, {
  String? localeName,
  bool lowercaseRelativeDay = false,
}) {
  final String locale = localeName ?? 'es_CO';
  final String renderedDay = _captureDayLabel(
    l10n,
    postedAt,
    localeName: locale,
    lowercaseRelativeDay: lowercaseRelativeDay,
  );
  return '$renderedDay, ${DateFormat('h:mm a', locale).format(postedAt)}';
}

/// The day-only half of [captureWhenLabel] ("hoy" / "ayer" / "7 de agosto").
///
/// The permanent Ajustes row ("Activa · última captura hoy") only has room for
/// the day, but it must say it the same way the cards and the sheet already
/// do, so it renders through the same formatter instead of a second relative
/// date helper. Relative labels come out lower-case because they follow a
/// middot, not a sentence start.
String captureRelativeDayLabel(
  AppLocalizations l10n,
  DateTime date, {
  required String localeName,
}) =>
    _captureDayLabel(
      l10n,
      date,
      localeName: localeName,
      lowercaseRelativeDay: true,
    );

String _captureDayLabel(
  AppLocalizations l10n,
  DateTime date, {
  required String localeName,
  required bool lowercaseRelativeDay,
}) {
  final today = DateUtils.dateOnly(clock.now());
  final day = DateUtils.dateOnly(date);
  final String dayLabel;
  if (DateUtils.isSameDay(day, today)) {
    dayLabel = l10n.transactionsGroupToday;
  } else if (DateUtils.isSameDay(
      day, today.subtract(const Duration(days: 1)))) {
    dayLabel = l10n.transactionsGroupYesterday;
  } else {
    dayLabel = DateFormat("d 'de' MMMM", localeName).format(day);
  }
  // Only the relative labels are lower-cased; a month name is a proper noun
  // in the approved copy ("7 de agosto") and must keep its capital.
  final bool isRelativeDay = dayLabel == l10n.transactionsGroupToday ||
      dayLabel == l10n.transactionsGroupYesterday;
  return lowercaseRelativeDay && isRelativeDay
      ? '${dayLabel[0].toLowerCase()}${dayLabel.substring(1)}'
      : dayLabel;
}

/// The footer under the degraded captures section (`VW54R`, HU-09): when the
/// listener last produced a capture, or the line that explains that nothing
/// ever arrived.
///
/// The date reuses [captureWhenLabel], the same relative "hoy, 9:19 a. m."
/// format the capture cards already print, so the section does not invent a
/// second way of saying when something happened.
String captureBackgroundLastCaptureLabel(
  AppLocalizations l10n,
  DateTime? lastCaptureAt, {
  required String localeName,
}) =>
    lastCaptureAt == null
        ? l10n.captureBackgroundNoCaptureYet
        : l10n.captureBackgroundLastCapture(
            captureWhenLabel(
              l10n,
              lastCaptureAt,
              localeName: localeName,
              lowercaseRelativeDay: true,
            ),
          );

/// The sheet's footer (`TPLPN`): the same "última captura" fact plus the line
/// that keeps the app from promising a hundred percent capture — if a notice
/// never arrives, the user can still record it by hand.
String captureBackgroundSheetFooterLabel(
  AppLocalizations l10n,
  DateTime? lastCaptureAt, {
  required String localeName,
}) =>
    lastCaptureAt == null
        ? l10n.captureBackgroundSheetFooterNoCapture
        : l10n.captureBackgroundSheetFooter(
            captureWhenLabel(
              l10n,
              lastCaptureAt,
              localeName: localeName,
              lowercaseRelativeDay: true,
            ),
          );

/// The icon inside a capture card's tile (`W5UTdc`).
///
/// An income shows the incoming arrow; everything else keeps `bell-ring`, the
/// mark of "this arrived as a notice, it is not a movement yet". The frame
/// also draws an outgoing arrow on one specific mockup row (a Bre-B
/// transfer), but nothing on `PendingCapture` distinguishes that from an
/// ordinary expense — a capture can never be a `transfer` — so deriving it
/// would mean guessing from the merchant text.
IconData captureIcon(TransactionType type) => type == TransactionType.income
    ? LucideIcons.arrowDownLeft
    : LucideIcons.bellRing;

/// The compare strip's verdict line (`ZUmyl`, HU-07): "Mismo monto · 3
/// minutos antes · misma cuenta" — the calculated fact that actually resolves
/// the case, not just a restatement of the two rows above it.
///
/// The amount clause is unconditional: [CaptureDuplicateView] only exists for
/// a candidate that already matched on amount and currency. The account
/// clause is dropped, never printed as a mismatch, when
/// [CaptureDuplicateView.accountMatches] is `false` — the account is itself a
/// guess (HU-03), so a mismatch there is not evidence against the duplicate.
String captureDuplicateVerdict(
  AppLocalizations l10n, {
  required DateTime capturePostedAt,
  required CaptureDuplicateView duplicate,
}) {
  final diffMinutes = capturePostedAt.difference(duplicate.date).inMinutes;
  final minutesPart = diffMinutes >= 0
      ? l10n.captureDuplicateVerdictMinutesBefore(diffMinutes)
      : l10n.captureDuplicateVerdictMinutesAfter(-diffMinutes);
  return [
    l10n.captureDuplicateVerdictSameAmount,
    minutesPart,
    if (duplicate.accountMatches) l10n.captureDuplicateVerdictSameAccount,
  ].join(' · ');
}

/// "categoría · cuenta · fecha-hora" line of the existing transaction in the
/// compare strip (`G6iQN`). The category is named in text, never conveyed
/// only by an icon's color — HU-07's requirement.
String captureDuplicateExistingLine(
  AppLocalizations l10n,
  CaptureDuplicateView duplicate,
) =>
    l10n.captureDuplicateExistingSubtitle(
      duplicate.categoryName ?? l10n.captureDuplicateNoCategory,
      duplicate.accountName ?? l10n.captureNoAccount,
      captureWhenLabel(l10n, duplicate.date),
    );

/// "Un solo pago · Google Wallet + Bancolombia" (`vteXS`) — the only thing
/// that tells the user why one card shows up when their phone rang twice.
/// `null` legs fall back to a neutral placeholder rather than inventing a
/// brand name neither notification carried.
String captureGroupSourceLabel(
  AppLocalizations l10n,
  CaptureGroupView group,
) =>
    l10n.captureGroupedSourceLabel(
      group.walletIssuerName ?? l10n.captureIssuerUnknown,
      group.bankIssuerName ?? l10n.captureIssuerUnknown,
    );
