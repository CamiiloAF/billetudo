import 'package:billetudo/core/widgets/tutorial_sheet.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_content.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:billetudo/features/tutorials/presentation/utils/tutorial_content_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden_helpers.dart';

/// The one shared minitutorial sheet (`docs/requirements/
/// 16-minitutoriales.md`), both variants: HU-01 (a navigation CTA) and HU-02
/// (only "Entendido").
///
/// Content is pulled from the real [TutorialContentCatalog] (backed by
/// `AppLocalizations`), never hand-typed lorem-ipsum strings — this is the
/// exact copy `design-system/billetudo/pages/minitutoriales.md` closed and
/// every production call site actually renders, so a wording regression in
/// the `.arb` files fails here too.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  TutorialContent contentFor(BuildContext context, TutorialKey key) =>
      TutorialContentCatalog.of(context, key);

  // One golden per key, both themes — full coverage of all 11 stable
  // minitutorials (4 HU-01 screens, 3 points each; 7 HU-02 sub-flows, 1-2
  // points each), not just a sample of the shortest/longest ones. Named by
  // `TutorialKey.name` so a new key added to the enum is a visible gap here
  // (the file won't exist) rather than a silently-uncovered addition.
  for (final key in TutorialKey.values) {
    for (final brightness in Brightness.values) {
      final suffix = brightness == Brightness.light ? 'light' : 'dark';
      final kind = key.isScreenTutorial ? 'screen' : 'subflow';

      testWidgets('golden: ${key.name} ($kind, $suffix)', (tester) async {
        setGoldenViewport(tester);
        await tester.pumpWidget(
          wrapForGolden(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    TutorialSheet.show(context, contentFor(context, key)),
                child: const Text('open'),
              ),
            ),
            brightness: brightness,
          ),
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/tutorial_sheet_${key.name}_$suffix.png',
          ),
        );
      });
    }
  }
}
