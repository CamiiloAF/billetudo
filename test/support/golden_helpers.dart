import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// A realistic, fixed phone viewport (iPhone 13 logical size) so every golden
/// in the app renders at the same frame regardless of the host machine.
///
/// Kept separate from [tallGoldenPhoneSize]: pages with a bottom action bar or
/// a scrollable body that must be captured in full (a form) need a taller
/// canvas than a page meant to be read one screen at a time.
const Size goldenPhoneSize = Size(390, 844);
const double goldenDevicePixelRatio = 3;

/// A tall canvas for pages whose full scrollable content must show in one
/// golden, instead of only the first viewport. [height] varies by how long
/// the page's content actually is — callers pick their own.
Size tallGoldenPhoneSize({double height = 2200}) => Size(390, height);

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

/// A safety net against `google_fonts` reaching for the network, which never
/// resolves in `flutter test`. The app itself no longer renders through
/// `google_fonts` (Plus Jakarta Sans is a plain `pubspec.yaml` family now, see
/// `AppTheme.fontFamily`), so this only guards leftovers. Idempotent: safe to
/// call from every golden test's `setUpAll`.
void disableGoogleFontsRuntimeFetching() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// `flutter test` substitutes every font that has not been explicitly loaded
/// with a placeholder glyph (a tofu box) to keep non-golden tests fast and
/// deterministic. Plus Jakarta Sans escapes that substitution because
/// `test/flutter_test_config.dart` registers its five weights once for every
/// test file, goldens included, so a plain widget test measures the same
/// glyphs the app ships. `Icons.*` (Material Icons) and `LucideIcons.*` (the
/// app's real icon set, see `pubspec.yaml`) do not — so without this, every
/// icon in a golden renders as a hollow square instead of the glyph the
/// design actually ships. Call once per golden test file's `setUpAll`,
/// alongside [disableGoogleFontsRuntimeFetching].
///
/// The Lucide font MUST be registered as `packages/lucide_icons_flutter/Lucide`,
/// not bare `Lucide`: every `LucideIcons.*` constant sets `fontPackage:
/// 'lucide_icons_flutter'`, and `Icon`'s `TextStyle` resolution looks up a
/// `package`-scoped font under that `packages/<package>/<family>` name —
/// registering the bare family name silently never matches, so the icon
/// falls back to the placeholder glyph with no error anywhere.
Future<void> loadMaterialIconsFont() async {
  final materialData = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
  final materialLoader = FontLoader('MaterialIcons')
    ..addFont(Future.value(materialData));
  await materialLoader.load();

  final lucideData =
      await rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf');
  final lucideLoader = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(Future.value(lucideData));
  await lucideLoader.load();
}

/// Registers the app's bundled typeface under the `'Roboto'` family so a
/// golden that renders the Google sign-in button measures its label with real
/// glyph metrics.
///
/// `GoogleSignInButton`'s label is pinned to `fontFamily: 'Roboto'` per
/// Google's branding guidelines, and Roboto is deliberately NOT bundled (it is
/// the Android platform default on device). In `flutter test` an unregistered
/// family falls back to the placeholder typeface, whose glyphs are much wider
/// than the real font — enough to overflow that button by ~20px. That overflow
/// is the documented test-only artifact `test/flutter_test_config.dart` warns
/// about, not a device bug, so a golden must not capture it. Aliasing the
/// bundled Plus Jakarta Sans faces to `'Roboto'` renders the label in a real,
/// correctly-metricised font (a close visual stand-in for device Roboto, which
/// tests can never load anyway). Call once per golden test file that renders
/// the button, in `setUpAll`, alongside [loadMaterialIconsFont].
Future<void> loadGoogleButtonFontFallback() async {
  final loader = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-SemiBold.ttf'));
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
/// choreography every golden test follows before calling `matchesGoldenFile`.
///
/// [settle] defaults to `true` (`pumpAndSettle`). Set it to `false` for a
/// loading state that renders an indeterminate `CircularProgressIndicator`:
/// its `AnimationController` repeats forever, so `pumpAndSettle` never
/// finishes and times out. A single `pump()` still captures a deterministic
/// frame — the spinner's start position is fixed, not random — which is all
/// a golden of a loading state needs.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  required Brightness brightness,
  Size size = goldenPhoneSize,
  bool settle = true,
}) async {
  setGoldenViewport(tester, size);
  await tester.pumpWidget(wrapForGolden(child, brightness: brightness));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
