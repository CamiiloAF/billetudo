import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/home/presentation/widgets/home_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden_helpers.dart';
import 'marketing_status_bar.dart';

// Re-exported so a capture file needs only this one import.
export 'marketing_status_bar.dart' show MarketingPlatform, MarketingStatusBar;

/// Capture harness for the store-listing screenshots (F1 of
/// `docs/marketing/plan-fichas-de-tienda.md`).
///
/// **This is not a golden test.** Nothing here asserts anything: it is an
/// asset generator that renders the real app widgets with the showcase
/// dataset and writes PNGs to `docs/marketing/store-listing/raw/`. It lives
/// outside `test/features/` and is deliberately not named `*_test.dart` so a
/// plain `flutter test` never picks it up and never rewrites marketing assets
/// as a side effect of the regular suite.
///
/// It reuses `test/support/golden_helpers.dart` for the theme/locale chrome
/// and the font registration (so the captured pixels are the same typography
/// the goldens audit), but keeps its own viewport handling: the goldens use
/// tall synthetic canvases (up to 2200 logical px) to fit a whole scrollable
/// page into one image, while a store screenshot must be exactly one real
/// phone screen.
///
/// Surface: 390 x 844 logical px (iPhone 13 / the size every golden uses) at
/// `devicePixelRatio` 3 → **1170 x 2532** PNG, which is what the Pencil
/// mockup frames of F2 expect.
const Size marketingLogicalSize = Size(390, 844);
const double marketingPixelRatio = 3;

/// Where the raw (frameless) captures land. Relative to the repo root, which
/// is `flutter test`'s working directory.
///
/// Captures are filed under a per-platform subdirectory (`android/`, `ios/`),
/// because each store gets its own status bar.
///
/// Beware when regenerating: Pencil caches an image fill by its resolved file
/// path and does **not** invalidate it when the bytes change. Rewriting the
/// fill, clearing it first, adding a `?v=` query (which breaks path resolution
/// outright) and changing the relative prefix were all tried and all kept
/// rendering the stale image. Only a new path works. If a regeneration changes
/// what the captures look like without changing their names, rename them and
/// repoint the `MarketingDeviceFrame` instances in `billetudo.pen`.
const String marketingOutputDir = 'docs/marketing/store-listing/raw';

/// Registers the fonts the captures need. Same set as every golden's
/// `setUpAll`, so icons render as real glyphs instead of tofu boxes.
Future<void> setUpMarketingCapture() async {
  disableGoogleFontsRuntimeFetching();
  await loadMaterialIconsFont();
}

/// The five branches of `app_router.dart`'s `StatefulShellRoute.indexedStack`,
/// **in the same order they are declared there** (`_inicioBranch`,
/// `_movimientosBranch`, `_presupuestosBranch`, `_metasBranch`,
/// `_masBranch`), so `index` is literally the `currentIndex` `HomeShellPage`
/// hands to [HomeTabBar].
///
/// A screenshot names its branch only when the real app renders that screen
/// *inside* the shell — i.e. when its `GoRoute` is a branch's first-level
/// route with no `parentNavigatorKey`. Every route declared with
/// `parentNavigatorKey: _rootNavigatorKey` (all the `nuevo`/`:id` subroutes,
/// plus the top-level siblings of the shell: Gráficas, Deudas, Pagos
/// Programados, Import/Export, Cuentas, Categorías, Onboarding) is stacked on
/// the root navigator and shows a `Page Header` with a back button instead —
/// a `Page Header` and the `Tab Bar` are mutually exclusive per MASTER.md.
/// Those screens must be captured with [pumpMarketing]'s `tabBranch` left
/// `null`.
enum MarketingTabBranch { inicio, movimientos, presupuestos, metas, mas }

/// Reproduces `HomeShellPage`'s chrome for a capture: the branch content as
/// the body, the real [HomeTabBar] as `bottomNavigationBar`, with [branch]
/// highlighted.
///
/// It is not `HomeShellPage` itself because that widget requires a live
/// `StatefulNavigationShell`, which go_router only builds from inside a real
/// router (see `home_shell_page_golden_test.dart`'s note). Wiring a whole
/// `GoRouter` here would drag in the DI graph of all five branches just to
/// draw one bar; this renders the exact same two widgets `HomeShellPage.build`
/// composes, with the same `currentIndex` semantics.
class MarketingTabShell extends StatelessWidget {
  const MarketingTabShell({
    required this.branch,
    required this.child,
    super.key,
  });

