import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_history_entry.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_detail.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_linked_debt.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/scheduled_payment_detail_page.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_card.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_skipped_history_row.dart';
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
    ScheduledPaymentLinkedDebt? linkedDebt,
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
      // These tests treat the total as generated transactions (no skipped
      // events), so `once`'s "already fired" fact keys off the same number.
      generatedTransactionCount: historyTotalCount,
      pendingOccurrence:
          pending ? buildPendingOccurrence(scheduledPayment: payment) : null,
      linkedDebt: linkedDebt,
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester,
    ScheduledPaymentDetailState state, {
    ValueChanged<String>? onOpenDebt,
    void Function(ScheduledPaymentLinkedDebt debt, String spId)?
        onEditInstallment,
  }) async {
    // A tall surface so the whole detail (hero + ficha + history) fits without
    // the last rows landing below the default 600px viewport — otherwise a tap
    // on the "Recuperar" link at the bottom would miss its hit test.
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
            onOpenDebt: onOpenDebt ?? (_) {},
            onEditInstallment: onEditInstallment ?? (_, __) {},
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

    // The category name now lives in the identity strip subtitle joined with
    // the type ("Suscripciones · Gasto"), so it is no longer an exact-match
    // Text — it moved out of the title as of the category→subtitle change.
    expect(find.textContaining('Suscripciones'), findsOneWidget);
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

  testWidgets('la sección de historial se llama "Historial"', (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(),
      ),
    );
    await tester.dragUntilVisible(
      find.text('Historial'),
      find.byType(ListView),
      const Offset(0, -80),
    );

    expect(find.text('Historial'), findsOneWidget);
  });

  testWidgets(
      'un evento omitido se pinta como fila de omitido con badge "Omitido", '
      'monto tachado y enlace "Recuperar"', (tester) async {
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(historyTotalCount: 1),
        history: [
          ScheduledSkippedHistoryEntry(
            occurrenceId: 'occ-1',
            date: DateTime(2026, 6, 13),
            amountMinor: 145000000,
            currency: 'COP',
          ),
        ],
      ),
    );
    await tester.dragUntilVisible(
      find.byType(ScheduledSkippedHistoryRow),
      find.byType(ListView),
      const Offset(0, -80),
    );

    expect(find.byType(ScheduledSkippedHistoryRow), findsOneWidget);
    expect(find.text('Omitido'), findsOneWidget);
    expect(find.text('Recuperar'), findsOneWidget);
    final amount = tester.widget<Text>(find.textContaining('1.450.000'));
    expect(amount.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets(
      'tocar "Recuperar" dispara recoverSkipped con el id de la '
      'ocurrencia', (tester) async {
    when(() => cubit.recoverSkipped(any())).thenAnswer((_) async {});
    await pumpDetail(
      tester,
      ScheduledPaymentDetailState(
        status: ScheduledPaymentDetailStatus.ready,
        detail: buildDetail(historyTotalCount: 1),
        history: [
          ScheduledSkippedHistoryEntry(
            occurrenceId: 'occ-1',
            date: DateTime(2026, 6, 13),
            amountMinor: 145000000,
            currency: 'COP',
          ),
        ],
      ),
    );
    await tester.dragUntilVisible(
      find.text('Recuperar'),
      find.byType(ListView),
      const Offset(0, -80),
    );

    await tester.tap(find.text('Recuperar'));
    await tester.pump();

    verify(() => cubit.recoverSkipped('occ-1')).called(1);
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

  group('HU-03: cross-link con la deuda', () {
    const linkedDebt = ScheduledPaymentLinkedDebt(
      id: 'debt-1',
      name: 'Crédito vehicular',
      iOwe: true,
    );

    testWidgets(
        'una cuota muestra la card "Cuota de <deuda> · <dirección>" y navega '
        'al detalle de la deuda al tocarla', (tester) async {
      String? openedDebtId;
      await pumpDetail(
        tester,
        ScheduledPaymentDetailState(
          status: ScheduledPaymentDetailStatus.ready,
          detail: buildDetail(linkedDebt: linkedDebt),
        ),
        onOpenDebt: (id) => openedDebtId = id,
      );

      expect(find.text('Cuota de'), findsOneWidget);
      expect(find.text('Crédito vehicular · Yo debo'), findsOneWidget);

      await tester.tap(find.text('Crédito vehicular · Yo debo'));
      await tester.pumpAndSettle();
      expect(openedDebtId, 'debt-1');
    });

    testWidgets(
        'una plantilla ordinaria (sin deuda) no muestra la card de cuota',
        (tester) async {
      await pumpDetail(
        tester,
        ScheduledPaymentDetailState(
          status: ScheduledPaymentDetailStatus.ready,
          detail: buildDetail(),
        ),
      );

      expect(find.text('Cuota de'), findsNothing);
    });

    testWidgets(
        'editar una cuota hace deep-link a Configurar cuota de la deuda, no al '
        'formulario suelto', (tester) async {
      ScheduledPaymentLinkedDebt? editedDebt;
      String? editedSpId;
      await pumpDetail(
        tester,
        ScheduledPaymentDetailState(
          status: ScheduledPaymentDetailStatus.ready,
          detail: buildDetail(linkedDebt: linkedDebt),
        ),
        onEditInstallment: (debt, spId) {
          editedDebt = debt;
          editedSpId = spId;
        },
      );

      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(editedDebt, linkedDebt);
      expect(editedSpId, 'sp-1');
    });
  });
}
