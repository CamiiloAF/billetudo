import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_chat_state.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_consent_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_consent_state.dart';
import 'package:billetudo/features/ai/presentation/pages/ai_assistant_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiConsentCubit extends MockCubit<AiConsentState>
    implements AiConsentCubit {}

class MockAiChatCubit extends MockCubit<AiChatState> implements AiChatCubit {}

void main() {
  late MockAiConsentCubit consentCubit;
  late MockAiChatCubit chatCubit;

  setUpAll(() {
    registerFallbackValue(const AiConsentState());
    registerFallbackValue(const AiChatState());
  });

  setUp(() {
    consentCubit = MockAiConsentCubit();
    chatCubit = MockAiChatCubit();
    when(() => consentCubit.start()).thenAnswer((_) async {});
    when(
      () => chatCubit.start(conversationId: any(named: 'conversationId')),
    ).thenAnswer((_) async {});
    when(
      () => chatCubit.startNew(insightType: any(named: 'insightType')),
    ).thenAnswer((_) async {});
    when(() => chatCubit.updateDraft(any())).thenReturn(null);
    when(() => chatCubit.send()).thenAnswer((_) async {});
  });

  /// Pumps [AiAssistantPage] with the consent cubit starting `checking` and
  /// then emitting `granted` (the transition `_startChatOnce`'s listener
  /// actually reacts to — pumping already-granted as the initial state would
  /// never fire `BlocConsumer`'s `listenWhen`), while the chat cubit is
  /// signed in from the very first frame so [AiAssistantPage._startChatOnce]
  /// only has one gate left to clear when consent lands.
  Future<void> pumpPage(
    WidgetTester tester, {
    String? initialQuestion,
    String? initialInsightType,
    String? initialConversationId,
  }) async {
    whenListen(
      consentCubit,
      Stream.value(const AiConsentState(status: AiConsentStatus.granted)),
      initialState: const AiConsentState(),
    );
    whenListen(
      chatCubit,
      const Stream<AiChatState>.empty(),
      initialState: const AiChatState(
        status: AiChatStatus.ready,
        isSignedIn: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AiConsentCubit>.value(value: consentCubit),
            BlocProvider<AiChatCubit>.value(value: chatCubit),
          ],
          child: AiAssistantPage(
            onBack: () {},
            onOpenHistory: () async => null,
            onSignIn: () {},
            initialQuestion: initialQuestion,
            initialInsightType: initialInsightType,
            initialConversationId: initialConversationId,
          ),
        ),
      ),
    );
    // Flushes the consent stream's `granted` emission (which triggers
    // `_startChatOnce`) and the `unawaited` futures it kicks off.
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'con initialConversationId no nulo: reabre esa conversación directo, '
    'ignorando initialQuestion',
    (tester) async {
      await pumpPage(
        tester,
        initialConversationId: 'conv-42',
        initialQuestion: '¿Cómo voy este mes?',
        initialInsightType: 'spendingVsAverage',
      );

      verify(
        () => chatCubit.start(conversationId: 'conv-42'),
      ).called(1);
      verifyNever(
        () => chatCubit.startNew(insightType: any(named: 'insightType')),
      );
      verifyNever(() => chatCubit.updateDraft(any()));
      verifyNever(() => chatCubit.send());
    },
  );

  testWidgets(
    'solo con initialQuestion: arranca un hilo nuevo, llena el borrador y '
    'lo envía',
    (tester) async {
      await pumpPage(
        tester,
        initialQuestion: '¿Cómo voy este mes?',
        initialInsightType: 'spendingVsAverage',
      );

      verify(
        () => chatCubit.startNew(insightType: 'spendingVsAverage'),
      ).called(1);
      verify(() => chatCubit.updateDraft('¿Cómo voy este mes?')).called(1);
      verify(() => chatCubit.send()).called(1);
      verifyNever(
        () => chatCubit.start(conversationId: any(named: 'conversationId')),
      );
    },
  );

  testWidgets(
    'sin initialQuestion ni initialConversationId: resume/crea sin id',
    (tester) async {
      await pumpPage(tester);

      verify(() => chatCubit.start(conversationId: null)).called(1);
      verifyNever(
        () => chatCubit.startNew(insightType: any(named: 'insightType')),
      );
      verifyNever(() => chatCubit.updateDraft(any()));
      verifyNever(() => chatCubit.send());
    },
  );

  testWidgets(
      'una conversación reanudada (mensajes ya presentes en el PRIMER '
      'frame, no llegados por un emit posterior) abre con el scroll en el '
      'último mensaje, no en el primero — reproduce el mismo hueco de '
      "BlocConsumer que ya se arregló para _startChatOnce: 'listener' solo "
      'reacciona a una transición después de suscribirse, nunca al estado '
      'que el cubit ya traía puesto', (tester) async {
    final messages = List.generate(
      30,
      (i) => AiMessage(
        id: 'm$i',
        conversationId: 'conv-1',
        role: i.isEven ? AiMessageRole.user : AiMessageRole.assistant,
        content: 'Mensaje número $i, con texto suficiente para ocupar '
            'varias líneas de la burbuja y así forzar overflow del '
            'viewport en la prueba.',
        createdAt: DateTime(2026, 8, 28, 12, i),
        status: AiMessageStatus.sent,
      ),
    );

    consentCubit = MockAiConsentCubit();
    chatCubit = MockAiChatCubit();
    when(() => consentCubit.start()).thenAnswer((_) async {});
    when(
      () => chatCubit.start(conversationId: any(named: 'conversationId')),
    ).thenAnswer((_) async {});
    whenListen(
      consentCubit,
      const Stream<AiConsentState>.empty(),
      initialState: const AiConsentState(status: AiConsentStatus.granted),
    );
    whenListen(
      chatCubit,
      const Stream<AiChatState>.empty(),
      initialState: AiChatState(
        status: AiChatStatus.ready,
        isSignedIn: true,
        conversationId: 'conv-1',
        messages: messages,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AiConsentCubit>.value(value: consentCubit),
            BlocProvider<AiChatCubit>.value(value: chatCubit),
          ],
          child: AiAssistantPage(
            onBack: () {},
            onOpenHistory: () async => null,
            onSignIn: () {},
            initialConversationId: 'conv-1',
          ),
        ),
      ),
    );
    // One `pump()` to build the first frame and let `_scrollToBottom`'s
    // `addPostFrameCallback` fire its `jumpTo`, then `pumpAndSettle()` — a
    // bare `pump()` with no duration doesn't advance the fake clock, so any
    // scroll physics still winding down after the jump (measured empirically:
    // `pixels` lands past `maxScrollExtent`, an unsettled overscroll, not a
    // production bug) never gets the chance to actually settle. Same
    // technique `month_picker_sheet_test.dart` uses after an action closes a
    // sheet.
    await tester.pump();
    await tester.pumpAndSettle();

    // `find.byType(Scrollable)` is ambiguous here: the composer's `TextField`
    // builds its own internal `Scrollable` for `EditableText`, so `.single`
    // throws "Too many elements". The messages `ListView` is the one and
    // only `ListView` in this tree — query it directly instead.
    final listView = tester.widget<ListView>(find.byType(ListView));
    final position = listView.controller!.position;
    expect(
      position.maxScrollExtent,
      greaterThan(0),
      reason: '30 mensajes largos deben desbordar el viewport de la prueba; '
          'si esto falla, la prueba no está probando nada.',
    );
    expect(position.pixels, position.maxScrollExtent);
  });
}
