import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/notifications/domain/entities/notification_kind.dart';
import '../cubit/notification_settings_cubit.dart';
import '../cubit/notification_settings_state.dart';
import 'notification_kind_field.dart';
import 'settings_section_label.dart';

/// The "Avisos" block of Ajustes: one switch per kind of notice.
///
/// Per-type control rather than a single master switch, because notification
/// fatigue is what kills this kind of feature: someone who does not want goal
/// celebrations must be able to drop exactly those and keep the due-date
/// reminders they configured on purpose. An all-or-nothing switch turns that
/// into "turn everything off".
class NotificationSettingsSection extends StatelessWidget {
  const NotificationSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationSettingsCubit>();
        final rows = <(NotificationKind, IconData, String, String)>[
          (
            NotificationKind.paymentReminders,
            LucideIcons.bellRing,
            l10n.notificationsSettingsPaymentReminders,
            l10n.notificationsSettingsPaymentRemindersSubtitle,
          ),
          (
            NotificationKind.upcomingCharges,
            LucideIcons.calendarClock,
            l10n.notificationsSettingsUpcomingCharges,
            l10n.notificationsSettingsUpcomingChargesSubtitle,
          ),
          (
            NotificationKind.pendingConfirmations,
            LucideIcons.circleCheck,
            l10n.notificationsSettingsPendingConfirmations,
            l10n.notificationsSettingsPendingConfirmationsSubtitle,
          ),
          (
            NotificationKind.goalMilestones,
            LucideIcons.partyPopper,
            l10n.notificationsSettingsGoalMilestones,
            l10n.notificationsSettingsGoalMilestonesSubtitle,
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionLabel(l10n.settingsNotificationsSection),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              NotificationKindField(
                icon: rows[i].$2,
                label: rows[i].$3,
                sublabel: rows[i].$4,
                enabled: state.isEnabled(rows[i].$1),
                onChanged: (value) => unawaited(
                  cubit.setEnabled(rows[i].$1, enabled: value),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
