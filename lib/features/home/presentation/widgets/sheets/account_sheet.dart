import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_menu_row.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_state.dart';
import 'account_sheet_backup_card.dart';
import 'account_sheet_hero_card.dart';
import 'account_sheet_list_card.dart';
import 'sign_out_row.dart';

/// "Tu cuenta" (`design-system/billetudo/pages/inicio.md` § "Hoja de
/// cuenta", issue #34: Propuesta B "hero + lista", nodeId `svGeu`/`mwnHe`
/// base, `AkTan`/`Z95Se7` sincronizado, `e0c5v8`/`aRNMx` sin cuenta):
///
/// - **Hero Card**: signed-in shows the avatar (its own status badge
///   switched off), name and a status pill; "sin cuenta" shows a backup
///   invite (icon + copy + CTA) instead.
/// - **List Card**: "Estado de sincronización" + "Ajustes" rows, separated
///   by a divider — only "Ajustes" survives without a session.
/// - **"Cerrar sesión"**: a bare link below the List Card, signed-in only.
///
/// Reactive like `SyncStatusSheet`: a [BlocBuilder] over the shared
/// [HomeCubit] keeps the pill/rows current while the sheet stays open.
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
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.user != current.user ||
          previous.syncStatus != current.syncStatus,
      builder: (context, state) {
        final user = state.user;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user == null)
              AccountSheetBackupCard(
                onActivateBackup: () {
                  Navigator.of(context).pop();
                  onActivateBackup();
                },
              )
            else
              AccountSheetHeroCard(
                user: user,
                synced: state.syncStatus != HomeSyncStatus.attention,
              ),
            const SizedBox(height: 16),
            AccountSheetListCard(
              rows: [
                if (user != null)
                  SheetMenuRow(
                    icon: LucideIcons.refreshCw,
                    label: l10n.settingsSyncStatus,
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenSyncStatus();
                    },
                  ),
                SheetMenuRow(
                  icon: LucideIcons.settings,
                  label: l10n.moreSettings,
                  onTap: () {
                    Navigator.of(context).pop();
                    onOpenSettings();
                  },
                ),
              ],
            ),
            if (user != null) ...[
              const SizedBox(height: 16),
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
