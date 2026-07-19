import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_mode_radio_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  Widget appWith(Widget child, {Brightness brightness = Brightness.light}) =>
      MaterialApp(
        theme:
            brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(body: child),
      );

  testWidgets(
      'seleccionada: icon wrap en blanco/primary y radio relleno con check',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentModeRadioCard(
          selected: true,
          icon: LucideIcons.zap,
          title: 'Automático',
          subtitle: 'Se aplica solo',
          onTap: () {},
        ),
      ),
    );

    final modeIcon = tester.widget<Icon>(find.byIcon(LucideIcons.zap));
    expect(modeIcon.color, AppColors.light.primary);

    final checkIcon = tester.widget<Icon>(find.byIcon(LucideIcons.check));
    expect(checkIcon.color, AppColors.light.onPrimary);
  });

  testWidgets(
      'no seleccionada: icon wrap en primarySoft/textSecondary y radio vacío',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentModeRadioCard(
          selected: false,
          icon: LucideIcons.bell,
          title: 'Manual',
          subtitle: 'Requiere confirmar',
          onTap: () {},
        ),
      ),
    );

    final modeIcon = tester.widget<Icon>(find.byIcon(LucideIcons.bell));
    expect(modeIcon.color, AppColors.light.textSecondary);

    expect(find.byIcon(LucideIcons.check), findsNothing);
  });

  testWidgets('el ícono renderizado depende del modo, no de selected',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentModeRadioCard(
          selected: false,
          icon: LucideIcons.zap,
          title: 'Automático',
          subtitle: 'Se aplica solo',
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.zap), findsOneWidget);
  });

  testWidgets('tocar la tarjeta (esté o no seleccionada) dispara onTap',
      (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentModeRadioCard(
          selected: false,
          icon: LucideIcons.bell,
          title: 'Manual',
          subtitle: 'Requiere confirmar',
          onTap: () => tapCount++,
        ),
      ),
    );

    await tester.tap(find.byType(ScheduledPaymentModeRadioCard));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('muestra el título y subtítulo recibidos', (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentModeRadioCard(
          selected: true,
          icon: LucideIcons.zap,
          title: 'Automático',
          subtitle: 'Se aplica sin intervención',
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Automático'), findsOneWidget);
    expect(find.text('Se aplica sin intervención'), findsOneWidget);
  });

  testWidgets(
      'tema oscuro, seleccionada: icon color usa AppColors.dark.primary, no light.primary',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentModeRadioCard(
          selected: true,
          icon: LucideIcons.zap,
          title: 'Automático',
          subtitle: 'Se aplica solo',
          onTap: () {},
        ),
        brightness: Brightness.dark,
      ),
    );

    final modeIcon = tester.widget<Icon>(find.byIcon(LucideIcons.zap));
    expect(modeIcon.color, AppColors.dark.primary);
    expect(modeIcon.color, isNot(AppColors.light.primary));

    final checkIcon = tester.widget<Icon>(find.byIcon(LucideIcons.check));
    expect(checkIcon.color, AppColors.dark.onPrimary);
  });

  testWidgets(
      'tema oscuro, no seleccionada: icon color usa AppColors.dark.textSecondary, no light.textSecondary',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentModeRadioCard(
          selected: false,
          icon: LucideIcons.bell,
          title: 'Manual',
          subtitle: 'Requiere confirmar',
          onTap: () {},
        ),
        brightness: Brightness.dark,
      ),
    );

    final modeIcon = tester.widget<Icon>(find.byIcon(LucideIcons.bell));
    expect(modeIcon.color, AppColors.dark.textSecondary);
    expect(modeIcon.color, isNot(AppColors.light.textSecondary));
  });
}
