import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('there are exactly 11 tutorials: 4 screen + 7 sub-flow', () {
    expect(TutorialKey.values, hasLength(11));
    expect(TutorialKey.screenTutorials, hasLength(4));
    expect(TutorialKey.subFlowTutorials, hasLength(7));
  });

  test('screen and sub-flow sets are disjoint and cover every key', () {
    final union = {
      ...TutorialKey.screenTutorials,
      ...TutorialKey.subFlowTutorials,
    };

    expect(union, TutorialKey.values.toSet());
    expect(
      TutorialKey.screenTutorials.intersection(TutorialKey.subFlowTutorials),
      isEmpty,
    );
  });

  test('every key has a unique, stable string id', () {
    final ids = TutorialKey.values.map((k) => k.id).toSet();

    expect(ids, hasLength(TutorialKey.values.length));
    for (final id in ids) {
      expect(id, startsWith('tutorial-'));
    }
  });

  test('isScreenTutorial matches the HU-01 screen set', () {
    expect(TutorialKey.budgetsScreen.isScreenTutorial, isTrue);
    expect(TutorialKey.debtLinkMovement.isScreenTutorial, isFalse);
  });
}
