import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/mapping_template.dart';
import '../repositories/mapping_template_repository.dart';

/// HU-06: every saved mapping template, for `AutodetectColumnMapping` and for
/// the mapping step's "usar una plantilla guardada" picker.
@injectable
class GetMappingTemplates {
  const GetMappingTemplates(this._repository);

  final MappingTemplateRepository _repository;

  FutureResult<List<MappingTemplate>> call() => _repository.getTemplates();
}
