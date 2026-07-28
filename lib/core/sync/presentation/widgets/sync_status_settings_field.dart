import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/settings_field.dart';
import '../cubit/sync_status_cubit.dart';
import '../cubit/sync_status_state.dart';
import '../utils/sync_relative_time.dart';

/// The entry point in Ajustes → "Cuenta y respaldo" (`STxah`): the row that
/// carries the last successful sync in its own sublabel.
///
/// It only exists with a session. Without one, Ajustes offers "Respaldar en la
/// nube" instead — there is no cloud to report on, and adding a diagnostics
/// row would turn a clear invitation into a detour.
class SyncStatusSettingsField extends StatelessWidget {
  const SyncStatusSettingsField({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<SyncStatusCubit, SyncStatusState>(
      buildWhen: (previous, current) =>
          previous.snapshot.lastSyncedAt != current.snapshot.lastSyncedAt,
      builder: (context, state) {
        final lastSyncedAt = state.snapshot.lastSyncedAt;
        return SettingsField(
          icon: LucideIcons.refreshCw,
          iconColor: colors.textSecondary,
          iconBackground: colors.muted,
          label: l10n.settingsSyncStatus,
          sublabel: lastSyncedAt == null
              ? l10n.syncNeverSyncedLabel
              : l10n.syncLastSyncLabel(
                  SyncRelativeTime.since(
                    l10n,
                    lastSyncedAt,
                    now: DateTime.now(),
                  ),
                ),
          onTap: onTap,
        );
      },
    );
  }
}
