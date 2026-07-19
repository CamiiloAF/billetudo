import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_interval_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('muestra el intervalo actual', (tester) async {
    await tester.pumpWidget(
      appWith(ScheduledPaymentIntervalStepper(interval: 3, onChanged: (_) {})),
    );

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('el botón "+" incrementa en uno', (tester) async {
    int? result;
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentIntervalStepper(
          interval: 3,
          onChanged: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.plus));
    await tester.pump();

    expect(result, 4);
  });

  testWidgets('el botón "-" decrementa en uno', (tester) async {
    int? result;
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentIntervalStepper(
          interval: 3,
          onChanged: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.minus));
    await tester.pump();

    expect(result, 2);
  });

  testWidgets('en el mínimo (1), el botón "-" queda deshabilitado', (tester) async {
    var called = false;
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentIntervalStepper(
          interval: 1,
          onChanged: (_) => called = true,
        ),
      ),
    );

    final minusButton =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, LucideIcons.minus));
    expect(minusButton.onPressed, isNull);

    await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.minus));
    await tester.pump();
    expect(called, isFalse);
  });

  testWidgets('en el máximo (99), el botón "+" queda deshabilitado', (tester) async {
    var called = false;
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentIntervalStepper(
          interval: 99,
          onChanged: (_) => called = true,
        ),
      ),
    );

    final plusButton =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, LucideIcons.plus));
    expect(plusButton.onPressed, isNull);

    await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.plus));
    await tester.pump();
    expect(called, isFalse);
  });
}
