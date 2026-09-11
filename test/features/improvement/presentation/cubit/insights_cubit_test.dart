import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/improvement/domain/entities/insight.dart';
import 'package:billetudo/features/improvement/domain/usecases/watch_insights.dart';
import 'package:billetudo/features/improvement/presentation/cubit/insights_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchInsights extends Mock implements WatchInsights {}

Insight buildInsight({
  required String id,
  InsightType type = InsightType.upcomingCharge,
  String subject = 'Netflix',
}) =>
    Insight(
      id: id,
      type: type,
      subject: subject,
      relevantOn: DateTime(2026, 9, 12),
      targetId: 'template-1',
      amountMinor: 4490000,
      currency: 'COP',
      daysUntil: 3,
    );

void main() {
  late MockWatchInsights watchInsights;
  late StreamController<Result<List<Insight>>> controller;

  setUp(() {
    watchInsights = MockWatchInsights();
    controller = StreamController<Result<List<Insight>>>.broadcast();
    when(watchInsights.call).thenAnswer((_) => controller.stream);
  });

  tearDown(() async => controller.close());

  test('publica lo que emite WatchInsights, sin reordenar', () async {
    final cubit = InsightsCubit(watchInsights);
    await cubit.start();

    final insights = [
      buildInsight(id: 'a'),
      buildInsight(id: 'b', type: InsightType.goalMilestone),
    ];
    controller.add(Right(insights));
    await Future<void>.delayed(Duration.zero);

    // El orden por utilidad ya lo decide el caso de uso; el cubit no opina.
    expect(cubit.state.insights.map((i) => i.id), ['a', 'b']);
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.failed, isFalse);

    await cubit.close();
  });

  test('"Recordar después" esconde solo esa tarjeta', () async {
    final cubit = InsightsCubit(watchInsights);
    await cubit.start();

    final a = buildInsight(id: 'a');
    final b = buildInsight(id: 'b');
    controller.add(Right([a, b]));
    await Future<void>.delayed(Duration.zero);

    cubit.dismiss(a);

    expect(cubit.state.insights.map((i) => i.id), ['b']);

    await cubit.close();
  });

  test('lo pospuesto sigue oculto cuando la fuente vuelve a emitir', () async {
    final cubit = InsightsCubit(watchInsights);
    await cubit.start();

    final a = buildInsight(id: 'a');
    controller.add(Right([a]));
    await Future<void>.delayed(Duration.zero);
    cubit.dismiss(a);

    // Misma razón, mismo id: no puede reaparecer dentro de la sesión.
    controller.add(Right([a]));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.insights, isEmpty);

    await cubit.close();
  });

  test('un fallo deja la sección vacía en vez de romper la pantalla',
      () async {
    final cubit = InsightsCubit(watchInsights);
    await cubit.start();

    controller.add(const Left(UnexpectedFailure('nope')));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.failed, isTrue);
    expect(cubit.state.insights, isEmpty);
    expect(cubit.state.loading, isFalse);

    await cubit.close();
  });
}
