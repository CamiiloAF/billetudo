import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/settings_field.dart';
import '../cubit/capture_background_cubit.dart';
import '../cubit/capture_background_state.dart';
import '../utils/capture_presentation.dart';
import 'sheets/capture_background_sheet.dart';

/// The permanent "background capture" row in Ajustes (HU-09, `rN8ye` /
/// `lv0iQ`).
///
/// It is the way to check the listener without waiting for Avisos to notice a
/// problem: Avisos only draws its card when there are captures and the
/// rule says so, while this row is always here on Android and states one of
/// five things — checking, missing setup, needing attention, silenced after
/// "Ahora no", or healthy with the last capture.
///
/// It reuses the shared `Appearance Field` (`R8PlN`) instead of a bespoke row,
/// so it keeps Settings' 64pt row, chevron and single semantics node. The
/// icon pair is the component's `$muted`/`$text-secondary` on purpose: this is
/// a status row, not a navigational brand action, and the violet stays
/// reserved elsewhere. Only the attention state borrows `$amber-soft` /
/// `$amber-text`, the product's "needs a look" accent.
///
/// It draws **nothing on iOS**, where notification access does not exist.
///
/// The tap splits by what the user can act on: with no permission or no
/// enabled issuer, the honest next step is setup (permission / issuers), so
/// the row routes there instead of opening a sheet about battery and
/// autostart the user cannot benefit from yet. Otherwise it opens the shared
/// sheet, silenced included.
class CaptureBackgroundField extends StatefulWidget {
  const CaptureBackgroundField({required this.onOpenSetup, super.key});

  /// Routes to the permission explainer (`false`) or the issuer catalog
  /// (`true`). The page owns the routes; the row only knows which of the two
  /// preconditions is missing.
  final ValueChanged<bool> onOpenSetup;

  @override
  State<CaptureBackgroundField> createState() => _CaptureBackgroundFieldState();
}

class _CaptureBackgroundFieldState extends State<CaptureBackgroundField>
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
      unawaited(context.read<CaptureBackgroundCubit>().refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BlocBuilder<CaptureBackgroundCubit, CaptureBackgroundState>(
      builder: (BuildContext context, CaptureBackgroundState state) {
        if (!state.isSupported) {
          return const SizedBox.shrink();
        }

        final AppColors colors = context.colors;
        // Loading wins over every other state: the permission is still
        // `false` while the first probe runs, and drawing "activá primero"
        // during that beat would be wrong. Then setup (its own surface has
        // precedence over attention), then the four settled states.
        final bool attention =
            !state.isLoading && !state.needsSetup && state.showsAttention;
        final IconData icon = switch (state) {
          CaptureBackgroundState(isLoading: true) => LucideIcons.clock,
          CaptureBackgroundState(needsSetup: true) => LucideIcons.bellOff,
          CaptureBackgroundState(showsAttention: true) =>
            LucideIcons.shieldAlert,
          CaptureBackgroundState(isSnoozed: true) => LucideIcons.clock,
          _ => LucideIcons.shieldCheck,
        };
        final String sublabel = switch (state) {
          CaptureBackgroundState(isLoading: true) =>
            l10n.captureBackgroundFieldChecking,
          CaptureBackgroundState(needsSetup: true) =>
            l10n.captureBackgroundFieldNeedsSetup,
          CaptureBackgroundState(showsAttention: true) =>
            l10n.captureBackgroundFieldAttention,
          CaptureBackgroundState(isSnoozed: true) =>
            l10n.captureBackgroundFieldSnoozed,
          CaptureBackgroundState(lastCaptureAt: final DateTime lastCaptureAt) =>
            l10n.captureBackgroundFieldActive(
              captureRelativeDayLabel(
                l10n,
                lastCaptureAt,
                localeName: Localizations.localeOf(context).toLanguageTag(),
              ),
            ),
          _ => l10n.captureBackgroundFieldActiveNoCapture,
        };

        // The 12pt gap belongs to this row, like `CaptureSettingsField`: on
        // iOS the row is not drawn at all and must not leave a hole behind.
        return Column(
          children: <Widget>[
            SettingsField(
              icon: icon,
              label: l10n.captureBackgroundFieldLabel,
              sublabel: sublabel,
              // Only the attention state speaks in amber; every other state
              // is the component's neutral diagnostics pair.
              iconBackground: attention ? colors.amberSoft : colors.muted,
              iconColor: attention ? colors.amberText : colors.textSecondary,
              sublabelColor: attention ? colors.amberText : null,
              onTap: () {
                if (state.needsSetup) {
                  widget.onOpenSetup(state.permissionGranted);
                  return;
                }
                unawaited(CaptureBackgroundSheet.show(context));
              },
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
