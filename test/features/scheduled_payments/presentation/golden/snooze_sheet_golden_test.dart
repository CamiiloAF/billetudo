import 'package:billetudo/features/scheduled_payments/presentation/cubit/snooze_sheet_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/snooze_sheet_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/snooze_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockSnoozeSheetCubit extends MockCubit<SnoozeSheetState>
    implements SnoozeSheetCubit {}

/// HU-07's Posponer sheet: a single date picker with a floor of
/// `max(fecha original, hoy)` (criterion 10), reusing the app's own
/// `MonthCalendar`.
void main() {
  late MockSnoozeSheetCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockSnoozeSheetCubit());

  Future<void> golden(
    WidgetTester tester,
    SnoozeSheetState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) => BlocProvider<SnoozeSheetCubit>.value(
                value: cubit,
                child: SnoozeSheetBody(
                  templateTitle: 'Netflix',
                  occurrenceDate: _fixedDate,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_snooze_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('sin fecha seleccionada aún ($suffix)', (tester) async {
      await golden(
        tester,
        SnoozeSheetState(minDate: _fixedDate, selectedDate: _fixedDate),
        'default_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('con una fecha posterior elegida ($suffix)', (tester) async {
      await golden(
        tester,
        SnoozeSheetState(
          minDate: _fixedDate,
          selectedDate: _fixedDate.add(const Duration(days: 5)),
        ),
        'selected_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('guardando: botón deshabilitado ($suffix)', (tester) async {
      await golden(
        tester,
        SnoozeSheetState(
          minDate: _fixedDate,
          selectedDate: _fixedDate.add(const Duration(days: 5)),
          status: SnoozeSheetStatus.saving,
        ),
        'saving_$suffix',
        brightness: brightness,
      );
    });
  }
}

final DateTime _fixedDate = DateTime(2026, 7, 15);
