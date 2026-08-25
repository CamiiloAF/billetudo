import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_content.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:billetudo/features/tutorials/presentation/utils/tutorial_content_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Criterion 12 (`docs/requirements/fase-1/16-minitutoriales.md`): every one of the
/// 12 tutorials is localized through `AppLocalizations`, and screen
/// tutorials (HU-01) carry a navigation CTA while sub-flow ones (HU-02)
/// never do — [TutorialContentCatalog.of] is the single place that maps a
/// [TutorialKey] to its copy, so this is the only test that would catch a
/// missing/mismatched `case` for a key (the compiler enforces exhaustiveness,
/// but not correctness of *which* content a key maps to).
void main() {
  Future<void> pumpAndResolve(
    WidgetTester tester,
    TutorialKey key,
    void Function(TutorialContent) onResolved,
  ) async {
    late TutorialContent content;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            content = TutorialContentCatalog.of(context, key);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    onResolved(content);
  }

  for (final key in TutorialKey.values) {
    testWidgets('${key.name}: title and every point are non-empty, key matches',
        (tester) async {
      await pumpAndResolve(tester, key, (content) {
        expect(content.key, key);
        expect(content.title, isNotEmpty);
        expect(content.points, isNotEmpty);
        for (final point in content.points) {
          expect(point.heading, isNotEmpty);
          expect(point.body, isNotEmpty);
        }
      });
    });

    if (key.isScreenTutorial) {
      testWidgets(
          '${key.name} (HU-01 screen): has a non-empty navigation CTA and '
          '2-3 points', (tester) async {
        await pumpAndResolve(tester, key, (content) {
          expect(content.ctaLabel, isNotNull);
          expect(content.ctaLabel, isNotEmpty);
          expect(content.hasNavigationCta, isTrue);
          expect(content.points.length, inInclusiveRange(2, 3));
        });
      });
    } else {
      testWidgets(
          '${key.name} (HU-02 sub-flow): has no navigation CTA and 1-2 '
          'points', (tester) async {
        await pumpAndResolve(tester, key, (content) {
          expect(content.ctaLabel, isNull);
          expect(content.hasNavigationCta, isFalse);
          expect(content.points.length, inInclusiveRange(1, 2));
        });
      });
    }
  }
}
