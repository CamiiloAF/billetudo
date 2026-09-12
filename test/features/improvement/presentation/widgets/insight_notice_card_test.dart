import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/improvement/domain/entities/insight.dart';
import 'package:billetudo/features/improvement/presentation/widgets/insight_notice_card.dart';
import 'package:billetudo/features/improvement/presentation/widgets/notice_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// `cYVQm` (`Notice Card · Con acción`) tal como se instancia en `Bk8zW` y
/// `Z38Eox`. Tono: informar y habilitar, nunca alarmar.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  Insight charge({int daysUntil = 3}) => Insight(
        id: 'upcomingCharge:1',
        type: InsightType.upcomingCharge,
        subject: 'Netflix',
        relevantOn: DateTime(2026, 9, 12),
        targetId: 'template-1',
        amountMinor: 4490000,
        currency: 'COP',
        daysUntil: daysUntil,
      );

  Widget cardFor(
    Insight insight, {
    ValueChanged<Insight>? onOpen,
    ValueChanged<Insight>? onDismiss,
  }) =>
      InsightNoticeCard(
        insight: insight,
        onOpen: onOpen ?? (_) {},
        onDismiss: onDismiss ?? (_) {},
      );

  testWidgets('cobro próximo: enuncia el hecho y su fecha, con acción directa',
      (tester) async {
    await tester.pumpWidget(appWith(cardFor(charge())));

    expect(find.text('Netflix se cobra en 3 días'), findsOneWidget);
    expect(find.textContaining('Pago programado'), findsOneWidget);
    expect(find.text('Ver pago'), findsOneWidget);
    expect(find.text('Recordar después'), findsOneWidget);
    // Ni orbe ni lenguaje de IA: es dato calculado, no salida de un modelo.
    expect(find.byIcon(LucideIcons.calendarClock), findsOneWidget);
  });

  testWidgets('cobro próximo: hoy y mañana no se dicen "en 0/1 días"',
      (tester) async {
    await tester.pumpWidget(appWith(cardFor(charge(daysUntil: 0))));
    expect(find.text('Netflix se cobra hoy'), findsOneWidget);

    await tester.pumpWidget(appWith(cardFor(charge(daysUntil: 1))));
    expect(find.text('Netflix se cobra mañana'), findsOneWidget);
  });

  testWidgets('las dos acciones responden', (tester) async {
    Insight? opened;
    Insight? dismissed;
    final insight = charge();

    await tester.pumpWidget(
      appWith(
        cardFor(
          insight,
          onOpen: (value) => opened = value,
          onDismiss: (value) => dismissed = value,
        ),
      ),
    );

    await tester.tap(find.text('Ver pago'));
    await tester.pump();
    expect(opened, insight);

    await tester.tap(find.text('Recordar después'));
    await tester.pump();
    expect(dismissed, insight);
  });

  testWidgets('ocurrencia por confirmar: pasado, nunca reproche',
      (tester) async {
    final insight = Insight(
      id: 'pendingConfirmation:1',
      type: InsightType.pendingConfirmation,
      subject: 'El arriendo',
      relevantOn: DateTime(2026, 9, 8),
      targetId: 'template-2',
      amountMinor: 120000000,
      currency: 'COP',
      daysUntil: -1,
    );

    await tester.pumpWidget(appWith(cardFor(insight)));

    expect(
        find.text('El arriendo estaba programado para ayer'), findsOneWidget);
    expect(find.text('Confirmar pago'), findsOneWidget);
    expect(find.text('Todavía no'), findsOneWidget);
  });

  testWidgets('meta cumplida: celebra y no ofrece posponer', (tester) async {
    final insight = Insight(
      id: 'goalMilestone:1:100',
      type: InsightType.goalMilestone,
      subject: 'Viaje a Cartagena',
      relevantOn: DateTime(2026, 9, 9),
      targetId: 'goal-1',
      amountMinor: 300000000,
      currency: 'COP',
      progressPercent: 100,
      targetAmountMinor: 300000000,
    );

    await tester.pumpWidget(appWith(cardFor(insight)));

    expect(
      find.text('¡Llegaste a tu meta Viaje a Cartagena!'),
      findsOneWidget,
    );
    expect(find.text('Ver meta'), findsOneWidget);
    // No hay nada que posponer sobre algo que ya pasó.
    final card = tester.widget<NoticeCard>(find.byType(NoticeCard));
    expect(card.secondaryActionLabel, isNull);
  });

  testWidgets('un nombre largo no empuja las acciones fuera de la tarjeta',
      (tester) async {
    final insight = Insight(
      id: 'upcomingCharge:2',
      type: InsightType.upcomingCharge,
      // Pencil no renderiza ellipsis: lo que allá cabe, aquí puede no caber.
      subject: 'Suscripción anual de la plataforma de streaming de la casa',
      relevantOn: DateTime(2026, 9, 12),
      targetId: 'template-3',
      amountMinor: 4490000,
      currency: 'COP',
      daysUntil: 3,
    );

    await tester.pumpWidget(
      appWith(SizedBox(width: 350, child: cardFor(insight))),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ver pago'), findsOneWidget);
    expect(find.text('Recordar después'), findsOneWidget);
  });
}
