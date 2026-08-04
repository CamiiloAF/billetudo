import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_form_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_form_state.dart';
import 'package:billetudo/features/goals/presentation/pages/goal_form_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockGoalFormCubit extends MockCubit<GoalFormState>
    implements GoalFormCubit {}

/// `GoalIconAndNameRow` (bug fix, design-system/billetudo/pages/metas.md):
/// the icon avatar must stay at the same vertical position whether or not
/// the name field shows its "campo requerido" error below it — the error is
/// rendered as a `Text` under the field's box, not as `InputDecoration`
/// growing the box itself, and the outer `Row` top-aligns both children so
/// the error's extra height never pushes the icon down.
void main() {
  late MockGoalFormCubit cubit;

  setUp(() {
    cubit = MockGoalFormCubit();
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<GoalFormState>.empty());
  });

  Future<double> pumpAndGetIconTop(
    WidgetTester tester,
    GoalFormState state,
  ) async {
    setGoldenViewport(tester, tallGoldenPhoneSize(height: 1400));
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<GoalFormCubit>.value(
          value: cubit,
          child: const GoalFormPage(),
        ),
      ),
    );
    await tester.pump();
    return tester.getTopLeft(find.byIcon(LucideIcons.pencil).first).dy;
  }

  testWidgets(
    'el ícono no se mueve verticalmente cuando aparece el error de nombre',
    (tester) async {
      final withoutError = await pumpAndGetIconTop(
        tester,
        const GoalFormState(status: GoalFormStatus.ready, targetMinor: 0),
      );

      final withError = await pumpAndGetIconTop(
        tester,
        const GoalFormState(
          status: GoalFormStatus.ready,
          targetMinor: 0,
          failedField: GoalDraft.fieldName,
        ),
      );

      expect(withError, withoutError);
    },
  );
}
