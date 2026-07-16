import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../entities/category_draft.dart';
import '../repositories/category_repository.dart';

/// HU-01/HU-02: creates a root category or a subcategory.
///
/// A root category (`draft.parentId == null`) is created with whatever
/// `kind` the user picked. A subcategory always **inherits its parent's
/// kind** — any `kind` the UI passed for it is ignored — and the hierarchy is
/// capped at 2 levels: a subcategory cannot itself be a parent.
@injectable
class CreateCategory {
  const CreateCategory(this._repository);

  final CategoryRepository _repository;

  FutureResult<Category> call(CategoryDraft draft) async {
    final validated = draft.validated();
    if (validated case Left(value: final failure)) {
      return Left(failure);
    }
    final normalized = validated.getOrElse(
      (_) => throw StateError('unreachable: validated() returned Left'),
    );

    final parentId = normalized.parentId;
    if (parentId == null) {
      return _repository.createCategory(normalized);
    }

    final parentResult = await _repository.getCategory(parentId);
    return parentResult.fold(
      (failure) async => Left(_asParentFailure(failure)),
      (parent) {
        if (!parent.isRoot) {
          return Future.value(
            const Left(
              ValidationFailure(
                'a subcategory cannot have another subcategory as parent '
                '(max depth is 2 levels)',
                field: CategoryDraft.fieldParentId,
              ),
            ),
          );
        }
        return _repository.createCategory(
          CategoryDraft(
            id: normalized.id,
            name: normalized.name,
            kind: parent.kind,
            parentId: parentId,
            icon: normalized.icon,
            color: normalized.color,
          ),
        );
      },
    );
  }

  Failure _asParentFailure(Failure failure) => failure is NotFoundFailure
      ? const ValidationFailure(
          'parent category does not exist',
          field: CategoryDraft.fieldParentId,
        )
      : failure;
}
