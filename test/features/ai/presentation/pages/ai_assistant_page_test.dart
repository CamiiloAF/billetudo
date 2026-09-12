import 'dart:async';

import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_chat_state.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_consent_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_consent_state.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_history_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_history_state.dart';
import 'package:billetudo/features/ai/presentation/pages/ai_assistant_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiConsentCubit extends MockCubit<AiConsentState>
    implements AiConsentCubit {}

class MockAiChatCubit extends MockCubit<AiChatState> implements AiChatCubit {}

class MockAiHistoryCubit extends MockCubit<AiHistoryState>
    implements AiHistoryCubit {}

void main() {
  late MockAiConsentCubit consentCubit;
  late MockAiChatCubit chatCubit;
  late MockAiHistoryCubit historyCubit;

  setUpAll(() {
    registerFallbackValue(const AiConsentState());
    registerFallbackValue(const AiChatState());
    registerFallbackValue(const AiHistoryState());
  });

  setUp(() {
    consentCubit = MockAiConsentCubit();
    chatCubit = MockAiChatCubit();
    historyCubit = MockAiHistoryCubit();
    when(() => historyCubit.state).thenReturn(const AiHistoryState());
    when(() => consentCubit.start()).thenAnswer((_) async {});
    when(
      () => chatCubit.start(conversationId: any(named: 'conversationId')),
    ).thenAnswer((_) async {});
    when(
      () => chatCubit.startNew(insightType: any(named: 'insightType')),
    ).thenAnswer((_) async {});
    when(() => chatCubit.updateDraft(any())).thenReturn(null);
    when(() => chatCubit.send()).thenAnswer((_) async {});
    when(() => chatCubit.isClosed).thenReturn(false);
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
            BlocProvider<AiHistoryCubit>.value(value: historyCubit),
          ],
          child: AiAssistantPage(
            onBack: () {},
            onOpenHistory: () async => null,
            onOpenReadOnlyConversation: (_) {},
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
      'con initialQuestion: si `startNew` resuelve antes de que el stream de '
      'mensajes emita su primer estado (status sigue en `loading`, el valor '
      'por defecto de `AiChatState`), espera a que salga de `loading` antes '
      'de enviar — reportado en vivo como "abre el chat, pero no autoenvía '
      'el mensaje": `canSend` exige `status != loading`, así que `send()` '
      'era un no-op silencioso si se llamaba antes de esa transición',
      (tester) async {
    final stateController = StreamController<AiChatState>();
    addTearDown(stateController.close);
    whenListen(
      consentCubit,
      Stream.value(const AiConsentState(status: AiConsentStatus.granted)),
      initialState: const AiConsentState(),
    );
    whenListen(
      chatCubit,
      stateController.stream,
      initialState: const AiChatState(
        status: AiChatStatus.loading,
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
            BlocProvider<AiHistoryCubit>.value(value: historyCubit),
          ],
          child: AiAssistantPage(
            onBack: () {},
            onOpenHistory: () async => null,
            onOpenReadOnlyConversation: (_) {},
            onSignIn: () {},
            initialQuestion: '¿Cómo voy este mes?',
            initialInsightType: 'spendingVsAverage',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // `startNew` (mocked to resolve instantly) already ran, but the message
    // stream hasn't emitted anything yet — status is still `loading`. If
    // `_startWithQuestion` sent right here instead of waiting, this is where
    // the bug would show: nothing sent, nothing thrown.
    verifyNever(() => chatCubit.updateDraft(any()));
    verifyNever(() => chatCubit.send());

    // Now the conversation's message stream delivers its first value (an
    // empty brand-new thread) and status settles into `ready`.
    stateController.add(
      const AiChatState(status: AiChatStatus.ready, isSignedIn: true),
    );
    await tester.pump();
    await tester.pump();

    verify(() => chatCubit.updateDraft('¿Cómo voy este mes?')).called(1);
    verify(() => chatCubit.send()).called(1);
  });

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
            BlocProvider<AiHistoryCubit>.value(value: historyCubit),
          ],
          child: AiAssistantPage(
            onBack: () {},
            onOpenHistory: () async => null,
            onOpenReadOnlyConversation: (_) {},
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
    // `reverse: true` (billetudo.pen `ueaIi`: the thread anchors to the
    // bottom) puts the newest message at `minScrollExtent`, not
    // `maxScrollExtent` — reversing the list flips which end "the latest
    // message" sits at.
    expect(position.pixels, position.minScrollExtent);
  });

  testWidgets(
      'bugfix: reabrir por initialConversationId (el chip "continuar '
      'conversación" del insight) llega al fondo aunque la conversación '
      'nueva tenga la MISMA cantidad de mensajes que la que el cubit ya '
      'traía — reportado en vivo como "a veces se abre al inicio": '
      'listenWhen solo compara messages.length, así que la coincidencia de '
      'conteo hace que el listener nunca dispare; _startChatOnce ahora '
      'scrollea explícito al resolver start(), sin depender de esa '
      'comparación', (tester) async {
    AiMessage message(
      String id,
      String conversationId,
      int i, {
      required String content,
    }) =>
        AiMessage(
          id: id,
          conversationId: conversationId,
          role: i.isEven ? AiMessageRole.user : AiMessageRole.assistant,
          content: content,
          createdAt: DateTime(2026, 8, 28, 12, i),
          status: AiMessageStatus.sent,
        );

    // Same COUNT (30) as each other — the exact coincidence that defeats
    // `listenWhen`'s `previous.messages.length != current.messages.length`
    // guard — but deliberately DIFFERENT total heights: short one-line
    // messages for the old conversation, long multi-line ones for the new.
    // If a stale `_scrollToBottom()` result (jumped once, against the old
    // conversation's shorter content) is left standing instead of
    // re-running against the new conversation's real height, `pixels` stays
    // pinned at the old (smaller) `maxScrollExtent` instead of the new
    // (larger) one — exactly what the identical-length messages used before
    // this fix accidentally hid, since same-shaped content made both
    // extents equal by coincidence.
    final oldMessages = List.generate(
      30,
      (i) => message('old-$i', 'conv-old', i, content: 'Mensaje $i'),
    );
    final newMessages = List.generate(
      30,
      (i) => message(
        'new-$i',
        'conv-new',
        i,
        content: 'Mensaje número $i, con texto bastante más largo que el de '
            'la conversación anterior, suficiente para ocupar varias líneas '
            'de la burbuja y así forzar un alto total de contenido mucho '
            'mayor que el de la conversación vieja.',
      ),
    );

    consentCubit = MockAiConsentCubit();
    chatCubit = MockAiChatCubit();
    when(() => consentCubit.start()).thenAnswer((_) async {});

    final chatStateController = StreamController<AiChatState>.broadcast();
    addTearDown(chatStateController.close);
    var currentChatState = AiChatState(
      status: AiChatStatus.ready,
      isSignedIn: true,
      conversationId: 'conv-old',
      messages: oldMessages,
    );
    when(() => chatCubit.state).thenAnswer((_) => currentChatState);
    when(
      () => chatCubit.start(conversationId: 'conv-new'),
    ).thenAnswer((_) async {
      currentChatState = AiChatState(
        status: AiChatStatus.ready,
        isSignedIn: true,
        conversationId: 'conv-new',
        messages: newMessages,
      );
      chatStateController.add(currentChatState);
    });
    whenListen(
      consentCubit,
      const Stream<AiConsentState>.empty(),
      initialState: const AiConsentState(status: AiConsentStatus.granted),
    );
    whenListen(
      chatCubit,
      chatStateController.stream,
      initialState: currentChatState,
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
            BlocProvider<AiHistoryCubit>.value(value: historyCubit),
          ],
          child: AiAssistantPage(
            onBack: () {},
            onOpenHistory: () async => null,
            onOpenReadOnlyConversation: (_) {},
            onSignIn: () {},
            initialConversationId: 'conv-new',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    verify(() => chatCubit.start(conversationId: 'conv-new')).called(1);

    final listView = tester.widget<ListView>(find.byType(ListView));
    final position = listView.controller!.position;
    expect(
      position.maxScrollExtent,
      greaterThan(0),
      reason: '30 mensajes largos deben desbordar el viewport de la prueba; '
          'si esto falla, la prueba no está probando nada.',
    );
    // `reverse: true` (billetudo.pen `ueaIi`: the thread anchors to the
    // bottom) puts the newest message at `minScrollExtent`, not
    // `maxScrollExtent` — reversing the list flips which end "the latest
    // message" sits at.
    expect(position.pixels, position.minScrollExtent);
  });
}
