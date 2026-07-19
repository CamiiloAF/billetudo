import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/app_settings_cubit.dart';
import '../cubit/app_settings_state.dart';
import '../widgets/envelope_mode_field.dart';
import '../widgets/settings_field.dart';
import '../widgets/settings_section_label.dart';
import '../widgets/settings_session_card.dart';
import '../widgets/sheets/envelope_info_sheet.dart';

/// Ajustes (`jDaUb` sin sesión / `aaQBp` con sesión): "Cuenta y respaldo" +
/// "Preferencias", closing on "Eliminar cuenta" pushed to the very bottom of
/// the screen — never mixed in with routine settings.
///
/// "Cerrar sesión" is **not** here: it moved to "Más" (a higher-level action
/// that shouldn't require going into Ajustes first — see
/// `design-system/billetudo/pages/auth.md`).
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.onOpenLogin,
    required this.onOpenDeleteAccount,
    required this.onOpenComingSoon,
    super.key,
  });

  final VoidCallback onOpenLogin;
  final VoidCallback onOpenDeleteAccount;
  final ValueChanged<String> onOpenComingSoon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.settingsTitle),
            Expanded(
              child: BlocBuilder<AuthCubit, AuthSession>(
                builder: (context, session) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      SettingsSectionLabel(l10n.settingsAccountSection),
                      if (session.isSignedIn)
                        SettingsSessionCard(session: session, l10n: l10n)
                      else
                        SettingsField(
                          icon: LucideIcons.cloudUpload,
                          label: l10n.settingsBackupTitle,
                          sublabel: l10n.settingsBackupSubtitle,
                          onTap: onOpenLogin,
                        ),
                      const SizedBox(height: 20),
                      SettingsSectionLabel(l10n.settingsPreferencesSection),
                      SettingsField(
                        icon: LucideIcons.palette,
                        label: l10n.settingsAppearance,
                        onTap: () => onOpenComingSoon(l10n.settingsAppearance),
                      ),
                      SettingsField(
                        icon: LucideIcons.badgeDollarSign,
                        label: l10n.settingsCurrency,
                        sublabel: l10n.settingsCurrencySubtitle,
                        onTap: () => onOpenComingSoon(l10n.settingsCurrency),
                      ),
                      BlocBuilder<AppSettingsCubit, AppSettingsState>(
                        builder: (context, settings) => EnvelopeModeField(
                          enabled: settings.zeroBasedEnabled,
                          onChanged: (value) => unawaited(
                            context
                                .read<AppSettingsCubit>()
                                .setZeroBasedEnabled(value),
                          ),
                          onWhatIs: () =>
                              unawaited(EnvelopeInfoSheet.show(context)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Material(
                        color: colors.expenseSoft,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: onOpenDeleteAccount,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.trash,
                                    size: 20,
                                    color: colors.expense,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.settingsDeleteAccount,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: colors.expenseText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevronRight,
                                  color: colors.expenseText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
