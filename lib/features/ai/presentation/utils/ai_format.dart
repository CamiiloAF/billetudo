import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/sync/presentation/utils/sync_relative_time.dart';

/// Shared, localized formatting for the assistant's history/chat screens.
abstract final class AiFormat {
  const AiFormat._();

  /// A `Conversation Row`'s meta line (`billetudo.pen` `cBizM`): "Hace 2
  /// horas" the same day, "Ayer" the day before, "Hace 3 días" within the
  /// week (both via [SyncRelativeTime], so this never invents a second copy
  /// of the same duration strings), and a compact "20 jul" date beyond that.
  static String conversationTimestamp(
    BuildContext context,
    AppLocalizations l10n,
    DateTime updatedAt,
  ) {
    final now = clock.now();
    if (_isSameDay(now, updatedAt)) {
      return SyncRelativeTime.since(l10n, updatedAt, now: now);
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(yesterday, updatedAt)) {
      return l10n.aiHistoryRowYesterday;
    }
    if (now.difference(updatedAt).inDays < 7) {
      return SyncRelativeTime.since(l10n, updatedAt, now: now);
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d MMM', locale).format(updatedAt);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
