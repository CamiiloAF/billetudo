import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/finished_scheduled_payments_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/finished_scheduled_payments_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/finished_scheduled_payments_page.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';

class MockFinishedScheduledPaymentsCubit
    extends MockCubit<FinishedScheduledPaymentsState>
    implements FinishedScheduledPaymentsCubit {}

void main() {
  late MockFinishedScheduledPaymentsCubit cubit;

  setUp(() {
    cubit = MockFinishedScheduledPaymentsCubit();
    when(() => cubit.start()).thenAnswer((_) async {});
  });

  Future<void> pumpPage(
    WidgetTester tester,
    FinishedScheduledPaymentsState state, {
    ValueChanged<String>? onOpenScheduledPayment,
  }) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<FinishedScheduledPaymentsState>.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<FinishedScheduledPaymentsCubit>.value(
          value: cubit,
          child: FinishedScheduledPaymentsPage(
            onOpenScheduledPayment: onOpenScheduledPayment ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('loading: shows the spinner, no list', (tester) async {
    await pumpPage(
      tester,
      const FinishedScheduledPaymentsState(),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ScheduledCard), findsNothing);
  });

  testWidgets('failure: shows the error view, not the list', (tester) async {
    await pumpPage(
      tester,
      const FinishedScheduledPaymentsState(
        status: FinishedScheduledPaymentsStatus.failure,
        failure: DatabaseFailure('boom'),
      ),
    );

    expect(find.byType(ScheduledCard), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('ready + empty: shows the empty state, no cards', (tester) async {
    await pumpPage(
      tester,
      const FinishedScheduledPaymentsState(
        status: FinishedScheduledPaymentsStatus.ready,
      ),
    );

    expect(find.byType(ScheduledCard), findsNothing);
  });

  testWidgets('ready + items: renders one ScheduledCard per finished template',
      (tester) async {
    final items = [
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(),
        accountName: 'Bancolombia',
        categoryName: 'Arriendo',
      ),
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(id: 'sp-2'),
        accountName: 'Nequi',
        categoryName: 'Internet',
      ),
    ];

    await pumpPage(
      tester,
      FinishedScheduledPaymentsState(
        status: FinishedScheduledPaymentsStatus.ready,
        items: items,
      ),
    );

    expect(find.byType(ScheduledCard), findsNWidgets(2));
  });

  testWidgets('tapping a card reports the tapped template id', (tester) async {
    String? opened;
    final items = [
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(id: 'sp-target'),
        accountName: 'Bancolombia',
        categoryName: 'Arriendo',
      ),
    ];

    await pumpPage(
      tester,
      FinishedScheduledPaymentsState(
        status: FinishedScheduledPaymentsStatus.ready,
        items: items,
      ),
      onOpenScheduledPayment: (id) => opened = id,
    );

    await tester.tap(find.byType(ScheduledCard));
    await tester.pump();

    expect(opened, 'sp-target');
  });
}
