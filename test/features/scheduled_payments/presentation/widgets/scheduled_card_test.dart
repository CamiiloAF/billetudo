import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_card.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_finished_chip.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_manual_mode_chip.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_pending_count_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scheduled_payment_fixtures.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets(
      'item 3/19: the title is the payment name (note), category in the '
      'sub-line', (tester) async {
    final entry = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(amountMinor: 25000, note: 'Gym'),
      accountName: 'Bancolombia',
      categoryName: 'Salud',
    );

    await tester.pumpWidget(
      appWith(ScheduledCard(entry: entry, onTap: () {})),
    );

    // Title is the note, never the category.
    expect(find.text('Gym'), findsOneWidget);
    // Category still shows, but only in the "Cuenta · Categoría" sub-line.
    expect(find.text('Bancolombia · Salud'), findsOneWidget);
    // Expense: signed with a '-' prefix, like the movements list.
    expect(find.textContaining(RegExp(r'^-')), findsOneWidget);
    expect(find.byType(ScheduledPendingCountChip), findsNothing);
  });

  testWidgets(
      'item 3/19: with no note the title is the generic label, never the '
      'category', (tester) async {
    final entry = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(amountMinor: 25000),
      accountName: 'Bancolombia',
      categoryName: 'Salud',
    );

    await tester.pumpWidget(
      appWith(ScheduledCard(entry: entry, onTap: () {})),
    );

    expect(find.text('Pago programado'), findsOneWidget);
    // The category is not promoted to the big title.
    expect(find.text('Salud'), findsNothing);
    expect(find.text('Bancolombia · Salud'), findsOneWidget);
  });

  testWidgets('the ×N chip belongs to the pending row, never to the card',
      (tester) async {
    final entry = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(),
      accountName: 'Bancolombia',
      categoryName: 'Arriendo',
      pendingOccurrenceCount: 3,
    );

    await tester.pumpWidget(
      appWith(ScheduledCard(entry: entry, onTap: () {})),
    );

    expect(find.byType(ScheduledPendingCountChip), findsNothing);
    expect(find.text('×3'), findsNothing);
  });

  testWidgets('the sub-line reads "Cuenta · Categoría", never the date',
      (tester) async {
    final entry = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(),
      accountName: 'Bancolombia',
      categoryName: 'Arriendo',
    );

    await tester.pumpWidget(
      appWith(ScheduledCard(entry: entry, onTap: () {})),
    );

    expect(find.text('Bancolombia · Arriendo'), findsOneWidget);
  });

  testWidgets('the "Te avisamos" chip only shows in manual mode',
      (tester) async {
    ScheduledPaymentSummary entryWith({required bool requiresConfirmation}) =>
        ScheduledPaymentSummary(
          scheduledPayment: buildScheduledPayment(
            requiresConfirmation: requiresConfirmation,
          ),
          accountName: 'Bancolombia',
          categoryName: 'Arriendo',
        );

    await tester.pumpWidget(
      appWith(
        ScheduledCard(
          entry: entryWith(requiresConfirmation: false),
          onTap: () {},
        ),
      ),
    );
    expect(find.byType(ScheduledManualModeChip), findsNothing);

    await tester.pumpWidget(
      appWith(
        ScheduledCard(
          entry: entryWith(requiresConfirmation: true),
          onTap: () {},
        ),
      ),
    );
    expect(find.byType(ScheduledManualModeChip), findsOneWidget);
  });

  testWidgets('income amount uses incomeText, not textPrimary', (tester) async {
    final entry = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(
        type: ScheduledPaymentType.income,
        amountMinor: 50000,
      ),
      accountName: 'Bancolombia',
      categoryName: 'Salario',
    );

    await tester.pumpWidget(
      appWith(ScheduledCard(entry: entry, onTap: () {})),
    );

    final amountFinder = find.textContaining('+');
    expect(amountFinder, findsOneWidget);
    final amountText = tester.widget<Text>(amountFinder);
    expect(amountText.style?.color, AppColors.light.incomeText);
  });

  testWidgets('tapping the card triggers onTap once', (tester) async {
    var tapCount = 0;
    final entry = ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(),
      accountName: 'Bancolombia',
      categoryName: 'Arriendo',
    );

    await tester.pumpWidget(
      appWith(ScheduledCard(entry: entry, onTap: () => tapCount++)),
    );

    await tester.tap(find.byType(ScheduledCard));
    await tester.pump();

    expect(tapCount, 1);
  });

  group('modo terminada (filtro "Terminados")', () {
    ScheduledPaymentSummary finishedEntry() => ScheduledPaymentSummary(
          scheduledPayment: buildScheduledPayment(
            amountMinor: 25000,
            requiresConfirmation: true,
          ),
          accountName: 'Bancolombia',
          categoryName: 'Gimnasio',
          lastPaymentDate: DateTime(2026, 3, 15),
        );

    testWidgets(
        'cambia el eje inferior: chip "Terminada" y "Último pago · fecha" '
        'con año, sin cadencia ni cuenta regresiva', (tester) async {
      await tester.pumpWidget(
        appWith(
          ScheduledCard(entry: finishedEntry(), isFinished: true, onTap: () {}),
        ),
      );

      expect(find.byType(ScheduledFinishedChip), findsOneWidget);
      expect(find.text('Terminada'), findsOneWidget);
      expect(find.text('Último pago · 15 mar 2026'), findsOneWidget);
      expect(find.byType(ScheduledFrequencyChip), findsNothing);
      expect(find.byType(ScheduledManualModeChip), findsNothing);
    });

    testWidgets(
        'sin último pago el slot queda vacío, nunca con la fecha de fin',
        (tester) async {
      final entry = ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(endDate: DateTime(2026, 3, 31)),
        accountName: 'Bancolombia',
        categoryName: 'Gimnasio',
      );

      await tester.pumpWidget(
        appWith(ScheduledCard(entry: entry, isFinished: true, onTap: () {})),
      );

      expect(find.textContaining('Último pago'), findsNothing);
      expect(find.textContaining('2026'), findsNothing);
    });

    testWidgets(
        'mantiene la misma geometría: el monto sigue arriba y todo '
        'el InkWell es tocable', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        appWith(
          ScheduledCard(
            entry: finishedEntry(),
            isFinished: true,
            onTap: () => taps++,
          ),
        ),
      );

      final card = tester.getRect(find.byType(ScheduledCard));
      final ink = tester.getRect(find.byType(InkWell).first);
      expect(ink.size, card.size);

      // La esquina inferior izquierda (fuera de la fila superior) abre igual.
      await tester.tapAt(Offset(card.left + 8, card.bottom - 8));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
