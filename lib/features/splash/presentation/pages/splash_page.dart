import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_wordmark.dart';

/// billetudo's launch screen (`Splash - B Wordmark`, `bSOQb` light / `raS94`
/// dark in billetudo.pen — `design-system/billetudo/pages/splash.md`).
///
/// Shown while `bootstrap()` opens Drift and handshakes with PowerSync — a
/// duration that is unknown up front, hence the indeterminate spinner
/// (deliberately not a determinate progress bar; see the spec's "Decisión de
/// diseño" section). Pure presentation: no `domain`/`data` layer, and not a
/// go_router destination — it is what is on screen before the router exists
/// (see `AppBootstrapGate`).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              child: Center(child: BrandWordmark(fontSize: 56)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.splashLoadingCaption,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
