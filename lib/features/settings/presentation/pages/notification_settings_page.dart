import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/notification_settings_cubit.dart';
import '../widgets/notification_settings_section.dart';

/// "Notificaciones" (`z8RdTm`): the per-kind notice preferences, reached from
/// the Ajustes ▸ Preferencias row.
///
/// A stacked screen with a `Page Header` and no `Tab Bar`, moved out of
/// Ajustes' own scroll: the granularity lives here so the settings list stays
/// a list of destinations instead of growing four switches inline.
///
/// Watches the app lifecycle to re-read the OS permission on resume — the
/// user leaves for the phone's settings and comes back, and the OS gives no
/// callback for it. Without this the "permiso denegado" strip would survive a
/// permission the user just granted.
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<NotificationSettingsCubit>().refreshPermission());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.settingsNotifications),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 28),
                child: NotificationSettingsSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
