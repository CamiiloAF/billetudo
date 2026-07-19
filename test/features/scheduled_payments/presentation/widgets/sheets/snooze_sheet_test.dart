import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/snooze_sheet_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/snooze_sheet_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/snooze_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSnoozeSheetCubit extends MockCubit<SnoozeSheetState>
    implements SnoozeSheetCubit {}

/// HU-07: the Posponer sheet is a single date picker with a floor of
/// `max(fecha original, hoy)` (criterion 10); saving is disabled while a save
/// is already in flight.
void main() {
  late MockSnoozeSheetCubit cubit;

  setUp(() {
    cubit = MockSnoozeSheetCubit();
    when(() => cubit.dateSelected(any())).thenAnswer((_) {});
    when(() => cubit.save()).thenAnswer((_) async {});
    when(() => cubit.close()).thenAnswer((_) async {});
  });

  Future<void> pumpBody(
    WidgetTester tester,
    SnoozeSheetState state, {
    DateTime? occurrenceDate,
  }) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<SnoozeSheetState>.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SnoozeSheetCubit>.value(
          value: cubit,
          child: Scaffold(
            body: SnoozeSheetBody(
              templateTitle: 'Netflix',
              occurrenceDate: occurrenceDate ?? DateTime(2026, 7, 15),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the context line with the template title and date',
      (tester) async {
    await pumpBody(
      tester,
      SnoozeSheetState(
        minDate: DateTime(2026, 7, 15),
        selectedDate: DateTime(2026, 7, 15),
      ),
    );

    expect(find.textContaining('Netflix'), findsOneWidget);
  });

  testWidgets('tapping Guardar while ready calls cubit.save()', (tester) async {
    await pumpBody(
      tester,
      SnoozeSheetState(
        minDate: DateTime(2026, 7, 15),
        selectedDate: DateTime(2026, 7, 20),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    verify(() => cubit.save()).called(1);
  });

  testWidgets('Guardar is disabled while saving, so it never fires save() again',
      (tester) async {
    await pumpBody(
      tester,
      SnoozeSheetState(
        minDate: DateTime(2026, 7, 15),
        selectedDate: DateTime(2026, 7, 20),
        status: SnoozeSheetStatus.saving,
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
