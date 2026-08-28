import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_chat_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_chat_state.dart';
import 'package:billetudo/features/ai/presentation/widgets/ai_empty_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiChatCubit extends MockCubit<AiChatState> implements AiChatCubit {}

void main() {
  late MockAiChatCubit cubit;

  setUp(() {
    cubit = MockAiChatCubit();
    when(() => cubit.state).thenReturn(
      const AiChatState(status: AiChatStatus.ready, isSignedIn: true),
    );
  });

  Future<void> pumpEmptyState(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: BlocProvider<AiChatCubit>.value(
          value: cubit,
          child: const Scaffold(body: AiEmptyState()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows title, subtitle and the 4 suggestion chips', (
    tester,
  ) async {
    await pumpEmptyState(tester);

    expect(find.text('¿Por dónde empezamos?'), findsOneWidget);
    expect(
      find.text('Elige una pregunta o escríbeme lo que necesites.'),
      findsOneWidget,
    );
    expect(find.text('¿Cómo voy este mes?'), findsOneWidget);
    expect(find.text('Ayudame a armar un presupuesto'), findsOneWidget);
    expect(find.text('¿Cuánto llevo ahorrado en mis metas?'), findsOneWidget);
    expect(find.text('¿En qué se me fue más la plata?'), findsOneWidget);
  });

  testWidgets('tapping a chip fills the draft and sends it right away', (
    tester,
  ) async {
    when(() => cubit.send()).thenAnswer((_) async {});
    await pumpEmptyState(tester);

    await tester.tap(find.text('¿Cómo voy este mes?'));
    await tester.pumpAndSettle();

    verify(() => cubit.updateDraft('¿Cómo voy este mes?')).called(1);
    verify(() => cubit.send()).called(1);
  });
}
