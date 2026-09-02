import 'dart:async';

import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_conversation_read_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_conversation_read_state.dart';
import 'package:billetudo/features/ai/presentation/pages/ai_conversation_read_page.dart';
import 'package:billetudo/features/ai/presentation/widgets/ai_composer.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../ai_fixtures.dart';

class MockAiConversationReadCubit extends MockCubit<AiConversationReadState>
    implements AiConversationReadCubit {}

void main() {
  late MockAiConversationReadCubit cubit;

  setUp(() {
    cubit = MockAiConversationReadCubit();
    when(() => cubit.start(any())).thenAnswer((_) async {});
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    VoidCallback? onReactivate,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: BlocProvider<AiConversationReadCubit>.value(
          value: cubit,
          child: AiConversationReadPage(
            conversationId: 'conv-1',
            onBack: () {},
            onReactivate: onReactivate ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders a saved conversation\'s bubbles with no composer at all — '
    'reading never opens a path to sending a new message',
    (tester) async {
      when(() => cubit.state).thenReturn(
        AiConversationReadState(
          status: AiConversationReadStatus.ready,
          messages: [
            buildAiMessage(
              id: 'm1',
              role: AiMessageRole.user,
              content: 'Hola',
            ),
            buildAiMessage(
              id: 'm2',
              role: AiMessageRole.assistant,
              content: 'Este mes gastaste menos en comida.',
            ),
          ],
        ),
      );

      await pumpPage(tester);
      await tester.pump();

      expect(find.text('Hola'), findsOneWidget);
      expect(
        find.text('Este mes gastaste menos en comida.'),
        findsOneWidget,
      );
      expect(find.byType(AiComposer), findsNothing);
      verify(() => cubit.start('conv-1')).called(1);
    },
  );

  testWidgets(
    'el banner de solo lectura dispara onReactivate al tocarlo',
    (tester) async {
      when(() => cubit.state).thenReturn(const AiConversationReadState());
      var tapped = false;

      await pumpPage(tester, onReactivate: () => tapped = true);
      await tester.pump();

      await tester.tap(find.text('Reactivar asistente'));
      await tester.pump();

      expect(tapped, isTrue);
    },
  );

  testWidgets(
      'bugfix: abrir una conversación pasada desde "Ver mis conversaciones '
      'anteriores" llega al fondo, no a la parte superior — esta pantalla '
      'nunca tuvo ScrollController, así que se quedaba "como una pantalla '
      'normal" (reportado en vivo)', (tester) async {
    final messages = List.generate(
      30,
      (i) => buildAiMessage(
        id: 'm$i',
        role: i.isEven ? AiMessageRole.user : AiMessageRole.assistant,
        content: 'Mensaje número $i, con texto suficiente para ocupar '
            'varias líneas de la burbuja y así forzar overflow del '
            'viewport en la prueba.',
      ),
    );

    final stateController = StreamController<AiConversationReadState>();
    addTearDown(stateController.close);
    when(() => cubit.state).thenReturn(const AiConversationReadState());
    whenListen(cubit, stateController.stream);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: BlocProvider<AiConversationReadCubit>.value(
          value: cubit,
          child: AiConversationReadPage(
            conversationId: 'conv-1',
            onBack: () {},
            onReactivate: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    // Only now does the cubit's fetch "resolve" — mirroring the real
    // `start()` reading messages asynchronously after the loading frame.
    stateController.add(
      AiConversationReadState(
        status: AiConversationReadStatus.ready,
        messages: messages,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

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
