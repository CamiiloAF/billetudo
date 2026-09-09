import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/notifications/domain/entities/notification_kind.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/toggle_field.dart';
import '../cubit/notification_settings_cubit.dart';
import '../cubit/notification_settings_state.dart';
import 'notification_permission_denied_notice.dart';

/// The body of the "Notificaciones" screen (`z8RdTm`, and `VkWqs` for the
/// denied-permission variant): one `Toggle Field` per kind of notice.
///
/// Per-type control rather than a single master switch, because notification
/// fatigue is what kills this kind of feature: someone who does not want goal
/// celebrations must be able to drop exactly those and keep the due-date
/// reminders they configured on purpose. An all-or-nothing switch turns that
/// into "turn everything off" — and turning everything off stays a valid
/// choice the app never nags about.
class NotificationSettingsSection extends StatelessWidget {
  const NotificationSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationSettingsCubit>();
        final denied = !state.permissionGranted;
        final rows = <(NotificationKind, IconData, String, String)>[
          (
            NotificationKind.paymentReminders,
            LucideIcons.calendarClock,
            l10n.notificationsSettingsPaymentReminders,
            l10n.notificationsSettingsPaymentRemindersSubtitle,
          ),
          (
            NotificationKind.upcomingCharges,
            LucideIcons.bellRing,
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
            LucideIcons.target,
            l10n.notificationsSettingsGoalMilestones,
            l10n.notificationsSettingsGoalMilestonesSubtitle,
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (denied) ...[
              NotificationPermissionDeniedNotice(
                onOpenSystemSettings: () =>
                    unawaited(cubit.openSystemSettings()),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              // Two different intros on purpose: with the permission denied
              // the useful thing to say is that nothing was lost, not how the
              // switches work.
              denied
                  ? l10n.notificationsSettingsDeniedIntro
                  : l10n.notificationsSettingsIntro,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.colors.textSecondary,
                height: 1.45,
              ),
            ),
            for (var i = 0; i < rows.length; i++) ...[
              const SizedBox(height: 12),
              ToggleField(
                icon: rows[i].$2,
                label: rows[i].$3,
                hint: rows[i].$4,
                value: state.isEnabled(rows[i].$1),
                // Inert, not dimmed and not forced off in storage: the stored
                // preference survives untouched and comes back exactly as it
                // was when the permission returns.
                inert: denied,
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
