import '../../../../core/error/result.dart';
import '../entities/mapping_template.dart';

/// HU-06: saved column mappings, keyed by name ("Mi banco", "Wallet"). Local
/// device storage, not a Drift table — the schema deliberately has none for
/// this (see `data/datasources/mapping_templates_local_datasource.dart` for
/// where it actually lives and why).
abstract class MappingTemplateRepository {
  FutureResult<List<MappingTemplate>> getTemplates();

  /// Upserts by [MappingTemplate.name] — saving again under the same name
  /// replaces it.
  FutureResult<Unit> saveTemplate(MappingTemplate template);

  FutureResult<Unit> deleteTemplate(String name);
}
