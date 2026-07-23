import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CategoryDraft draft({String name = 'Comida'}) =>
      CategoryDraft(name: name, kind: CategoryKind.expense);

  ValidationFailure? failureOf(CategoryDraft d) =>
      d.validated().fold((f) => f as ValidationFailure, (_) => null);

  group('CategoryDraft.validated name rules (HU-01, fix #15b)', () {
    test('an empty name fails as required, not as a length error', () {
      final failure = failureOf(draft(name: '   '));
      expect(failure, isNotNull);
      expect(failure!.field, CategoryDraft.fieldName);
      // The empty case must be the *first* rule, so presentation can map it to
      // the "required" copy — never the length one.
      expect(failure.message, contains('required'));
      expect(failure.message, isNot(contains('exceeds')));
    });

    test('a name over the limit fails as a length error', () {
      final failure = failureOf(draft(name: 'a' * (CategoryDraft.maxNameLength + 1)));
      expect(failure, isNotNull);
      expect(failure!.field, CategoryDraft.fieldName);
      expect(failure.message, contains('exceeds'));
    });

    test('a name exactly at the limit is valid', () {
      final result = draft(name: 'a' * CategoryDraft.maxNameLength).validated();
      expect(result.isRight(), isTrue);
    });

    test('a valid name is trimmed', () {
      final normalized =
          draft(name: '  Comida  ').validated().getRight().toNullable()!;
      expect(normalized.name, 'Comida');
    });
  });
}
