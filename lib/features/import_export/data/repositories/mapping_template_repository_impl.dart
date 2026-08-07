import 'package:injectable/injectable.dart';

import '../../../../core/crash/crash_reporter.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/mapping_template.dart';
import '../../domain/repositories/mapping_template_repository.dart';
import '../datasources/mapping_templates_local_datasource.dart';

/// `shared_preferences` implementation of [MappingTemplateRepository]. See
/// `MappingTemplatesLocalDatasource` for why this is not a Drift table.
@LazySingleton(as: MappingTemplateRepository)
class MappingTemplateRepositoryImpl implements MappingTemplateRepository {
  const MappingTemplateRepositoryImpl(this._local, this._crash);

  final MappingTemplatesLocalDatasource _local;
  final CrashReporter _crash;

  @override
  FutureResult<List<MappingTemplate>> getTemplates() => _guard(() async {
        final templates = await _local.getTemplates();
        return Right(templates);
      });

  @override
  FutureResult<Unit> saveTemplate(MappingTemplate template) => _guard(() async {
        await _local.saveTemplate(template);
        return const Right(unit);
      });

  @override
  FutureResult<Unit> deleteTemplate(String name) => _guard(() async {
        await _local.deleteTemplate(name);
        return const Right(unit);
      });

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      await _crash.recordError(e, st, context: 'mapping templates');
      return Left(
        DatabaseFailure('mapping templates storage failed', cause: e, stackTrace: st),
      );
    }
  }
}
