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
      'el chip activo es sólido (primary + on-primary); los demás son neutros',
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
    expect(
      materials.map((material) => material.color).toList(),
      containsAll(<Color>[AppColors.light.primary, AppColors.light.muted]),
    );
    expect(
      materials.where((material) => material.color == AppColors.light.primary),
      hasLength(1),
    );

    final selectedText = tester.widget<Text>(find.text('Mes'));
    expect(selectedText.style?.color, AppColors.light.onPrimary);

    final unselectedText = tester.widget<Text>(find.text('Semana'));
    expect(unselectedText.style?.color, AppColors.light.textSecondary);
  });

  testWidgets(
      'tema oscuro: el chip activo resuelve primary/muted de AppColors.dark, no los de light',
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
      expect(material.color, isNot(AppColors.light.muted));
    }
    expect(
      materials.map((material) => material.color).toList(),
      containsAll(<Color>[AppColors.dark.primary, AppColors.dark.muted]),
    );

    final selectedText = tester.widget<Text>(find.text('Mes'));
    expect(selectedText.style?.color, AppColors.dark.onPrimary);

    final unselectedText = tester.widget<Text>(find.text('Semana'));
    expect(unselectedText.style?.color, AppColors.dark.textSecondary);
    expect(unselectedText.style?.color, isNot(AppColors.light.textSecondary));
  });

  testWidgets(
      'los cinco chips viven en una sola fila y la tira scrollea en vez de '
      'escalar la tipografía en un ancho estrecho', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      appWith(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ScheduledPaymentFrequencyUnitChips(
            frequency: ScheduledPaymentFrequency.monthly,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final tops = tester
        .widgetList<ScheduledPaymentFrequencyUnitChip>(
          find.byType(ScheduledPaymentFrequencyUnitChip),
        )
        .toList()
        .asMap()
        .keys
        .map(
          (index) => tester
              .getTopLeft(
                  find.byType(ScheduledPaymentFrequencyUnitChip).at(index))
              .dy,
        )
        .toSet();
    expect(tops, hasLength(1));
    // The strip must never shrink the label below the design system's
    // minimum: on a narrow screen it scrolls instead of scaling.
    expect(find.byType(FittedBox), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ScheduledPaymentFrequencyUnitChips),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });
}
