import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_frequency_unit_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('pinta un chip por cada frecuencia', (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentFrequencyUnitChips(
          frequency: ScheduledPaymentFrequency.monthly,
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byType(ScheduledPaymentFrequencyUnitChip),
      findsNWidgets(ScheduledPaymentFrequency.values.length),
    );
  });

  testWidgets(
      'tocar un chip distinto al actual llama onChanged con esa frecuencia',
      (tester) async {
    ScheduledPaymentFrequency? selected;
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentFrequencyUnitChips(
          frequency: ScheduledPaymentFrequency.monthly,
          onChanged: (frequency) => selected = frequency,
        ),
      ),
    );

    await tester.tap(find.text('Semana'));
    await tester.pump();

    expect(selected, ScheduledPaymentFrequency.weekly);
  });

  testWidgets('solo un chip queda marcado como seleccionado a la vez',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentFrequencyUnitChips(
          frequency: ScheduledPaymentFrequency.yearly,
          onChanged: (_) {},
        ),
      ),
    );

    final chips = tester.widgetList<ScheduledPaymentFrequencyUnitChip>(
      find.byType(ScheduledPaymentFrequencyUnitChip),
    );
    final selectedChips = chips.where((chip) => chip.selected).toList();
    expect(selectedChips, hasLength(1));
    expect(selectedChips.single.label, 'Año');
  });

  testWidgets(
      'todos los chips comparten el mismo fondo neutro; solo el activo lleva borde y texto primaryDeep',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentFrequencyUnitChips(
          frequency: ScheduledPaymentFrequency.monthly,
          onChanged: (_) {},
        ),
      ),
    );

    final materials = tester.widgetList<Material>(
      find.descendant(
        of: find.byType(ScheduledPaymentFrequencyUnitChip),
        matching: find.byType(Material),
      ),
    );
    for (final material in materials) {
      expect(material.color, AppColors.light.muted);
    }

    final selectedText = tester.widget<Text>(find.text('Mes'));
    expect(selectedText.style?.color, AppColors.light.primaryDeep);

    final unselectedText = tester.widget<Text>(find.text('Semana'));
    expect(unselectedText.style?.color, AppColors.light.textSecondary);
  });

  testWidgets(
      'tema oscuro: el chip activo resuelve muted/primaryDeep de AppColors.dark, no los de light',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScheduledPaymentFrequencyUnitChips(
            frequency: ScheduledPaymentFrequency.monthly,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final materials = tester.widgetList<Material>(
      find.descendant(
        of: find.byType(ScheduledPaymentFrequencyUnitChip),
        matching: find.byType(Material),
      ),
    );
    for (final material in materials) {
      expect(material.color, AppColors.dark.muted);
      expect(material.color, isNot(AppColors.light.muted));
    }

    final selectedText = tester.widget<Text>(find.text('Mes'));
    expect(selectedText.style?.color, AppColors.dark.primaryDeep);
    expect(selectedText.style?.color, isNot(AppColors.light.primaryDeep));

    final unselectedText = tester.widget<Text>(find.text('Semana'));
    expect(unselectedText.style?.color, AppColors.dark.textSecondary);
    expect(unselectedText.style?.color, isNot(AppColors.light.textSecondary));
  });
}
