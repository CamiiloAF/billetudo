import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/settings_field.dart';
import '../cubit/capture_status_cubit.dart';
import '../cubit/capture_status_state.dart';

/// The permanent entry into notification capture, in Ajustes (HU-09).
///
/// **Not designed in `billetudo.pen`.** The zone has the explainer, the off
/// state and the catalog, but no frame for this row, so it is built from the
/// shared `Appearance Field` (`R8PlN`) that every other navigable setting in
/// Ajustes already uses. Flagged for the designer rather than invented as a
/// new component.
///
/// What it must do, and what a stored flag could not: **state the truth**.
/// The permission is asked to the system on every load and on every return to
/// foreground, because the user can revoke notification access from Android
/// without the app hearing a thing. An app that claims to be capturing when
/// it is not is worse than one that captures nothing — every number in
/// Billetudo only ever counts confirmed transactions, so the honest thing
/// here costs nothing.
///
/// It renders **nothing at all** on iOS. Notification access does not exist
/// there and never will, so showing this row disabled behind a padlock would
/// advertise something impossible.
class CaptureSettingsField extends StatefulWidget {
  const CaptureSettingsField({required this.onTap, super.key});

  /// Routes to the catalog when the permission is granted and to the
  /// explainer when it is not — the router decides, since only it knows both
  /// routes.
  final ValueChanged<CaptureStatusState> onTap;

  @override
  State<CaptureSettingsField> createState() => _CaptureSettingsFieldState();
}

class _CaptureSettingsFieldState extends State<CaptureSettingsField>
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
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(context.read<CaptureStatusCubit>().refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BlocBuilder<CaptureStatusCubit, CaptureStatusState>(
      builder: (BuildContext context, CaptureStatusState state) {
        if (!state.isSupported) {
          return const SizedBox.shrink();
        }
        // The 12pt gap belongs to this row rather than to Ajustes: on iOS the
        // row is not drawn at all, and a gap left behind by a widget that
        // renders nothing would open a hole between its neighbours.
        return Column(
          children: <Widget>[
            SettingsField(
              icon: LucideIcons.bellRing,
              label: l10n.captureSettingsTitle,
              sublabel: switch (state) {
                CaptureStatusState(isLoading: true) =>
                  l10n.captureSettingsSubtitleChecking,
                CaptureStatusState(permissionGranted: false) =>
                  l10n.captureSettingsSubtitleOff,
                CaptureStatusState(enabledCount: 0) =>
                  l10n.captureSettingsSubtitleNoIssuers,
                CaptureStatusState(enabledCount: final int count) =>
                  l10n.captureSettingsSubtitleListening(count),
              },
              onTap: () => widget.onTap(state),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
