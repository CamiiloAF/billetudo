import 'dart:async';

import 'package:billetudo/features/capture/presentation/cubit/capture_background_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_state.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_degraded_card.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_degraded_empty_view.dart';
import 'package:billetudo/features/capture/presentation/widgets/sheets/capture_background_sheet.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../capture_mocks.dart';

/// The three surfaces of HU-09 in both themes: the degraded card (`VW54R` /
/// `DSCf0`), the degraded empty state (`krE9G` / `S0iyTP`) and the sheet
/// (`TPLPN` / `bN2YZ`), plus the fulfilled-battery row variant.
///
/// The clock is pinned because the footer prints "última captura: hoy,
/// 9:19 a. m."; without it the PNG would drift every day after it was
/// generated.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  CaptureBackgroundState sheetState({bool batteryExempt = false}) =>
      CaptureBackgroundState(
        isSupported: true,
        isLoading: false,
        showsAttention: true,
        permissionGranted: true,
        enabledCount: 1,
        diagnostics: buildCaptureDiagnostics(
          batteryOptimizationExempt: batteryExempt,
          manufacturer: 'Xiaomi',
          autostartAvailable: true,
          lastCaptureAtEpochMs:
              DateTime(2026, 8, 7, 9, 19).millisecondsSinceEpoch,
        ),
      );

  Future<void> sheetGolden(
    WidgetTester tester,
    CaptureBackgroundState state,
    String name, {
    required Brightness brightness,
  }) async {
    final cubit = MockCaptureBackgroundCubit();
    when(() => cubit.state).thenReturn(state);

    await withClock(Clock.fixed(goldenReferenceNow), () async {
      setGoldenViewport(tester);

      // Open the sheet through the shipped route (`CaptureBackgroundSheet.show`
      // -> `showModalBottomSheet`), so the golden includes the scrim, the
      // [28,28,0,0] radius and the drag handle the theme draws. The trigger is
      // scheduled after the first frame instead of being a visible button, so
      // the old harness "open" button no longer leaks into the PNG.
      late BuildContext harnessContext;
      await tester.pumpWidget(
        wrapForGolden(
          BlocProvider<CaptureBackgroundCubit>.value(
            value: cubit,
            child: Builder(
              builder: (BuildContext context) {
                harnessContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
          brightness: brightness,
        ),
      );
      await tester.pump();
      unawaited(CaptureBackgroundSheet.show(harnessContext));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/capture_background_sheet_$name.png'),
      );
    });
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('degraded card ($suffix)', (tester) async {
      await pumpWithFixedClock(
        tester,
        SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 350,
                child: CaptureDegradedCard(onReview: () {}, onSnooze: () {}),
              ),
            ),
          ),
        ),
        brightness: brightness,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/capture_background_card_$suffix.png'),
      );
    });

    testWidgets('degraded empty state ($suffix)', (tester) async {
      await pumpWithFixedClock(
        tester,
        CaptureDegradedEmptyView(onReview: () {}),
        brightness: brightness,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/capture_background_empty_$suffix.png'),
      );
    });

    testWidgets('background sheet, battery pending ($suffix)', (tester) async {
      await sheetGolden(
        tester,
        sheetState(),
        suffix,
        brightness: brightness,
      );
    });

    testWidgets('background sheet, battery fulfilled ($suffix)',
        (tester) async {
      await sheetGolden(
        tester,
        sheetState(batteryExempt: true),
        'battery_done_$suffix',
        brightness: brightness,
      );
    });
  }
}
