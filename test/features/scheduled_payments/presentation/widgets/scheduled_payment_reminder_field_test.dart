import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_reminder.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_reminder_field.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/reminder_option_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// HU-08, campo `KXZKA` de `a7x7uy` + hoja `HyuO3`: el recordatorio se elige
/// en un `Form Field` que abre una hoja, NO en una tira de chips inline.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('sin recordatorio: placeholder y campana tachada', (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentReminderField(
          reminder: null,
          showsPermissionNotice: false,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Recordatorio'), findsOneWidget);
    expect(find.text('Sin recordatorio'), findsOneWidget);
    // El estado no depende solo del texto: `bell-off` es la señal redundante.
    expect(find.byIcon(LucideIcons.bellOff), findsOneWidget);
    // El campo no despliega las opciones hasta que lo toquen.
    expect(find.byType(ReminderOptionRow), findsNothing);
  });

  testWidgets('con recordatorio nombra la anticipación elegida',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentReminderField(
          reminder: ScheduledPaymentReminder.threeDaysBefore,
          showsPermissionNotice: false,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('3 días antes'), findsOneWidget);
    expect(find.byIcon(LucideIcons.bell), findsOneWidget);
  });

  testWidgets(
      'al tocarlo abre la hoja con "Sin recordatorio" primero y devuelve la '
      'opción elegida', (tester) async {
    ScheduledPaymentReminder? picked;
    var calls = 0;

    await tester.pumpWidget(
      appWith(
        ScheduledPaymentReminderField(
          reminder: null,
          showsPermissionNotice: false,
          onChanged: (value) {
            calls++;
            picked = value;
          },
        ),
      ),
    );

    await tester.tap(find.text('Sin recordatorio'));
    await tester.pumpAndSettle();

    final rows = tester.widgetList<ReminderOptionRow>(
      find.byType(ReminderOptionRow),
    ).toList();
    expect(rows, hasLength(5));
    // El polo apagado va primero y es el seleccionado por defecto.
    expect(rows.first.label, 'Sin recordatorio');
    expect(rows.first.selected, isTrue);
    expect(rows.first.icon, LucideIcons.bellOff);

    await tester.tap(find.text('Una semana antes'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(picked, ScheduledPaymentReminder.oneWeekBefore);
  });

  testWidgets('cerrar la hoja sin elegir no cambia nada', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      appWith(
        ScheduledPaymentReminderField(
          reminder: ScheduledPaymentReminder.oneDayBefore,
          showsPermissionNotice: false,
          onChanged: (_) => calls++,
        ),
      ),
    );

    await tester.tap(find.text('1 día antes'));
    await tester.pumpAndSettle();
    // Toca el scrim para descartar la hoja.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Descartar no puede leerse como "eligió sin recordatorio".
    expect(calls, 0);
  });

  testWidgets(
      'con el permiso del sistema apagado avisa, sin bloquear la elección',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPaymentReminderField(
          reminder: null,
          showsPermissionNotice: true,
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      find.textContaining('activa las notificaciones'),
      findsOneWidget,
    );
  });
}
