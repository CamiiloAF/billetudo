import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_degraded_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// `VW54R` / `DSCf0` — the degraded capture card of Avisos (HU-09).
///
/// The copy is fixed by the design spec, and the wiring matters: "Revisar"
/// opens the sheet, "Ahora no" snoozes, and the subtitle gets three lines
/// because the sentence explains what the phone does.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 350, child: child),
          ),
        ),
      );

  testWidgets('states the spec copy and lets the subtitle wrap to 3 lines',
      (tester) async {
    await tester.pumpWidget(
      wrap(CaptureDegradedCard(onReview: () {}, onSnooze: () {})),
    );

    expect(find.text('La captura puede detenerse'), findsOneWidget);
    expect(
      find.text(
        'Tu teléfono puede cerrar Billetudo cuando no lo usás. Si pasa, no '
        'llegan avisos hasta que lo abras.',
      ),
      findsOneWidget,
    );

    final Text subtitle = tester.widget<Text>(
      find.text(
        'Tu teléfono puede cerrar Billetudo cuando no lo usás. Si pasa, no '
        'llegan avisos hasta que lo abras.',
      ),
    );
    expect(subtitle.maxLines, 3);
  });

  testWidgets('the attention state uses the amber tokens, never text or error',
      (tester) async {
    await tester.pumpWidget(
      wrap(CaptureDegradedCard(onReview: () {}, onSnooze: () {})),
    );

    final Icon icon = tester.widget<Icon>(find.byIcon(LucideIcons.shieldAlert));
    expect(icon.color, AppColors.light.amberText);
    // The 40pt icon wrap carries `$amber-soft`; the card itself stays `$surface`
    // so the attention reads from the icon, not from a tinted card.
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                AppColors.light.amberSoft,
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Revisar" opens the sheet through its own callback',
      (tester) async {
    var reviews = 0;
    var snoozes = 0;
    await tester.pumpWidget(
      wrap(
        CaptureDegradedCard(
          onReview: () => reviews++,
          onSnooze: () => snoozes++,
        ),
      ),
    );

    await tester.tap(find.text('Revisar'));
    await tester.pump();

    expect(reviews, 1);
    expect(snoozes, 0);
  });

  testWidgets('"Ahora no" only snoozes; it never opens the sheet',
      (tester) async {
    var reviews = 0;
    var snoozes = 0;
    await tester.pumpWidget(
      wrap(
        CaptureDegradedCard(
          onReview: () => reviews++,
          onSnooze: () => snoozes++,
        ),
      ),
    );

    await tester.tap(find.text('Ahora no'));
    await tester.pump();

    expect(snoozes, 1);
    expect(reviews, 0);
  });
}
