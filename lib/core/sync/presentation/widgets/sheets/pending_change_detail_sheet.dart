import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/money_formatter.dart';
import '../../../../widgets/bottom_sheet_base.dart';
import '../../../../widgets/sheet_buttons_row.dart';
import '../../cubit/sync_status_cubit.dart';
import '../../models/pending_sync_change.dart';
import '../../utils/sync_relative_time.dart';
import '../sync_time_row.dart';
import 'sync_log_sheet.dart';

/// The detail of one held-back change (`r1qQYc`), opened by tapping its row.
///
/// Content contract: which change it is *in the user's language*, since when
/// it has been waiting, how many attempts it took, the same risk sentence the
/// rest of the family uses, "Reintentar" as the primary action and a
/// secondary way into the technical log.
///
/// Forbidden here: error codes, table names, ISO timestamps. Those live only
/// in the technical log, whose reader is support. There is no "Descartar":
/// nothing in this flow destroys data that only exists on this phone.
class PendingChangeDetailSheet extends StatelessWidget {
  const PendingChangeDetailSheet({required this.change, super.key});

  final PendingSyncChange change;

  /// Opens the sheet wired to the screen's [SyncStatusCubit], so a retry
  /// started here lands in the same state the page is rendering.
  static Future<void> show(
    BuildContext context,
    SyncStatusCubit cubit,
    PendingSyncChange change,
  ) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: PendingChangeDetailSheet(change: change),
        ),
      );

  /// "$ 18.000 · 12 de julio", dropping whichever half the payload did not
  /// carry. Never a fallback made up out of nothing.
  String? _subtitle(AppLocalizations l10n, String locale) {
    final parts = <String>[];
    final amountMinor = change.amountMinor;
    if (amountMinor != null) {
      parts.add(
        const MoneyFormatter().formatSymbol(
          amountMinor,
          currencyCode: change.currencyCode ?? 'COP',
        ),
      );
    }
    final occurredAt = change.occurredAt;
    if (occurredAt != null) {
      // Day and month only: the year adds length (and truncation risk) to a
      // line whose job is to identify a change the user made days ago, not
      // years ago.
      parts.add(DateFormat.MMMMd(locale).format(occurredAt));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final kind = change.kind.label(l10n);
    final title = change.label == null
        ? kind
        : l10n.syncPendingRowTitle(kind, change.label!);
    final subtitle = _subtitle(l10n, locale);
    final waiting = DateTime.now().difference(change.pendingSince);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.amberSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(change.kind.icon, size: 24, color: colors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SyncTimeRow(
          label: l10n.syncDetailWaiting(
            SyncRelativeTime.elapsed(l10n, waiting),
          ),
          color: colors.amberText,
        ),
        const SizedBox(height: 10),
        SyncTimeRow(
          icon: LucideIcons.refreshCw,
          label: l10n.syncDetailAttempts(change.attempts),
          iconColor: colors.textSecondary,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Icon(LucideIcons.cloudOff, size: 18, color: colors.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.syncDetailRisk,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SheetButtonsRow(
          left: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(SyncLogSheet.show(context));
            },
            icon: const Icon(LucideIcons.fileText, size: 18),
            label: Text(l10n.syncTechnicalLogTitle),
          ),
          right: FilledButton.icon(
            onPressed: () {
              final cubit = context.read<SyncStatusCubit>();
              Navigator.of(context).pop();
              unawaited(cubit.retryOne(change.id));
            },
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: Text(l10n.syncDetailRetry),
          ),
        ),
      ],
    );
  }
}
