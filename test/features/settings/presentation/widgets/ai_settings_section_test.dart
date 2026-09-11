import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/usecases/resolve_legal_document.dart';
import 'package:billetudo/core/legal/presentation/pages/legal_document_viewer_page.dart';
import 'package:billetudo/features/ai/domain/entities/ai_consent.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:billetudo/features/settings/presentation/widgets/ai_settings_section.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../auth/presentation/widgets/pump_widget.dart';

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

class MockResolveLegalDocument extends Mock implements ResolveLegalDocument {}

void main() {
  late MockAppSettingsCubit cubit;

  const settingsOff = AppSettings(
    zeroBasedEnabled: false,
    categoriesSeeded: true,
    onboardingCompleted: true,
  );

  /// Consent granted against this build's copy — the only state in which
  /// Ajustes offers the withdrawal, and the only one in which the notes
  /// opt-in itself renders at all (bugfix: it used to stay visible and
  /// toggleable with consent withdrawn, an orphan permission for something
  /// already fully off — `ClearAiConsent`'s own doc warns against exactly
  /// this).
  final settingsConsented = AppSettings(
    zeroBasedEnabled: false,
    categoriesSeeded: true,
    onboardingCompleted: true,
    aiNotesAccessEnabled: true,
    aiConsentAcceptedAt: DateTime(2026, 8, 25),
    aiConsentVersion: currentAiConsentVersion,
  );

  /// Same consent, notes opt-in still off — the default starting point for
  /// the "interruptor de notas" tests below, which are about that switch's
  /// own behavior and need it visible to begin with.
  final settingsConsentedNotesOff = AppSettings(
    zeroBasedEnabled: false,
    categoriesSeeded: true,
    onboardingCompleted: true,
    aiConsentAcceptedAt: DateTime(2026, 8, 25),
    aiConsentVersion: currentAiConsentVersion,
  );

  void seed(AppSettings settings) {
    final state = AppSettingsState(settings: settings);
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<AppSettingsState>.empty(),
      initialState: state,
    );
  }

  setUpAll(() {
    registerFallbackValue(LegalDocumentKind.privacyPolicy);
  });

  setUp(() {
    cubit = MockAppSettingsCubit();
    when(() => cubit.setAiNotesAccessEnabled(enabled: any(named: 'enabled')))
        .thenAnswer((_) async {});
    when(cubit.clearAiConsent).thenAnswer((_) async {});
    seed(settingsOff);
  });

  Future<void> pumpSection(WidgetTester tester) => tester.pumpAuthWidget(
        BlocProvider<AppSettingsCubit>.value(
          value: cubit,
          child: const AiSettingsSection(),
        ),
      );

  testWidgets(
      'bugfix: sin consentimiento vigente, el interruptor de notas no se '
      'muestra en absoluto — reaparecer togglable tras retirar el '
      'consentimiento creaba exactamente el permiso huérfano que '
      'ClearAiConsent existe para evitar', (tester) async {
    seed(settingsOff);
    await pumpSection(tester);

    expect(find.byType(Switch), findsNothing);
  });

  group('interruptor de notas', () {
    // These tests are about the switch's own behavior, which only renders
    // with consent granted (bugfix above) — start every one of them there
    // instead of the outer `setUp`'s no-consent default.
    setUp(() => seed(settingsConsentedNotesOff));

    testWidgets(
        'apagado por defecto y el subtítulo aclara que la búsqueda sigue '
        'funcionando en el dispositivo', (tester) async {
      await pumpSection(tester);

      expect(
        tester.widget<Switch>(find.byType(Switch)).value,
        isFalse,
      );
      expect(
        find.textContaining('la búsqueda ocurre en tu dispositivo'),
        findsOneWidget,
      );
    });

    testWidgets('encenderlo pide confirmación antes de escribir nada',
        (tester) async {
      await pumpSection(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(
        find.text('¿Dejar que el asistente lea tus notas?'),
        findsOneWidget,
      );
      // Nombra al tercero explícitamente, antes y no después.
      expect(find.textContaining('Google Gemini'), findsOneWidget);
      verifyNever(
        () => cubit.setAiNotesAccessEnabled(enabled: any(named: 'enabled')),
      );
    });

    testWidgets('confirmar la hoja sí lo activa', (tester) async {
      await pumpSection(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activar'));
      await tester.pumpAndSettle();

      verify(() => cubit.setAiNotesAccessEnabled(enabled: true)).called(1);
    });

    testWidgets('cancelar la hoja lo deja apagado', (tester) async {
      await pumpSection(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(
        () => cubit.setAiNotesAccessEnabled(enabled: any(named: 'enabled')),
      );
    });

    testWidgets(
        'apagarlo NO pide confirmación: retirar un permiso es inmediato',
        (tester) async {
      seed(settingsConsented);
      await pumpSection(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      verify(() => cubit.setAiNotesAccessEnabled(enabled: false)).called(1);
      expect(
        find.text('¿Dejar que el asistente lea tus notas?'),
        findsNothing,
      );
    });
  });

  group('retirar el consentimiento (RGPD art. 7.3)', () {
    testWidgets(
        'no se ofrece cuando nunca se aceptó: no hay permiso que retirar',
        (tester) async {
      await pumpSection(tester);

      expect(find.text('Retirar el consentimiento de IA'), findsNothing);
    });

    testWidgets('se ofrece en cuanto el consentimiento está vigente',
        (tester) async {
      seed(settingsConsented);
      await pumpSection(tester);

      expect(find.text('Retirar el consentimiento de IA'), findsOneWidget);
      expect(
        find.textContaining('Puedes volver a activarlo cuando quieras.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'pide confirmación en una hoja (no un diálogo) antes de escribir nada, '
        'y dice qué pasa: el asistente deja de estar disponible y el '
        'interruptor de notas se apaga', (tester) async {
      seed(settingsConsented);
      await pumpSection(tester);

      await tester.tap(find.text('Retirar el consentimiento de IA'));
      await tester.pumpAndSettle();

      expect(find.text('¿Retirar el consentimiento?'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(
        find.textContaining('El asistente deja de estar disponible'),
        findsOneWidget,
      );
      expect(
        find.textContaining('«Dejar que el asistente lea mis notas»'),
        findsOneWidget,
      );
      verifyNever(cubit.clearAiConsent);
    });

    testWidgets('confirmar sí retira el consentimiento', (tester) async {
      seed(settingsConsented);
      await pumpSection(tester);

      await tester.tap(find.text('Retirar el consentimiento de IA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirar'));
      await tester.pumpAndSettle();

      verify(cubit.clearAiConsent).called(1);
    });

    testWidgets('cancelar no retira nada', (tester) async {
      seed(settingsConsented);
      await pumpSection(tester);

      await tester.tap(find.text('Retirar el consentimiento de IA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(cubit.clearAiConsent);
    });

    testWidgets(
        'el retiro pasa por su propio caso de uso, nunca apagando el '
        'interruptor de notas por separado desde la UI', (tester) async {
      seed(settingsConsented);
      await pumpSection(tester);

      await tester.tap(find.text('Retirar el consentimiento de IA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirar'));
      await tester.pumpAndSettle();

      verifyNever(
        () => cubit.setAiNotesAccessEnabled(enabled: any(named: 'enabled')),
      );
    });
  });

  group('enlaces legales', () {
    setUp(() {
      final resolveLegalDocument = MockResolveLegalDocument();
      when(() => resolveLegalDocument(kind: any(named: 'kind'))).thenAnswer(
        (invocation) async => Right(
          LegalDocument(
            kind: invocation.namedArguments[#kind] as LegalDocumentKind,
            content: '# Título\n\nCuerpo.',
            legalVersion: 1,
            effectiveDate: DateTime.utc(2026, 1, 1),
            source: LegalDocumentSource.bundle,
          ),
        ),
      );
      getIt.registerFactory<ResolveLegalDocument>(() => resolveLegalDocument);
    });

    tearDown(getIt.reset);

    testWidgets('la política de privacidad abre el visor nativo',
        (tester) async {
      await pumpSection(tester);

      await tester.tap(find.text('Política de privacidad'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalDocumentViewerPage), findsOneWidget);
    });

    testWidgets('los términos de uso abren el visor nativo', (tester) async {
      await pumpSection(tester);

      await tester.tap(find.text('Términos de uso'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalDocumentViewerPage), findsOneWidget);
    });
  });
}
