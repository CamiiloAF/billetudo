import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/ai/domain/entities/ai_report.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_report_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_report_state.dart';
import 'package:billetudo/features/ai/presentation/widgets/sheets/ai_report_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockAiReportCubit extends MockCubit<AiReportState>
    implements AiReportCubit {}

/// The "Reportar mensaje" sheet (`zV9g3`/`G6uAwV`): reason grid, comment and
/// privacy note always visible together; "Enviar" only lights up once a
/// motive is picked. Uses a mocked `AiReportCubit` (same shape as the sheet's
/// own widget test) shown through the app's real bottom-sheet chrome.
void main() {
  late MockAiReportCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
    registerFallbackValue(AiReportReason.other);
  });

  setUp(() {
    cubit = MockAiReportCubit();
    when(() => cubit.reasonSelected(any())).thenReturn(null);
    when(() => cubit.commentChanged(any())).thenReturn(null);
    when(() => cubit.close()).thenAnswer((_) async {});
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required AiReportState state,
  }) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<AiReportState>.empty());

    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BottomSheetBase.show<void>(
              context,
              builder: (_) => BlocProvider<AiReportCubit>.value(
                value: cubit,
                child: const AiReportSheetBody(
                  reportedText: 'Este mes gastaste 320.000 en Comida.',
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
      matchesGoldenFile('goldens/ai_report_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('no reason selected: Enviar disabled ($suffix)',
        (tester) async {
      await golden(
        tester,
        'no_reason_$suffix',
        brightness: brightness,
        state: const AiReportState(),
      );
    });

    testWidgets('reason selected: Enviar enabled ($suffix)', (tester) async {
      await golden(
        tester,
        'reason_selected_$suffix',
        brightness: brightness,
        state: const AiReportState(reason: AiReportReason.wrong),
      );
    });
  }
}