  final MarketingTabBranch branch;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: HomeTabBar(
        currentIndex: branch.index,
        onSelect: (_) {},
      ),
    );
  }
}

/// One whole phone screen: [MarketingStatusBar] on top of the app content,
/// filling the 390 x 844 viewport exactly.
///
/// Every capture rasterizes *this* widget rather than the page under test, so
/// all nine PNGs come out at the same size with the same chrome — a page-level
/// finder would silently drop the status bar back out of the frame.
class MarketingScreenFrame extends StatelessWidget {
  const MarketingScreenFrame({
    required this.platform,
    required this.child,
    super.key,
  });

  final MarketingPlatform platform;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.background,
      child: Column(
        children: [
          MarketingStatusBar(platform: platform),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Pumps [child] on a real-phone-sized viewport under [brightness].
///
/// [tabBranch] decides whether the capture gets the bottom tab bar, and which
/// tab reads as active. Pass it **only** for screens the router serves from
/// inside a `StatefulShellBranch` — see [MarketingTabBranch]. Leaving it
/// `null` (the default) captures a bare stacked screen, which is what the app
/// really shows for every root-navigator route.
///
/// [settle] mirrors `pumpGolden`'s escape hatch for indeterminate animations;
/// every showcase screen is a settled "with data" state, so it defaults to
/// `true`.
Future<void> pumpMarketing(
  WidgetTester tester,
  Widget child, {
  required Brightness brightness,
  required MarketingPlatform platform,
  MarketingTabBranch? tabBranch,
  bool settle = true,
}) async {
  tester.view.physicalSize = marketingLogicalSize * marketingPixelRatio;
  tester.view.devicePixelRatio = marketingPixelRatio;
  // `flutter_test` forces `debugDisableShadows = true` so goldens stay
  // deterministic across platforms: shadows still paint, but with no blur,
  // which flattens a soft `BoxShadow` into a hard-edged solid silhouette. The
  // goldens want that; a store screenshot does not — it has to look like the
  // app on a real device, and `AppFab`'s `blurRadius: 16` halo was showing up
  // as a second flat disc behind the button.
  //
  // It must be restored *inside* the test body: the binding asserts every
  // painting debug variable is back to its default, and it runs that check
  // before `addTearDown` callbacks, so a tear-down alone fails every test
  // after its capture is already on disk. [captureMarketing] restores it as
  // its last step; the tear-down below is only the safety net for a
  // `pumpMarketing` that never captures.
  debugDisableShadows = false;
  addTearDown(() {
    debugDisableShadows = true;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final framed = tabBranch == null
      ? child
      : MarketingTabShell(branch: tabBranch, child: child);
  await tester.pumpWidget(
    wrapForGolden(
      MarketingScreenFrame(platform: platform, child: framed),
      brightness: brightness,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Rasterizes the [MarketingScreenFrame] on screen and writes it as
/// `<marketingOutputDir>/<fileName>`.
///
/// Same layer-walk `matchesGoldenFile` uses internally (climb to the nearest
/// repaint boundary, rasterize its `OffsetLayer`), but at
/// [marketingPixelRatio] instead of 1: the display list is re-rasterized at
/// 3x, so text and vector icons come out genuinely sharp rather than upscaled.
Future<void> captureMarketing(
  WidgetTester tester,
  String fileName,
) async {
  final element = find.byType(MarketingScreenFrame).evaluate().single;
  // Derived from the tree instead of taken as an argument: the frame already
  // knows which chrome it drew, so a caller cannot file an Android capture
  // under `ios/` by passing the wrong value.
  final platform = (element.widget as MarketingScreenFrame).platform;
  var renderObject = element.renderObject!;
  while (!renderObject.isRepaintBoundary) {
    renderObject = renderObject.parent!;
  }
  final layer = renderObject.debugLayer! as OffsetLayer;
  final bounds = renderObject.paintBounds;

  final bytes = await tester.runAsync<Uint8List>(() async {
    final image = await layer.toImage(bounds, pixelRatio: marketingPixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });

  final file = File('$marketingOutputDir/${platform.name}/$fileName')
    ..createSync(recursive: true);
  file.writeAsBytesSync(bytes!);

  // Restored only now: the shadow blur has to survive both the paint that
  // built the display list and its re-rasterization above. See the note in
  // [pumpMarketing] for why this cannot live in a tear-down.
  debugDisableShadows = true;
}
