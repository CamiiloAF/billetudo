import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_detail.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/scheduled_payment_detail_page.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_card.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/scheduled_payment_detail_actions_sheet.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_header_button.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';

class MockScheduledPaymentDetailCubit
    extends MockCubit<ScheduledPaymentDetailState>
    implements ScheduledPaymentDetailCubit {}

void main() {
  late MockScheduledPaymentDetailCubit cubit;

  setUp(() {
    cubit = MockScheduledPaymentDetailCubit();
  });

  ScheduledPaymentDetail buildDetail({
    bool isDeleted = false,
    ScheduledPaymentFrequency frequency = ScheduledPaymentFrequency.monthly,
    int historyTotalCount = 0,
    DateTime? nextDate,
    bool pending = false,
  }) {
    final payment = buildScheduledPayment(
      frequency: frequency,
      nextDate: nextDate,
      requiresConfirmation: pending,
      tombstonedAt: isDeleted ? DateTime(2026, 8) : null,
    );
    return ScheduledPaymentDetail(
      scheduledPayment: payment,
      accountName: 'Bancolombia',
      categoryName: 'Suscripciones',
      historyTotalCount: historyTotalCount,
      pendingOccurrence:
          pending ? buildPendingOccurrence(scheduledPayment: payment) : null,
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester,
    ScheduledPaymentDetailState state,
  ) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<ScheduledPaymentDetailState>.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<ScheduledPaymentDetailCubit>.value(
          value: cubit,
          child: ScheduledPaymentDetailPage(
            onEdit: (_) {},
            onOpenTransaction: (_) async => null,
          ),
        ),
      ),
    );
  }

  testWidgets('smoke: renderiza sin crashear y muestra los datos clave',
      (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(),
      ),
    );

    expect(find.text('Suscripciones'), findsOneWidget);
    expect(find.textContaining('Bancolombia'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'el hero responde "cuándo y de cuánto": eyebrow en mayúsculas, la '
      'fecha grande del próximo pago y luego el monto', (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(nextDate: DateTime(2026, 8, 13)),
      ),
    );

    expect(find.text('PRÓXIMO PAGO'), findsOneWidget);
    expect(find.text('13 de agosto, 2026'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
  });

  testWidgets(
      'once ya generado (Eyold): el hero dice PAGO EJECUTADO, sin pill, y la '
      'ficha dice Terminada', (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(
          frequency: ScheduledPaymentFrequency.once,
          nextDate: DateTime(2026, 7, 26),
          historyTotalCount: 1,
        ),
      ),
    );

    expect(find.text('PAGO EJECUTADO'), findsOneWidget);
    expect(find.text('PRÓXIMO PAGO'), findsNothing);
    expect(find.byType(ScheduledDueInChip), findsNothing);
    expect(find.text('Terminada'), findsOneWidget);
    expect(find.text('Activa'), findsNothing);
    expect(find.textContaining('Una sola vez el 26 de julio'), findsOneWidget);
  });

  testWidgets('la sección de historial se llama "Ya generados"',
      (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(),
      ),
    );
    await tester.dragUntilVisible(
      find.text('Ya generados'),
      find.byType(ListView),
      const Offset(0, -80),
    );

    expect(find.text('Ya generados'), findsOneWidget);
  });

  testWidgets('estado de carga muestra un spinner, no la data', (tester) async {
    await pumpDetail(tester, const ScheduledPaymentDetailState());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Suscripciones'), findsNothing);
  });

  testWidgets(
      'tocar el menú ⋮ abre la hoja de acciones con el divisor entre '
      'ocurrencia y plantilla (plantilla activa: puede posponer)',
      (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduledPaymentDetailActionsSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ScheduledPaymentDetailActionsSheet),
        matching: find.byType(Divider),
      ),
      findsOneWidget,
    );
    expect(find.text('Posponer este pago'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar pago programado'), findsOneWidget);
  });

  testWidgets(
      'pago único (once): la hoja de acciones no ofrece posponer — mover su '
      'fecha es editar la plantilla, no posponer una ocurrencia (HU-07)',
      (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(frequency: ScheduledPaymentFrequency.once),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();

    expect(find.text('Posponer este pago'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ScheduledPaymentDetailActionsSheet),
        matching: find.byType(Divider),
      ),
      findsNothing,
    );
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar pago programado'), findsOneWidget);
  });

  testWidgets(
      'plantilla inactiva (tombstoned): la hoja de acciones no ofrece '
      'posponer ni el divisor', (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(isDeleted: true),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ScheduledPaymentDetailActionsSheet),
        matching: find.byType(Divider),
      ),
      findsNothing,
    );
    expect(find.text('Posponer este pago'), findsNothing);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar pago programado'), findsOneWidget);
  });

  testWidgets(
      'el header lleva el título "Detalle", el arrow-left y el ⋮ en círculo '
      '(OY2Kj)', (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(),
      ),
    );

    expect(find.text('Detalle'), findsOneWidget);
    final buttons = tester.widgetList<TransactionHeaderButton>(
      find.byType(TransactionHeaderButton),
    );
    expect(buttons, hasLength(2));
    expect(
      buttons.map((button) => button.icon),
      containsAll(<IconData>[
        LucideIcons.arrowLeft,
        LucideIcons.ellipsisVertical,
      ]),
    );
  });

  testWidgets(
      'con ocurrencia pendiente el estado se expresa en la ficha, no como un '
      'segundo pill en el hero', (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(pending: true),
      ),
    );

    expect(find.text('Pendiente de confirmar'), findsOneWidget);
    expect(find.text('Activa'), findsNothing);
    // The hero keeps exactly one pill: the countdown.
    expect(find.byType(ScheduledDueInChip), findsOneWidget);
  });
}
