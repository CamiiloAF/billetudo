import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/utils/ai_client_context.dart';
import 'package:billetudo/features/ai/domain/entities/ai_report.dart';
import 'package:billetudo/features/ai/domain/usecases/report_ai_message.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_report_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_report_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportAiMessage extends Mock implements ReportAiMessage {}

class MockAiClientContextProvider extends Mock
    implements AiClientContextProvider {}

void main() {
  late MockReportAiMessage reportAiMessage;
  late MockAiClientContextProvider clientContext;

  const context = AiClientContext(
    locale: 'es-CO',
    timezone: 'America/Bogota',
    clientVersion: '1.12.0+134',
  );

  setUpAll(() {
    registerFallbackValue(
      const AiReport(
        reason: AiReportReason.other,
        reportedText: 'x',
        clientVersion: '0',
      ),
    );
  });

  setUp(() {
    reportAiMessage = MockReportAiMessage();
    clientContext = MockAiClientContextProvider();
    when(() => clientContext.resolve()).thenAnswer((_) async => context);
  });

  AiReportCubit build() => AiReportCubit(reportAiMessage, clientContext);

  blocTest<AiReportCubit, AiReportState>(
    'reasonSelected updates state and clears a previous failure',
    build: build,
    seed: () => const AiReportState(
      status: AiReportStatus.failure,
      failure: DatabaseFailure('boom'),
    ),
    act: (cubit) => cubit.reasonSelected(AiReportReason.harmful),
    expect: () => [
      isA<AiReportState>()
          .having((s) => s.reason, 'reason', AiReportReason.harmful)
          .having((s) => s.failure, 'failure', isNull),
    ],
  );

  test('submit() does nothing without a selected reason', () async {
    final cubit = build();

    await cubit.submit(reportedText: 'algo raro');

    verifyNever(() => reportAiMessage(any()));
    expect(cubit.state.status, AiReportStatus.editing);
  });

  blocTest<AiReportCubit, AiReportState>(
    'submit() files the report with a trimmed comment and reports success',
    setUp: () {
      when(() => reportAiMessage(any()))
          .thenAnswer((_) async => const Right(unit));
    },
    build: build,
    seed: () => const AiReportState(
      reason: AiReportReason.offensive,
      comment: '  demasiado agresivo  ',
    ),
    act: (cubit) =>
        cubit.submit(reportedText: 'contenido feo', conversationId: 'conv-1'),
    expect: () => [
      isA<AiReportState>()
          .having((s) => s.status, 'status', AiReportStatus.submitting),
      isA<AiReportState>()
          .having((s) => s.status, 'status', AiReportStatus.submitted),
    ],
    verify: (_) {
      final captured = verify(() => reportAiMessage(captureAny()))
          .captured
          .single as AiReport;
      expect(captured.reason, AiReportReason.offensive);
      expect(captured.reportedText, 'contenido feo');
      expect(captured.conversationId, 'conv-1');
      expect(captured.comment, 'demasiado agresivo');
      expect(captured.clientVersion, '1.12.0+134');
    },
  );

  blocTest<AiReportCubit, AiReportState>(
    'submit() sends null comment when only blank text was typed',
    setUp: () {
      when(() => reportAiMessage(any()))
          .thenAnswer((_) async => const Right(unit));
    },
    build: build,
    seed: () => const AiReportState(
      reason: AiReportReason.other,
      comment: '   ',
    ),
    act: (cubit) => cubit.submit(reportedText: 'x'),
    verify: (_) {
      final captured = verify(() => reportAiMessage(captureAny()))
          .captured
          .single as AiReport;
      expect(captured.comment, isNull);
    },
  );

  blocTest<AiReportCubit, AiReportState>(
    'submit() surfaces a failure without leaving the sheet stuck submitting',
    setUp: () {
      when(() => reportAiMessage(any())).thenAnswer(
        (_) async => const Left(
          AiFailure('nope', code: AiFailureCode.unauthenticated),
        ),
      );
    },
    build: build,
    seed: () => const AiReportState(reason: AiReportReason.privacy),
    act: (cubit) => cubit.submit(reportedText: 'x'),
    expect: () => [
      isA<AiReportState>()
          .having((s) => s.status, 'status', AiReportStatus.submitting),
      isA<AiReportState>()
          .having((s) => s.status, 'status', AiReportStatus.failure)
          .having((s) => s.failure, 'failure', isA<AiFailure>()),
    ],
  );
}
