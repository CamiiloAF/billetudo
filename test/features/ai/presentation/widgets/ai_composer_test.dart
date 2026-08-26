import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_chat_state.dart';
import 'package:billetudo/features/ai/presentation/widgets/ai_composer.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAiChatCubit extends MockCubit<AiChatState> implements AiChatCubit {}

void main() {
  late MockAiChatCubit cubit;

  setUp(() {
    cubit = MockAiChatCubit();
  });

  Future<void> pumpComposer(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: BlocProvider<AiChatCubit>.value(
          value: cubit,
          child: const Scaffold(body: AiComposer()),
        ),
      ),
    );
    await tester.pump();
  }

  // Guards the fix behind this test: a suggestion chip fills
  // `AiChatState.draft` from outside the composer's own `TextField`, and the
  // field must reflect it — otherwise tapping a chip would look like nothing
  // happened.
  testWidgets('fills the text field when the draft changes externally', (
    tester,
  ) async {
    const initial = AiChatState(
      status: AiChatStatus.ready,
      isSignedIn: true,
    );
    const withDraft = AiChatState(
      status: AiChatStatus.ready,
      isSignedIn: true,
      draft: '¿Cómo voy este mes?',
    );
    whenListen(cubit, Stream.value(withDraft), initialState: initial);

    await pumpComposer(tester);
    await tester.pump();

    expect(find.text('¿Cómo voy este mes?'), findsOneWidget);
  });

  // Guards the WhatsApp-style multiline fix: the field must accept and keep
  // text spanning several lines instead of being forced to a single line
  // (the old `Container(height: 44)` + implicit `maxLines: 1` behaviour).
  testWidgets('accepts multiline text without collapsing it', (
    tester,
  ) async {
    const initial = AiChatState(status: AiChatStatus.ready, isSignedIn: true);
    whenListen(cubit, const Stream<AiChatState>.empty(), initialState: initial);

    await pumpComposer(tester);

    const multilineText = 'Línea uno\nLínea dos\nLínea tres';
    await tester.enterText(find.byType(TextField), multilineText);
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, multilineText);
    expect(textField.maxLines, greaterThan(1));
    expect(textField.minLines, 1);
    expect(textField.keyboardType, TextInputType.multiline);
  });
}
