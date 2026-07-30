import 'package:billetudo/features/import_export/domain/entities/column_mapping.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_dialect.dart';
import 'package:billetudo/features/import_export/domain/entities/import_commit_plan.dart';
import 'package:billetudo/features/import_export/domain/repositories/import_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockImportRepository extends Mock implements ImportRepository {}

/// Registers the fallbacks mocktail needs for `any()` on custom types.
void registerImportRepositoryFallbacks() {
  registerFallbackValue(const ColumnMapping(columns: {}));
  registerFallbackValue(const CsvDialect());
  registerFallbackValue(
    const ImportCommitPlan(
      fileName: 'fallback.csv',
      rows: [],
      skippedDuplicateCount: 0,
      skippedErrorCount: 0,
    ),
  );
}
