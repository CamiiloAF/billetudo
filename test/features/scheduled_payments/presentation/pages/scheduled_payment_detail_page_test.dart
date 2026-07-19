import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_detail.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/scheduled_payment_detail_page.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/scheduled_payment_detail_actions_sheet.dart';
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

  ScheduledPaymentDetail buildDetail({bool isDeleted = false}) =>
      ScheduledPaymentDetail(
        scheduledPayment: buildScheduledPayment(
          tombstonedAt: isDeleted ? DateTime(2026, 8) : null,
        ),
        accountName: 'Bancolombia',
        categoryName: 'Suscripciones',
        historyTotalCount: 0,
      );

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
            onOpenTransaction: (_) {},
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
    expect(find.text('Posponer'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
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
    expect(find.text('Posponer'), findsNothing);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });
}
