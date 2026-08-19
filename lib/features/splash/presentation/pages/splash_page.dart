import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/brand_block.dart';

/// billetudo's launch screen (`Splash - B Wordmark + Icono (v2)`, `QUsfN`
/// light / `U0WjJ` dark in billetudo.pen —
/// `design-system/billetudo/pages/splash.md`).
///
/// Shown while `bootstrap()` opens Drift and handshakes with PowerSync — a
/// duration that is unknown up front, hence the indeterminate spinner
/// (deliberately not a determinate progress bar; see the spec's "Decisión de
/// diseño" section). Pure presentation: no `domain`/`data` layer, and not a
/// go_router destination — it is what is on screen before the router exists
/// (see `AppBootstrapGate`).
///
/// Plays a one-shot, sober entrance animation on first paint (spec's
/// "Animación de entrada" section): the `Brand Block` (icon + wordmark, one
/// unit) fades and scales in over 450ms, followed ~150ms later by a simple
/// 200ms fade-in of the `Bottom Block` (spinner + caption). Neither waits on
/// `bootstrap()` — both start as soon as this widget is first painted.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _brandBlockDuration = Duration(milliseconds: 450);
  static const _bottomBlockDelay = Duration(milliseconds: 150);
  static const _bottomBlockDuration = Duration(milliseconds: 200);

  bool _showBrandBlock = false;
  bool _showBottomBlock = false;

  @override
  void initState() {
    super.initState();
    // Start on the next frame rather than synchronously in `initState`, so
    // the initial (invisible) state is actually painted first and the
    // fade/scale has something to animate from.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _showBrandBlock = true);
      Future.delayed(_bottomBlockDelay, () {
        if (!mounted) {
          return;
        }
        setState(() => _showBottomBlock = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showBrandBlock ? 1 : 0,
                  duration: _brandBlockDuration,
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: _showBrandBlock ? 1 : 0.92,
                    duration: _brandBlockDuration,
                    curve: Curves.easeOutCubic,
                    child: const BrandBlock(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: AnimatedOpacity(
                opacity: _showBottomBlock ? 1 : 0,
                duration: _bottomBlockDuration,
                curve: Curves.easeOut,
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
            ),
          ],
        ),
      ),
    );
  }
}
