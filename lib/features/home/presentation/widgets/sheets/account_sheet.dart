import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_state.dart';
import 'account_sync_block.dart';
import 'identity_row.dart';
import 'no_account_invite.dart';
import 'settings_row.dart';
import 'sign_out_row.dart';

/// "Tu cuenta" (`design-system/billetudo/pages/inicio.md` § "Hoja de
/// cuenta"), opened by tapping the header's avatar: Identity Row + a compact
/// sync block (reusing `SyncHero`, never a parallel component) + "Ajustes" +
/// "Cerrar sesión" — the last two absent for the "sin cuenta" variant, which
/// shows an "Activar respaldo" invite instead.
///
/// Reactive like `SyncStatusSheet`: a [BlocBuilder] over the shared
/// [HomeCubit] keeps the sync block current while the sheet stays open.
class AccountSheet extends StatelessWidget {
  const AccountSheet({
    required this.onOpenSettings,
    required this.onSignOut,
    required this.onOpenSyncStatus,
    required this.onActivateBackup,
    super.key,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onSignOut;
  final VoidCallback onOpenSyncStatus;

  /// The "sin cuenta" variant's CTA — routes to the login/backup flow.
  final VoidCallback onActivateBackup;

  static Future<void> show(
    BuildContext context,
    HomeCubit cubit, {
    required VoidCallback onOpenSettings,
    required VoidCallback onSignOut,
    required VoidCallback onOpenSyncStatus,
    required VoidCallback onActivateBackup,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider<HomeCubit>.value(
          value: cubit,
          child: AccountSheet(
            onOpenSettings: onOpenSettings,
            onSignOut: onSignOut,
            onOpenSyncStatus: onOpenSyncStatus,
            onActivateBackup: onActivateBackup,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.user != current.user ||
          previous.syncStatus != current.syncStatus ||
          previous.syncSnapshot != current.syncSnapshot,
      builder: (context, state) {
        final user = state.user;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeAccountSheetTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            if (user == null)
              NoAccountInvite(
                onActivateBackup: () {
                  Navigator.of(context).pop();
                  onActivateBackup();
                },
              )
            else ...[
              IdentityRow(user: user),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenSyncStatus();
                },
                child: AccountSyncBlock(state: state),
              ),
              const SizedBox(height: 16),
              SettingsRow(
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenSettings();
                },
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              SignOutRow(
                onTap: () {
                  Navigator.of(context).pop();
                  onSignOut();
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
