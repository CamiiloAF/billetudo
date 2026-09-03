import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_consent_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_consent_state.dart';
import 'package:billetudo/features/ai/presentation/pages/ai_consent_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiConsentCubit extends MockCubit<AiConsentState>
    implements AiConsentCubit {}

void main() {
  late MockAiConsentCubit consentCubit;

  setUp(() {
    consentCubit = MockAiConsentCubit();
    when(() => consentCubit.state).thenReturn(const AiConsentState());
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    bool hasHistory = false,
    VoidCallback? onOpenHistory,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: BlocProvider<AiConsentCubit>.value(
          value: consentCubit,
          child: AiConsentPage(
            onDecline: () {},
            hasHistory: hasHistory,
            onOpenHistory: onOpenHistory,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'sin conversaciones guardadas: no muestra el link a Ver historial',
    (tester) async {
      await pumpPage(tester);

      expect(
        find.text('Ver mis conversaciones anteriores'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'con al menos una conversación guardada: muestra el link a Ver '
    'historial y lo dispara al tocarlo',
    (tester) async {
      var tapped = false;
      await pumpPage(
        tester,
        hasHistory: true,
        onOpenHistory: () => tapped = true,
      );

      expect(find.text('Ver mis conversaciones anteriores'), findsOneWidget);

      await tester.tap(find.text('Ver mis conversaciones anteriores'));
      await tester.pump();

      expect(tapped, isTrue);
    },
  );

  testWidgets(
      'sigue mostrando aceptar y no, gracias sin importar el '
      'historial', (tester) async {
    await pumpPage(tester, hasHistory: true, onOpenHistory: () {});

    expect(find.text('Aceptar y continuar'), findsOneWidget);
    expect(find.text('No, gracias'), findsOneWidget);
  });
}
