import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/auth_provider.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';
import '../widgets/auth_sign_in_buttons_group.dart';
import '../widgets/device_preview_illustration.dart';
import '../widgets/sheets/confirm_account_conflict_sheet.dart';

/// Login / invitation to back up (`fTetG` Android, `RSzD1` iOS): the
/// same centered composition on both platforms, differing only in which
/// buttons `AuthSignInButtonsGroup` shows.
///
/// Never a gate: a plain close button lets the user postpone this with no
/// fewer than "Continuar sin cuenta" already offers (HU-01).
class LoginPage extends StatelessWidget {
  const LoginPage({
    required this.onSignedIn,
    required this.onSkip,
    super.key,
  });

  /// Called once [LoginCubit] reports a successful sign-in.
  ///
  /// `signedInAfterConflict: true` means this sign-in was completed by
  /// resolving an account-conflict sheet (this device's local data was just
  /// wiped) — the caller must skip the merge confirmation screen (HU-04):
  /// there is nothing left on this device to fold in. `false` is a plain
  /// sign-in, which the caller sends to the merge screen as before.
  final void Function({required bool signedInAfterConflict}) onSignedIn;

  /// "Continuar sin cuenta" / the close button: both just leave this screen.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return BlocConsumer<LoginCubit, LoginState>(
      listenWhen: (previous, current) =>
          current.status == LoginStatus.signedIn ||
          current.status == LoginStatus.error ||
          current.status == LoginStatus.accountConflictDetected,
      listener: (context, state) {
        if (state.status == LoginStatus.signedIn) {
          onSignedIn(signedInAfterConflict: state.signedInAfterConflict);
          return;
        }
        if (state.status == LoginStatus.accountConflictDetected) {
          unawaited(_handleAccountConflict(context));
          return;
        }
        final failure = state.failure;
        if (failure == null) {
          return;
        }
        final cubit = context.read<LoginCubit>();
        final isApple = state.lastProvider == AuthProvider.apple;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                isApple
                    ? l10n.authAppleErrorSnackbar
                    : l10n.authGoogleErrorSnackbar,
              ),
              action: SnackBarAction(
                label: l10n.commonRetry,
                onPressed: isApple
                    ? cubit.continueWithApple
                    : cubit.continueWithGoogle,
              ),
              persist: false,
            ),
          );
        cubit.dismissError();
      },
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        final isLoading = state.status == LoginStatus.loading;
        // Both providers share a single `status`, so it alone can't tell
        // which button is mid-flight — filter by `lastProvider` too. Never
        // let both spinners show at once (GH-25).
        final isGoogleLoading =
            isLoading && state.lastProvider == AuthProvider.google;
        final isAppleLoading =
            isLoading && state.lastProvider == AuthProvider.apple;

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: onSkip,
                      icon: const Icon(LucideIcons.x),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.muted,
                        fixedSize: const Size(44, 44),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const DevicePreviewIllustration(),
                            const SizedBox(height: 24),
                            Text(
                              l10n.authLoginTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.authLoginSubtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colors.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.shield,
                                  size: 24,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    l10n.authTrustRow,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AuthSignInButtonsGroup(
                    isGoogleLoading: isGoogleLoading,
                    isAppleLoading: isAppleLoading,
                    onGoogle: isLoading ? null : cubit.continueWithGoogle,
                    onApple: isLoading ? null : cubit.continueWithApple,
                    onSkip: onSkip,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shows the blocking [ConfirmAccountConflictSheet] and settles it against
/// [LoginCubit] — `true` (borrar y continuar) calls `resolveConflict`,
/// `false` (cancelar) calls `cancelConflict`. The sheet itself never
/// resolves to `null` (see its own doc), but the `context.mounted` guard
/// still protects the (rare) case where this widget is gone by the time the
/// awaited sheet settles.
Future<void> _handleAccountConflict(BuildContext context) async {
  final cubit = context.read<LoginCubit>();
  final confirmed = await ConfirmAccountConflictSheet.show(context);
  if (!context.mounted) {
    return;
  }
  if (confirmed ?? false) {
    await cubit.resolveConflict();
  } else {
    await cubit.cancelConflict();
  }
}
