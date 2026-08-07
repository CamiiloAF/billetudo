import 'package:billetudo/features/tutorials/domain/entities/tutorial_content.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hasNavigationCta is true only when ctaLabel is set (HU-01)', () {
    const withCta = TutorialContent(
      key: TutorialKey.budgetsScreen,
      title: 'Presupuestos',
      points: [TutorialPoint(heading: 'h', body: 'b')],
      iconName: 'wallet',
      ctaLabel: 'Crear mi primer presupuesto',
    );
    const withoutCta = TutorialContent(
      key: TutorialKey.debtLinkMovement,
      title: 'Enlazar movimiento',
      points: [TutorialPoint(heading: 'h', body: 'b')],
      iconName: 'link',
    );

    expect(withCta.hasNavigationCta, isTrue);
    expect(withoutCta.hasNavigationCta, isFalse);
  });

  test('equality is value-based (Equatable)', () {
    const a = TutorialContent(
      key: TutorialKey.goalsScreen,
      title: 'Metas',
      points: [TutorialPoint(heading: 'h', body: 'b')],
      iconName: 'flag',
    );
    const b = TutorialContent(
      key: TutorialKey.goalsScreen,
      title: 'Metas',
      points: [TutorialPoint(heading: 'h', body: 'b')],
      iconName: 'flag',
    );

    expect(a, b);
  });
}
