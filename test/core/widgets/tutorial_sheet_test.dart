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

  Future<TutorialContent> readContent(
    WidgetTester tester,
    TutorialKey key,
  ) async {
    late TutorialContent content;
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) {
            content = contentFor(context, key);
            return const SizedBox.shrink();
          },
        ),
        brightness: Brightness.light,
      ),
    );
    return content;
  }

  Future<void> pumpSheet(
    WidgetTester tester,
    TutorialKey key,
  ) async {
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                TutorialSheet.show(context, contentFor(context, key)),
            child: const Text('open'),
          ),
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  }

  group('HU-01 (screen tutorial, has a navigation CTA)', () {
    // Presupuestos: the pattern's home turf and its 3-point ceiling.
    testWidgets('renders title, every point and both buttons', (
      tester,
    ) async {
      final content = await readContent(tester, TutorialKey.budgetsScreen);
      await pumpSheet(tester, TutorialKey.budgetsScreen);

      expect(find.text(content.title), findsOneWidget);
      expect(content.points, hasLength(3));
      for (final point in content.points) {
        expect(find.text(point.heading), findsOneWidget);
        expect(find.text(point.body), findsOneWidget);
      }
      expect(find.text(content.ctaLabel!), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);
    });

    testWidgets('tapping the CTA resolves TutorialSheetResult.cta', (
      tester,
    ) async {
      TutorialSheetResult? result;
      final content = await readContent(tester, TutorialKey.budgetsScreen);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await TutorialSheet.show(
                  context,
                  contentFor(context, TutorialKey.budgetsScreen),
                );
              },
              child: const Text('open'),
            ),
          ),
          brightness: Brightness.light,
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text(content.ctaLabel!));
      await tester.pumpAndSettle();

      expect(result, TutorialSheetResult.cta);
    });

    testWidgets('tapping "Entendido" resolves TutorialSheetResult.gotIt', (
      tester,
    ) async {
      TutorialSheetResult? result;
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await TutorialSheet.show(
                  context,
                  contentFor(context, TutorialKey.budgetsScreen),
                );
              },
              child: const Text('open'),
            ),
          ),
          brightness: Brightness.light,
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(result, TutorialSheetResult.gotIt);
    });

    testWidgets(
      'dismissing via the standard gesture resolves null — criterion 3 '
      'counts that as seen anyway, it is the caller who marks it',
      (tester) async {
        TutorialSheetResult? result = TutorialSheetResult.gotIt;
        await tester.pumpWidget(
          wrapForGolden(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await TutorialSheet.show(
                    context,
                    contentFor(context, TutorialKey.budgetsScreen),
                  );
                },
                child: const Text('open'),
              ),
            ),
            brightness: Brightness.light,
          ),
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Tap the scrim above the sheet to dismiss it, same gesture a real
        // swipe-down or tap-outside would trigger.
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        expect(result, isNull);
      },
    );

    // All 4 HU-01 screens now land on 3 points each (Presupuestos, Metas,
    // Deudas y Pagos programados copy was synced with
    // `design-system/billetudo/pages/minitutoriales.md`, which closed the
    // once-missing points) — asserted for every screen tutorial key, not
    // just Presupuestos above, separately from the golden loop below so a
    // regression that drops a point fails a plain widget test too, not only
    // a pixel diff.
    for (final key in TutorialKey.screenTutorials) {
      testWidgets('${key.name}: renders its 3 points and CTA', (
        tester,
      ) async {
        final content = await readContent(tester, key);
        await pumpSheet(tester, key);

        expect(content.points, hasLength(3));
        expect(find.text(content.title), findsOneWidget);
        for (final point in content.points) {
          expect(find.text(point.heading), findsOneWidget);
          expect(find.text(point.body), findsOneWidget);
        }
        expect(find.text(content.ctaLabel!), findsOneWidget);
      });
    }
  });

  group('HU-02 (sub-flow tutorial, no navigation CTA)', () {
    // Enlazar movimiento existente: the pattern's 1-point floor.
    testWidgets(
      'renders only "Entendido" as the primary button, no CTA',
      (tester) async {
        final content =
            await readContent(tester, TutorialKey.debtLinkMovement);
        await pumpSheet(tester, TutorialKey.debtLinkMovement);

        expect(content.points, hasLength(1));
        expect(find.text(content.title), findsOneWidget);
        expect(find.text(content.points.single.heading), findsOneWidget);
        expect(find.text('Entendido'), findsOneWidget);
        expect(find.byType(OutlinedButton), findsNothing);
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    // La cuota programada: the pattern's other end, 2 points instead of 1.
    testWidgets('holds at the 2-point end of the range too (cuota)', (
      tester,
    ) async {
      final content =
          await readContent(tester, TutorialKey.debtScheduledInstallment);
      await pumpSheet(tester, TutorialKey.debtScheduledInstallment);

      expect(content.points, hasLength(2));
      expect(find.text(content.title), findsOneWidget);
      for (final point in content.points) {
        expect(find.text(point.heading), findsOneWidget);
        expect(find.text(point.body), findsOneWidget);
      }
      expect(find.text('Entendido'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

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
