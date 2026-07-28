import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution_draft.dart';
import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:billetudo/features/goals/domain/repositories/goal_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

/// Registers the fallbacks mocktail needs for `any()` on custom types.
void registerGoalRepositoryFallbacks() {
  registerFallbackValue(
    const GoalDraft(name: 'fallback', targetMinor: 1, currency: 'COP'),
  );
  registerFallbackValue(GoalMovementDirection.contribution);
  registerFallbackValue(
    GoalContributionDraft(
      goalId: 'fallback',
      amountMinor: 1,
      direction: GoalMovementDirection.contribution,
      date: DateTime(2026),
      currency: 'COP',
    ),
  );
}
