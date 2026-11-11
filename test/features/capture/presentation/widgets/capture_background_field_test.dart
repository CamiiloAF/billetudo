import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/core/widgets/settings_field.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_state.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_background_field.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

/// The permanent Ajustes row (HU-09, `rN8ye` / `lv0iQ`).
///
/// The behaviours that matter: iOS draws nothing, each state has its own
/// icon/sublabel (amber only on attention), a missing precondition routes to
/// setup instead of opening the sheet, and the three settled states open the
/// shared sheet.
void main() {
  late MockCaptureBackgroundCubit cubit;

  setUp(() {
    cubit = MockCaptureBackgroundCubit();
  });

  CaptureBackgroundState state({
    bool isSupported = true,
    bool isLoading = false,
    bool permissionGranted = true,
    int enabledCount = 1,
    bool degraded = false,
    bool showsAttention = false,
    DateTime? snoozedUntil,
    DateTime? lastCaptureAt,
  }) =>
      CaptureBackgroundState(
        isSupported: isSupported,
        isLoading: isLoading,
        permissionGranted: permissionGranted,
        enabledCount: enabledCount,
        degraded: degraded,
        showsAttention: showsAttention,
        snoozedUntil: snoozedUntil,
        diagnostics: buildCaptureDiagnostics(
          lastCaptureAtEpochMs: lastCaptureAt?.millisecondsSinceEpoch,
        ),
      );

  Future<void> pumpField(
    WidgetTester tester,
    CaptureBackgroundState snapshot, {
    ValueChanged<bool>? onOpenSetup,
  }) async {
    when(() => cubit.state).thenReturn(snapshot);
    await withClock(Clock.fixed(DateTime(2026, 8, 7, 12)), () async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<CaptureBackgroundCubit>.value(
              value: cubit,
              child: CaptureBackgroundField(
                onOpenSetup: onOpenSetup ?? (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  }

  BoxDecoration wrapDecoration(WidgetTester tester) {
    final Container container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SettingsField),
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  Icon rowIcon(WidgetTester tester) =>
      tester.widget<Icon>(find.byIcon(LucideIcons.shieldCheck));

  testWidgets('on iOS the row is not drawn at all', (tester) async {
    await pumpField(tester, state(isSupported: false));

    expect(find.byType(SettingsField), findsNothing);
    expect(find.text('Captura en segundo plano'), findsNothing);
  });

  testWidgets('loading: clock, muted wrap and the checking sublabel',
      (tester) async {
    await pumpField(tester, state(isLoading: true));

    expect(find.text('Captura en segundo plano'), findsOneWidget);
    expect(find.text('Revisando el estado…'), findsOneWidget);
    final Icon icon = tester.widget<Icon>(find.byIcon(LucideIcons.clock));
    expect(icon.color, AppColors.light.textSecondary);
    expect(wrapDecoration(tester).color, AppColors.light.muted);
  });

  testWidgets(
      'missing setup: bell-off, muted wrap and the "activate notices first" '
      'sublabel', (tester) async {
    await pumpField(tester, state(permissionGranted: false, enabledCount: 0));

    expect(find.text('Activa primero los avisos de tu banco'), findsOneWidget);
    final Icon icon = tester.widget<Icon>(find.byIcon(LucideIcons.bellOff));
    expect(icon.color, AppColors.light.textSecondary);
    expect(wrapDecoration(tester).color, AppColors.light.muted);
  });

  testWidgets('attention: shield-alert and the amber accent on icon and sub',
      (tester) async {
    await pumpField(
      tester,
      state(degraded: true, showsAttention: true),
    );

    expect(find.text('Revisá dos ajustes del sistema'), findsOneWidget);
    final Icon icon = tester.widget<Icon>(find.byIcon(LucideIcons.shieldAlert));
    expect(icon.color, AppColors.light.amberText);
    expect(wrapDecoration(tester).color, AppColors.light.amberSoft);
    final Text sublabel =
        tester.widget<Text>(find.text('Revisá dos ajustes del sistema'));
    expect(sublabel.style?.color, AppColors.light.amberText);
  });

  testWidgets('snoozed: clock, muted wrap and the 14-day sublabel',
      (tester) async {
    await pumpField(
      tester,
      state(
        degraded: true,
        snoozedUntil: DateTime(2026, 8, 21),
      ),
    );

    expect(find.text('Silenciada por 14 días'), findsOneWidget);
    final Icon icon = tester.widget<Icon>(find.byIcon(LucideIcons.clock));
    expect(icon.color, AppColors.light.textSecondary);
    expect(wrapDecoration(tester).color, AppColors.light.muted);
  });

  testWidgets('normal: shield-check and the relative last-capture day',
      (tester) async {
    await pumpField(
      tester,
      state(lastCaptureAt: DateTime(2026, 8, 7, 9, 19)),
    );

    expect(
      find.text('Activa · última captura hoy'),
      findsOneWidget,
    );
    expect(rowIcon(tester).color, AppColors.light.textSecondary);
    expect(wrapDecoration(tester).color, AppColors.light.muted);
  });

  testWidgets('normal without history: waiting for the first notice',
      (tester) async {
    await pumpField(tester, state());

    expect(find.text('Activa · esperando el primer aviso'), findsOneWidget);
  });

  testWidgets('missing setup taps into setup and never opens the sheet',
      (tester) async {
    final opened = <bool>[];
    await pumpField(
      tester,
      state(permissionGranted: false, enabledCount: 0),
      onOpenSetup: opened.add,
    );

    await tester.tap(find.text('Captura en segundo plano'));
    await tester.pumpAndSettle();

    expect(opened, <bool>[false]);
    expect(find.byType(BottomSheetBase), findsNothing);
  });

  testWidgets('missing issuers taps into the catalog, not the permission',
      (tester) async {
    final opened = <bool>[];
    await pumpField(
      tester,
      state(enabledCount: 0),
      onOpenSetup: opened.add,
    );

    await tester.tap(find.text('Captura en segundo plano'));
    await tester.pumpAndSettle();

    expect(opened, <bool>[true]);
    expect(find.byType(BottomSheetBase), findsNothing);
  });

  for (final (String name, CaptureBackgroundState snapshot)
      in <(String, CaptureBackgroundState)>[
    ('normal', state(lastCaptureAt: DateTime(2026, 8, 7, 9, 19))),
    ('attention', state(degraded: true, showsAttention: true)),
    ('snoozed', state(degraded: true, snoozedUntil: DateTime(2026, 8, 21))),
  ]) {
    testWidgets('$name opens the shared sheet', (tester) async {
      await pumpField(tester, snapshot);

      await tester.tap(find.text('Captura en segundo plano'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheetBase), findsOneWidget);
    });
  }
}
