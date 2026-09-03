import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/domain/entities/ai_report.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_report_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_report_state.dart';
import 'package:billetudo/features/ai/presentation/widgets/sheets/ai_report_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiReportCubit extends MockCubit<AiReportState>
    implements AiReportCubit {}

/// The "Reportar mensaje" sheet (`zV9g3`/`G6uAwV`): the reason grid, comment
/// and privacy note are always visible together, and "Enviar" only becomes
/// tappable once a motive is picked.
void main() {
  late MockAiReportCubit cubit;

  setUpAll(() {
    registerFallbackValue(AiReportReason.other);
  });

  setUp(() {
    cubit = MockAiReportCubit();
    when(() => cubit.reasonSelected(any())).thenReturn(null);
    when(() => cubit.commentChanged(any())).thenReturn(null);
    when(
      () => cubit.submit(
        reportedText: any(named: 'reportedText'),
        conversationId: any(named: 'conversationId'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpBody(WidgetTester tester, AiReportState state) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<AiReportState>.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AiReportCubit>.value(
          value: cubit,
          child: const Scaffold(
            body: AiReportSheetBody(reportedText: 'texto reportado'),
          ),
        ),
      ),
    );
  }

  testWidgets('shows every reason and the privacy note up front',
      (tester) async {
    await pumpBody(tester, const AiReportState());

    expect(find.text('Ofensivo'), findsOneWidget);
    expect(find.text('Incorrecto'), findsOneWidget);
    expect(find.text('Dañino'), findsOneWidget);
    expect(find.text('Privacidad'), findsOneWidget);
    expect(find.text('Otro'), findsOneWidget);
    expect(
      find.textContaining('Le enviaremos este mensaje a nuestro equipo'),
      findsOneWidget,
    );
  });

  testWidgets('Enviar is disabled until a reason is picked', (tester) async {
    await pumpBody(tester, const AiReportState());

    final button = tester
        .widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('picking a reason calls cubit.reasonSelected', (tester) async {
    await pumpBody(tester, const AiReportState());

    await tester.tap(find.text('Incorrecto'));

    verify(() => cubit.reasonSelected(AiReportReason.wrong)).called(1);
  });

  testWidgets('Enviar is enabled with a reason and calls cubit.submit',
      (tester) async {
    await pumpBody(
      tester,
      const AiReportState(reason: AiReportReason.wrong),
    );

    final button = tester
        .widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byWidgetPredicate((w) => w is FilledButton));

    verify(
      () => cubit.submit(
        reportedText: 'texto reportado',
        conversationId: null,
      ),
    ).called(1);
  });

  testWidgets('shows the unauthenticated message on that failure',
      (tester) async {
    await pumpBody(
      tester,
      const AiReportState(
        reason: AiReportReason.other,
        status: AiReportStatus.failure,
        failure: AiFailure('nope', code: AiFailureCode.unauthenticated),
      ),
    );

    expect(
      find.text('Necesitas iniciar sesión para reportar un mensaje.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a generic message for any other failure', (tester) async {
    await pumpBody(
      tester,
      const AiReportState(
        reason: AiReportReason.other,
        status: AiReportStatus.failure,
        failure: DatabaseFailure('boom'),
      ),
    );

    expect(
      find.text('No pudimos enviar tu reporte. Inténtalo de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('closes with true once the report is submitted', (tester) async {
    whenListen(
      cubit,
      Stream.fromIterable([
        const AiReportState(
          reason: AiReportReason.other,
          status: AiReportStatus.submitted,
        ),
      ]),
      initialState: const AiReportState(reason: AiReportReason.other),
    );

    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The provider has to wrap the whole `Navigator` (via `builder`), not
        // just `home` — a pushed route's page is a sibling in the overlay,
        // not a descendant of whatever only wraps the first route's child.
        builder: (context, child) =>
            BlocProvider<AiReportCubit>.value(value: cubit, child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: AiReportSheetBody(
                          reportedText: 'texto reportado',
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
