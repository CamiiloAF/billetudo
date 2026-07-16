import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// A realistic, fixed phone viewport (iPhone 13 logical size) so every golden
/// in this feature renders at the same frame regardless of the host machine.
///
/// Kept separate from [tallGoldenPhoneSize]: pages whose full scrollable
/// content must be captured in one shot (the category form) need a taller
/// canvas than a page meant to be read one screen at a time. Same values as
/// `test/features/accounts/presentation/golden/golden_helpers.dart`, kept
/// per-feature (not promoted to a shared test helper) since no third feature
/// needs it yet.
const Size goldenPhoneSize = Size(390, 844);
const double goldenDevicePixelRatio = 3;

/// A tall canvas for pages whose full scrollable content must show in one
/// golden (the category form), instead of only the first viewport.
const Size tallGoldenPhoneSize = Size(390, 1600);

/// Sets the test binding's view to [size] at [goldenDevicePixelRatio] and
/// restores it on [addTearDown]. Must run inside a `testWidgets` body.
void setGoldenViewport(WidgetTester tester, [Size size = goldenPhoneSize]) {
  tester.view.physicalSize = size * goldenDevicePixelRatio;
  tester.view.devicePixelRatio = goldenDevicePixelRatio;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// google_fonts falls back to the bare Material fallback typeface if it tries
/// to hit the network — there is none in `flutter test`. The real Plus Jakarta
/// Sans ships in `assets/fonts/` precisely so goldens capture it instead of
/// that fallback (see `pubspec.yaml`). Idempotent: safe to call from every
/// golden test's `setUpAll`.
void disableGoogleFontsRuntimeFetching() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// `flutter test` substitutes every font that has not been explicitly loaded
/// with a placeholder glyph (a tofu box) to keep non-golden tests fast and
/// deterministic. Plus Jakarta Sans escapes that substitution because
/// `google_fonts` loads its bytes through its own `FontLoader` regardless of
/// the test binding, but `Icons.*` (Material Icons) does not — so without
/// this, every icon in a golden renders as a hollow square instead of the
/// glyph the design actually ships. Call once per golden test file's
/// `setUpAll`, alongside [disableGoogleFontsRuntimeFetching].
Future<void> loadMaterialIconsFont() async {
  final data = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
  final loader = FontLoader('MaterialIcons')..addFont(Future.value(data));
  await loader.load();
}

/// Wraps [child] with the app's real theme (light or dark), locale and
/// localizations — the same chrome `PumpApp` (widget_tests' pump helper) uses,
/// plus the `theme`/`darkTheme` split a golden needs to pick.
Widget wrapForGolden(Widget child, {required Brightness brightness}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

/// Pumps [child] at [size] under [brightness] and settles it — the shared
/// choreography every golden test in this file follows before calling
/// `matchesGoldenFile`.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  required Brightness brightness,
  Size size = goldenPhoneSize,
}) async {
  setGoldenViewport(tester, size);
  await tester.pumpWidget(wrapForGolden(child, brightness: brightness));
  await tester.pumpAndSettle();
}
