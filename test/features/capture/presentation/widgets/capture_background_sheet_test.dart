import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_state.dart';
import 'package:billetudo/features/capture/presentation/widgets/sheets/capture_background_sheet.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

/// `TPLPN` / `bN2YZ` — the background-capture sheet (HU-09).
///
/// The behaviours that matter: the battery row is always there, the autostart
/// row only where the manufacturer exposes one, a fulfilled row is not
/// navigable, "Listo, ya lo activé" closes only when the real diagnostics say
/// the exemption is granted, and only "Ahora no" snoozes.
void main() {
  late MockCaptureBackgroundCubit cubit;

  setUpAll(registerCaptureFallbacks);

  setUp(() {
    cubit = MockCaptureBackgroundCubit();
    when(() => cubit.state)
        .thenReturn(_state(batteryExempt: false, autostartAvailable: true));
    when(() => cubit.requestBatteryExemption()).thenAnswer((_) async {});
    when(() => cubit.openAutostart()).thenAnswer((_) async {});
    when(() => cubit.snooze()).thenAnswer((_) async {});
    when(() => cubit.confirmActivated()).thenAnswer((_) async => false);
  });

  Future<void> openSheet(
    WidgetTester tester, {
    required CaptureBackgroundState state,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await withClock(Clock.fixed(DateTime(2026, 8, 7, 12)), () async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<CaptureBackgroundCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => CaptureBackgroundSheet.show(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('always offers the battery setting, with its footer copy',
      (tester) async {
    await openSheet(tester, state: _state(autostartAvailable: false));

    expect(find.text('Captura en segundo plano'), findsOneWidget);
    expect(find.text('Permitir batería'), findsOneWidget);
    expect(find.text('Evita que el sistema lo duerma'), findsOneWidget);
    expect(find.textContaining('Última captura:'), findsOneWidget);
    expect(find.text('Listo, ya lo activé'), findsOneWidget);
    expect(find.text('Ahora no'), findsOneWidget);
  });

  testWidgets('the footer says nothing arrived yet when there is no history',
      (tester) async {
    await openSheet(
      tester,
      state: CaptureBackgroundState(
        isSupported: true,
        isLoading: false,
        showsAttention: true,
        permissionGranted: true,
        enabledCount: 1,
        diagnostics: buildCaptureDiagnostics(
          manufacturer: 'Xiaomi',
          autostartAvailable: false,
        ),
      ),
    );

    expect(
      find.text(
        'Todavía no recibimos ningún aviso. Si algo no llega, registralo a '
        'mano.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Última captura:'), findsNothing);
  });

  testWidgets('hides the autostart row where the manufacturer has no screen',
      (tester) async {
    await openSheet(tester, state: _state(autostartAvailable: false));

    expect(find.text('Abrir inicio automático'), findsNothing);
  });

  testWidgets('names the brand on an actionable autostart row', (tester) async {
    await openSheet(
      tester,
      state: _state(autostartAvailable: true, manufacturer: 'Xiaomi'),
    );

    expect(find.text('Abrir inicio automático'), findsOneWidget);
    expect(
      find.text('En Xiaomi, para que vuelva a escuchar'),
      findsOneWidget,
    );

    await tester.tap(find.text('Abrir inicio automático'));
    await tester.pump();

    verify(() => cubit.openAutostart()).called(1);
  });

  testWidgets('tapping the actionable battery row opens the system screen',
      (tester) async {
    await openSheet(tester, state: _state(autostartAvailable: false));

    await tester.tap(find.text('Permitir batería'));
    await tester.pump();

    verify(() => cubit.requestBatteryExemption()).called(1);
  });

  testWidgets('a fulfilled battery row is not navigable', (tester) async {
    await openSheet(
      tester,
      state: _state(batteryExempt: true, autostartAvailable: false),
    );

    expect(find.text('Permitido'), findsOneWidget);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);

    await tester.tap(find.text('Permitir batería'));
    await tester.pump();

    verifyNever(() => cubit.requestBatteryExemption());
  });

  testWidgets('a fulfilled battery row is mint, with the check as its state',
      (tester) async {
    await openSheet(
      tester,
      state: _state(batteryExempt: true, autostartAvailable: true),
    );

    final Icon check = tester.widget<Icon>(find.byIcon(LucideIcons.check));
    expect(check.color, AppColors.light.mint);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                AppColors.light.mintSoft,
      ),
      findsOneWidget,
    );
  });

  testWidgets('each row is one accessible label and the chevron is decorative',
      (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await openSheet(
      tester,
      state: _state(autostartAvailable: true, manufacturer: 'Xiaomi'),
    );

    final List<String> labels = tester.semantics
        .simulatedAccessibilityTraversal()
        .map((SemanticsNode node) => node.label)
        .where((String label) => label.isNotEmpty)
        .toList();

    // One node per row: title plus subtitle, and nothing else. If the visual
    // lines (or the arrow) were separate nodes, a screen reader would read the
    // row twice and announce a glyph that means nothing.
    expect(
      labels.where((String label) => label.contains('Permitir batería')),
      <String>['Permitir batería. Evita que el sistema lo duerma'],
    );
    expect(
      labels.where((String label) => label.contains('Abrir inicio automático')),
      <String>[
        'Abrir inicio automático. En Xiaomi, para que vuelva a escuchar'
      ],
    );
    expect(
      labels.where((String label) => label.contains('chevron')),
      isEmpty,
    );
    // Disposed inside the body: `flutter_test` verifies open handles before
    // `addTearDown` callbacks run.
    handle.dispose();
  });

  testWidgets('dragging the sheet down closes it without snoozing',
      (tester) async {
    await openSheet(tester, state: _state(autostartAvailable: false));

    await tester.drag(
      find.text('Captura en segundo plano'),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();

    expect(find.text('Captura en segundo plano'), findsNothing);
    verifyNever(() => cubit.snooze());
  });

  testWidgets('"Ahora no" snoozes and closes the sheet', (tester) async {
    await openSheet(tester, state: _state(autostartAvailable: false));

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    verify(() => cubit.snooze()).called(1);
    expect(find.text('Captura en segundo plano'), findsNothing);
  });

  testWidgets('closing by scrim never snoozes', (tester) async {
    await openSheet(tester, state: _state(autostartAvailable: false));

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Captura en segundo plano'), findsNothing);
    verifyNever(() => cubit.snooze());
  });

  testWidgets('"Listo" keeps the sheet open when the battery is not exempt',
      (tester) async {
    when(() => cubit.confirmActivated()).thenAnswer((_) async => false);
    await openSheet(tester, state: _state(autostartAvailable: false));

    await tester.tap(find.text('Listo, ya lo activé'));
    await tester.pumpAndSettle();

    expect(find.text('Captura en segundo plano'), findsOneWidget);
  });

  testWidgets('"Listo" closes only when the real diagnostics say it resolved',
      (tester) async {
    when(() => cubit.confirmActivated()).thenAnswer((_) async => true);
    await openSheet(tester, state: _state(autostartAvailable: false));

    await tester.tap(find.text('Listo, ya lo activé'));
    await tester.pumpAndSettle();

    expect(find.text('Captura en segundo plano'), findsNothing);
  });
}

/// A snapshot with attention on and every device fact set, so each test only
/// states the row it is about.
CaptureBackgroundState _state({
  bool batteryExempt = false,
  bool autostartAvailable = false,
  String manufacturer = 'Google',
}) =>
    CaptureBackgroundState(
      isSupported: true,
      isLoading: false,
      showsAttention: true,
      permissionGranted: true,
      enabledCount: 1,
      diagnostics: buildCaptureDiagnostics(
        batteryOptimizationExempt: batteryExempt,
        autostartAvailable: autostartAvailable,
        manufacturer: manufacturer,
        lastCaptureAtEpochMs:
            DateTime(2026, 8, 7, 9, 19).millisecondsSinceEpoch,
      ),
    );
