import 'package:billetudo/features/capture/presentation/cubit/capture_background_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_state.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_background_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../capture_mocks.dart';

/// The four settled states of the permanent Ajustes row in both themes
/// (`rN8ye` light / `lv0iQ` dark): normal, attention, missing setup and
/// snoozed. Loading is deliberately not captured — it is a transient beat,
/// and the checking copy is covered by the widget test.
///
/// The clock is pinned because the healthy sublabel prints a relative day
/// ("Activa · última captura hoy"); without it the PNG would drift as the
/// date moves.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  CaptureBackgroundState state({
    bool permissionGranted = true,
    int enabledCount = 1,
    bool degraded = false,
    bool showsAttention = false,
    DateTime? snoozedUntil,
    DateTime? lastCaptureAt,
  }) =>
      CaptureBackgroundState(
        isSupported: true,
        isLoading: false,
        permissionGranted: permissionGranted,
        enabledCount: enabledCount,
        degraded: degraded,
        showsAttention: showsAttention,
        snoozedUntil: snoozedUntil,
        diagnostics: buildCaptureDiagnostics(
          lastCaptureAtEpochMs: lastCaptureAt?.millisecondsSinceEpoch,
        ),
      );

  Future<void> golden(
    WidgetTester tester,
    CaptureBackgroundState snapshot,
    String name, {
    required Brightness brightness,
  }) async {
    final cubit = MockCaptureBackgroundCubit();
    when(() => cubit.state).thenReturn(snapshot);

    await pumpWithFixedClock(
      tester,
      BlocProvider<CaptureBackgroundCubit>.value(
        value: cubit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.topCenter,
            child: CaptureBackgroundField(onOpenSetup: (_) {}),
          ),
        ),
      ),
      brightness: brightness,
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        'goldens/capture_background_field_${name}_'
        '${brightness == Brightness.light ? 'light' : 'dark'}.png',
      ),
    );
  }

  final states = <(String, CaptureBackgroundState)>[
    ('normal', state(lastCaptureAt: DateTime(2026, 8, 7, 9, 19))),
    ('attention', state(degraded: true, showsAttention: true)),
    ('needs_setup', state(permissionGranted: false, enabledCount: 0)),
    ('snoozed', state(degraded: true, snoozedUntil: DateTime(2026, 8, 21))),
  ];

  for (final brightness in Brightness.values) {
    for (final (String name, CaptureBackgroundState snapshot) in states) {
      testWidgets('$name (${brightness.name})', (tester) async {
        await golden(tester, snapshot, name, brightness: brightness);
      });
    }
  }
}
