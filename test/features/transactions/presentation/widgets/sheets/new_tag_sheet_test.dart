import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/new_tag_sheet.dart';
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

  testWidgets(
      'muestra el label arriba del campo y el ícono tag dentro (c0ONUy)',
      (tester) async {
    await tester.pumpWidget(appWith(const NewTagSheet()));

    expect(find.text('Nueva etiqueta'), findsOneWidget);
    expect(find.text('Nombre de la etiqueta'), findsOneWidget);
    expect(find.byIcon(LucideIcons.tag), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Crear'), findsOneWidget);
  });

  testWidgets('el botón "Crear" resuelve el nombre escrito', (tester) async {
    late String? result;

    await tester.pumpWidget(
      appWith(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push(
                MaterialPageRoute<String>(
                  builder: (_) => const Scaffold(body: NewTagSheet()),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ahorro');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(result, 'ahorro');
  });
}
