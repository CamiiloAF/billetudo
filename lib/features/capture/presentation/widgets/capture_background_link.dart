import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_background_cubit.dart';
import '../cubit/capture_background_state.dart';
import 'sheets/capture_background_sheet.dart';

/// The quiet entry into "Captura en segundo plano" from the Avisos centre.
///
/// Granting notification access and choosing issuers is only half of the
/// setup: if the phone later kills the listener, nothing arrives. A brand-new
/// user has no reason to suspect that, and Avisos otherwise only surfaces it
/// once the heuristic detects stale captures. This footer link makes the
/// sheet reachable at any time, so the two system settings are one tap away
/// from where the captures live.
///
/// It never replaces the degraded card/empty state: those appear when the app
/// has a reason to believe capture stopped. This is the permanent door.
class CaptureBackgroundLink extends StatelessWidget {
  const CaptureBackgroundLink({required this.onOpenSetup, super.key});

  /// Opens the permission/issuer flow when capture is not configured yet.
  /// Receives whether the notification permission is already granted, so the
  /// caller can send the user to the next missing step instead of the first
  /// one.
  final ValueChanged<bool> onOpenSetup;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return BlocBuilder<CaptureBackgroundCubit, CaptureBackgroundState>(
      builder: (BuildContext context, CaptureBackgroundState state) {
        // iOS has no notification listeners: the link must not exist there.
        if (!state.isSupported) {
          return const SizedBox.shrink();
        }
        return TextButton.icon(
          onPressed: () {
            if (state.needsSetup) {
              onOpenSetup(state.permissionGranted);
              return;
            }
            unawaited(CaptureBackgroundSheet.show(context));
          },
          style: TextButton.styleFrom(
            foregroundColor: colors.primaryOnSoft,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            minimumSize: const Size(0, 44),
          ),
          icon: Icon(
            LucideIcons.shieldCheck,
            size: 16,
            color: colors.primaryOnSoft,
          ),
          label: Text(
            l10n.captureBackgroundLinkLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.primaryOnSoft,
            ),
          ),
        );
      },
    );
  }
}
