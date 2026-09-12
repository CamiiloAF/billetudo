import 'dart:async';

import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:billetudo/features/ai/domain/entities/ai_report.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_report_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_report_state.dart';
import 'package:billetudo/features/ai/presentation/widgets/ai_assistant_bubble.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiReportCubit extends MockCubit<AiReportState>
    implements AiReportCubit {}

void main() {
  String? clipboardText;
  late MockAiReportCubit reportCubit;

  setUpAll(() {
    registerFallbackValue(AiReportReason.other);
  });

  setUp(() {
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardText = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });

    // `AiReportSheet.show` resolves its cubit from `getIt` directly (the
    // sheet is not provided by the router the way `AiActionCubit` is), so
    // the DI container needs a real registration for this test to reach it.
    reportCubit = MockAiReportCubit();
    when(() => reportCubit.state).thenReturn(const AiReportState());
    when(() => reportCubit.stream)
        .thenAnswer((_) => const Stream<AiReportState>.empty());
    when(() => reportCubit.reasonSelected(any())).thenReturn(null);
    when(() => reportCubit.commentChanged(any())).thenReturn(null);
    when(
      () => reportCubit.submit(
        reportedText: any(named: 'reportedText'),
        conversationId: any(named: 'conversationId'),
      ),
    ).thenAnswer((_) async {});
    getIt.registerFactory<AiReportCubit>(() => reportCubit);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await getIt.unregister<AiReportCubit>();
  });

  final message = AiMessage(
    id: 'msg-2',
    conversationId: 'conv-1',
    role: AiMessageRole.assistant,
    content: 'Vas bien este mes, gastaste el 40% de tu presupuesto.',
    createdAt: DateTime(2026, 8, 26),
    status: AiMessageStatus.sent,
  );

  Future<void> pumpBubble(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: AiAssistantBubble(
            message: message,
            accountNames: const {},
            debtNames: const {},
            conversationId: 'conv-1',
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // Guards that copying an assistant bubble only ever takes `message.content`
  // — proposals (if any) never leak into the clipboard through this menu.
  testWidgets('long-press abre el menú y "Copiar" copia solo el texto',
      (tester) async {
    await pumpBubble(tester);

    await tester.longPress(find.text(message.content));
    await tester.pumpAndSettle();

    expect(find.text('Copiar'), findsOneWidget);

    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();

    expect(clipboardText, message.content);
  });

  testWidgets(
      '"Reportar" abre la hoja de motivo y envía el texto y la conversación '
      'correctos al confirmar', (tester) async {
    // A real stream, not an empty one: `AiReasonGrid`'s tap only calls
    // `reasonSelected` — the mock has to push the resulting state back for
    // `BlocConsumer` to rebuild "Enviar" as enabled.
    final controller = StreamController<AiReportState>.broadcast();
    addTearDown(controller.close);
    whenListen(
      reportCubit,
      controller.stream,
      initialState: const AiReportState(),
    );
    when(() => reportCubit.reasonSelected(any())).thenAnswer((invocation) {
      final reason = invocation.positionalArguments.single as AiReportReason;
      controller.add(AiReportState(reason: reason));
    });

    await pumpBubble(tester);

    await tester.longPress(find.text(message.content));
    await tester.pumpAndSettle();

    expect(find.text('Reportar'), findsOneWidget);
    await tester.tap(find.text('Reportar'));
    await tester.pumpAndSettle();

    // The sheet is open: its own icon-header title is now on screen.
    expect(find.text('Reportar mensaje'), findsOneWidget);

    await tester.tap(find.text('Ofensivo'));
    await tester.pump();

    await tester.ensureVisible(find.text('Enviar'));
    await tester.tap(find.text('Enviar'));
    await tester.pump();

    verify(
      () => reportCubit.submit(
        reportedText: message.content,
        conversationId: 'conv-1',
      ),
    ).called(1);
  });
}
