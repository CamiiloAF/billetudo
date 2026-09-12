import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/period_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The shared inline period pill (`vBgce`) — Movimientos' single-line
/// [PeriodStepper.label] and Presupuestos' two-fragment
/// [PeriodStepper.rangeLabel]/[PeriodStepper.stateLabel], plus the optional
/// `Context Row` (`Budget Context Tag`).
void main() {
  Future<void> pump(WidgetTester tester, PeriodStepper stepper) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: stepper),
        ),
      );

  testWidgets('renders a single-line label (Movimientos case)', (tester) async {
    await pump(
      tester,
      PeriodStepper(
        previousLabel: 'Periodo anterior',
        nextLabel: 'Periodo siguiente',
        label: 'Julio 2026',
        onPrevious: () {},
        onNext: () {},
      ),
    );

    expect(find.text('Julio 2026'), findsOneWidget);
  });

  testWidgets('renders range + state as two fragments (Presupuestos case)',
      (tester) async {
    await pump(
      tester,
      PeriodStepper(
        previousLabel: 'Periodo anterior',
        nextLabel: 'Periodo siguiente',
        rangeLabel: '25 ago – 25 sep',
        stateLabel: '· vigente',
        onPrevious: () {},
        onNext: () {},
      ),
    );

    expect(find.text('25 ago – 25 sep'), findsOneWidget);
    expect(find.text('· vigente'), findsOneWidget);
  });

  testWidgets('the Context Row is hidden unless both icon and label are set',
      (tester) async {
    await pump(
      tester,
      PeriodStepper(
        previousLabel: 'Periodo anterior',
        nextLabel: 'Periodo siguiente',
        label: 'Julio 2026',
        onPrevious: () {},
        onNext: () {},
      ),
    );

    expect(find.text('Comida del mes'), findsNothing);
  });

  testWidgets('the Context Row renders above the label when both are set',
      (tester) async {
    await pump(
      tester,
      PeriodStepper(
        previousLabel: 'Periodo anterior',
        nextLabel: 'Periodo siguiente',
        label: 'Julio 2026',
        contextIcon: LucideIcons.utensils,
        contextLabel: 'Comida del mes',
        onPrevious: () {},
        onNext: () {},
      ),
    );

    expect(find.text('Comida del mes'), findsOneWidget);
    expect(find.byIcon(LucideIcons.utensils), findsOneWidget);
  });

  testWidgets('tapping the left chevron calls onPrevious', (tester) async {
    var tapped = false;
    await pump(
      tester,
      PeriodStepper(
        previousLabel: 'Periodo anterior',
        nextLabel: 'Periodo siguiente',
        label: 'Julio 2026',
        onPrevious: () => tapped = true,
        onNext: () {},
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('tapping the right chevron calls onNext', (tester) async {
    var tapped = false;
    await pump(
      tester,
      PeriodStepper(
        previousLabel: 'Periodo anterior',
        nextLabel: 'Periodo siguiente',
        label: 'Julio 2026',
        onPrevious: () {},
        onNext: () => tapped = true,
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.chevronRight));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('a null onPrevious/onNext disables the matching chevron',
      (tester) async {
    const previousTapped = false;
    var nextTapped = false;
    await pump(
      tester,
      PeriodStepper(
        previousLabel: 'Periodo anterior',
        nextLabel: 'Periodo siguiente',
        label: 'Julio 2026',
        onPrevious: null,
        onNext: () => nextTapped = true,
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pump();
    expect(previousTapped, isFalse);

    await tester.tap(find.byIcon(LucideIcons.chevronRight));
    await tester.pump();
    expect(nextTapped, isTrue);
  });
}
