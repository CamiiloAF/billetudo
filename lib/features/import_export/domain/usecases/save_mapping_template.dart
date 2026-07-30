import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/mapping_template.dart';
import '../repositories/mapping_template_repository.dart';

/// HU-06: "al confirmar, se ofrece guardar el mapeo con un nombre". Rejects a
/// blank name — an unnamed template cannot be recognized again later.
@injectable
class SaveMappingTemplate {
  const SaveMappingTemplate(this._repository);

  static const String nameField = 'name';

  final MappingTemplateRepository _repository;

  FutureResult<Unit> call(MappingTemplate template) {
    if (template.name.trim().isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('template name cannot be empty', field: nameField),
        ),
      );
    }
    return _repository.saveTemplate(template);
  }
}
