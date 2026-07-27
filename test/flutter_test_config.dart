import 'dart:async';

import 'package:billetudo/core/theme/app_theme.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Registers the brand typeface for **every** test file under `test/`.
///
/// `flutter test` bundles the fonts declared in `pubspec.yaml` but does not
/// register them, so without this every `Text` falls back to the placeholder
/// typeface, whose glyph metrics are much wider than Plus Jakarta Sans. That
/// made plain widget tests report overflows that do not exist on device (and,
/// worse, hid the real ones).
///
/// It used to happen by accident: building [AppTheme] called
/// `GoogleFonts.plusJakartaSansTextTheme`, and `google_fonts` loads its bytes
/// through its own `FontLoader` regardless of the test binding. Now that the
/// family comes from `pubspec.yaml` (so `fontWeight` picks a real face instead
/// of always rendering the 400 file), that side effect is gone and the
/// registration has to be explicit and global.
///
/// All five weights are registered under one family: the engine reads each
/// file's own weight metadata, so registering only Regular would silently
/// bring back the "every bold renders at 400" bug inside tests.
const Map<int, String> _brandFontAssets = <int, String>{
  400: 'assets/fonts/PlusJakartaSans-Regular.ttf',
  500: 'assets/fonts/PlusJakartaSans-Medium.ttf',
  600: 'assets/fonts/PlusJakartaSans-SemiBold.ttf',
  700: 'assets/fonts/PlusJakartaSans-Bold.ttf',
  800: 'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
};

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final loader = FontLoader(AppTheme.fontFamily);
  for (final asset in _brandFontAssets.values) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();

  await testMain();
}
