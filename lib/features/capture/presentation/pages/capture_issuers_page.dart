import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../domain/entities/issuer_app.dart';
import '../cubit/capture_issuers_cubit.dart';
import '../cubit/capture_issuers_state.dart';
import '../widgets/capture_disabled_view.dart';
import '../widgets/issuers_catalog_view.dart';
import '../widgets/issuers_no_apps_view.dart';

/// `qrDFE` / `xqdHH` — "Apps que se leen" (HU-02).
///
/// The screen that actually turns capture on. Granting the system permission
/// on its own listens to nothing: until an issuer is switched on here, every
/// notification is dropped by `packageName` before a single character of its
/// content is read.
///
/// **The permission is re-checked on entry and on every return to
/// foreground** (HU-09). Android lets the user revoke notification access
/// without telling the app, and a list of switches that cannot capture
/// anything would be a lie — so a revoked permission replaces the list with
/// the calm off state instead of leaving the switches sitting there.
class CaptureIssuersPage extends StatefulWidget {
  const CaptureIssuersPage({required this.onOpenPermission, super.key});

  /// Opens the explainer/permission screen. Used by the revoked state, which
  /// cannot fix anything by itself.
  final VoidCallback onOpenPermission;

  @override
  State<CaptureIssuersPage> createState() => _CaptureIssuersPageState();
}

class _CaptureIssuersPageState extends State<CaptureIssuersPage>
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
      unawaited(context.read<CaptureIssuersCubit>().refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            PageHeader(title: l10n.captureIssuersHeader),
            Expanded(
              child: BlocBuilder<CaptureIssuersCubit, CaptureIssuersState>(
                builder: (BuildContext context, CaptureIssuersState state) {
                  final CaptureIssuersCubit cubit =
                      context.read<CaptureIssuersCubit>();
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!state.permissionGranted) {
                    return CaptureDisabledView(
                      onOpenSettings: widget.onOpenPermission,
                      onSeeHowItWorks: widget.onOpenPermission,
                    );
                  }
                  if (state.hasError) {
                    return ErrorState(
                      title: l10n.captureIssuersErrorTitle,
                      onRetry: () => unawaited(cubit.refresh()),
                    );
                  }
                  if (state.hasNoInstalledApps) {
                    return const IssuersNoAppsView();
                  }
                  return IssuersCatalogView(
                    state: state,
                    onIssuerChanged: (
                      IssuerApp issuer, {
                      required bool enabled,
                    }) =>
                        unawaited(
                      cubit.setEnabled(issuer: issuer, enabled: enabled),
                    ),
                    onTurnOffAll: () => unawaited(cubit.turnOffAll()),
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
