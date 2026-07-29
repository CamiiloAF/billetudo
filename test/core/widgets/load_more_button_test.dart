import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/load_more_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared "Ver más" pill used by Presupuestos, Deudas, Metas and Pagos
/// programados to expand a paginated list in place.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required VoidCallback onPressed,
    bool loading = false,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LoadMoreButton(onPressed: onPressed, loading: loading),
          ),
        ),
      );

  testWidgets('muestra la etiqueta compartida "Ver más"', (tester) async {
    await pump(tester, onPressed: () {});

    expect(find.text('Ver más'), findsOneWidget);
  });

  testWidgets('tocar el botón dispara onPressed', (tester) async {
    var tapped = false;
    await pump(tester, onPressed: () => tapped = true);

    await tester.tap(find.byType(LoadMoreButton));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets(
      'loading muestra un spinner en vez del chevron y deshabilita el tap',
      (tester) async {
    var tapped = false;
    await pump(tester, onPressed: () => tapped = true, loading: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(LoadMoreButton));
    await tester.pump();

    expect(tapped, isFalse);
  });

  testWidgets('sin loading no hay spinner', (tester) async {
    await pump(tester, onPressed: () {});

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
