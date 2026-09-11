import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/capture_permission_cubit.dart';
import '../cubit/capture_permission_state.dart';
import '../widgets/capture_disabled_view.dart';
import '../widgets/permission_explainer_view.dart';

/// `FRtfP` / `ZGtoE` — the door into notification capture (HU-01).
///
/// This screen exists so the user never meets Android's warning cold. The
/// system dialog says, in those words, that the app will be able to read
/// **every** notification; whoever reads that without context abandons, and
/// rightly so. So the app explains first, in plain language, what it reads
/// (only the bank apps the user picks), what it stores (only what it
/// understood: amount, merchant, date — never the notification text), what
/// syncs, and that nothing is recorded without confirmation.
///
/// **Returning from Ajustes re-checks the real permission** and never assumes
/// it was granted just because the user went there — the app can open that
/// screen but cannot observe it. If it is still off, the calm off state shows
/// with a way to retry and no reproach.
class CapturePermissionPage extends StatefulWidget {
  const CapturePermissionPage({
    required this.onGranted,
    required this.onDecline,
    super.key,
  });

  /// Once the permission is really granted the next step is choosing issuers:
  /// the permission alone captures nothing. The router supplies the
  /// navigation.
  final VoidCallback onGranted;

  /// "Ahora no, gracias" — leaves without cost. Also the back button.
  final VoidCallback onDecline;

  @override
  State<CapturePermissionPage> createState() => _CapturePermissionPageState();
}

class _CapturePermissionPageState extends State<CapturePermissionPage>
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

  /// The only way back from the system settings screen: Android gives no
  /// callback, so coming back to foreground is the signal to re-ask.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(context.read<CapturePermissionCubit>().recheck());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<CapturePermissionCubit, CapturePermissionState>(
          listenWhen: (CapturePermissionState previous,
                  CapturePermissionState current) =>
              previous.granted != current.granted,
          listener: (BuildContext context, CapturePermissionState state) {
            if (state.granted) {
              widget.onGranted();
            }
          },
          builder: (BuildContext context, CapturePermissionState state) {
            final CapturePermissionCubit cubit =
                context.read<CapturePermissionCubit>();
            return Column(
              children: <Widget>[
                PageHeader(
                  title: l10n.capturePermissionHeader,
                  onBack: widget.onDecline,
                ),
                Expanded(
                  child: switch (state.view) {
                    CapturePermissionView.explainer => PermissionExplainerView(
                        onOpenSettings: () => unawaited(cubit.openSettings()),
                        onDecline: widget.onDecline,
                      ),
                    CapturePermissionView.notGranted => CaptureDisabledView(
                        onOpenSettings: () => unawaited(cubit.openSettings()),
                        onSeeHowItWorks: cubit.showExplainer,
                      ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
