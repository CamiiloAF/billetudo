import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/cancellation_token.dart';
import '../entities/csv_vocabulary.dart';
import '../entities/progress_callback.dart';
import '../repositories/export_repository.dart';

/// Row counts from [ExportAccountsCategoriesCsv]; a `null` field means that
/// kind was not part of this call.
typedef AccountsCategoriesExportResult = ({int? accountRows, int? categoryRows});

/// HU-02: writes whichever of the accounts/categories CSVs the caller asks
/// for (each optional, so a caller wanting only categories does not pay for
/// an accounts query it will not use). Bundling the result files into a
/// `.zip` alongside a transactions export, when more than one kind is
/// selected, is `ExportRepository.zipFiles` — orchestrated by whoever calls
/// this (the export flow needs to know about a transactions file this use
/// case never touches).
@injectable
class ExportAccountsCategoriesCsv {
  const ExportAccountsCategoriesCsv(this._repository);

  final ExportRepository _repository;

  /// [onProgress], when set, is called once per file with counts scoped to
  /// *that* file (it restarts at `0` for categories once accounts finish) —
  /// the caller (a cubit tracking a combined total across both files) adds
  /// its own running offset.
  FutureResult<AccountsCategoriesExportResult> call({
    String? accountsOutputPath,
    String? categoriesOutputPath,
    required CsvLanguage language,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    int? accountRows;
    if (accountsOutputPath != null) {
      final result = await _repository.exportAccountsCsv(
        outputPath: accountsOutputPath,
        language: language,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );
      switch (result) {
        case Left(value: final failure):
          return Left(failure);
        case Right(value: final rows):
          accountRows = rows;
      }
    }

    int? categoryRows;
    if (categoriesOutputPath != null) {
      final result = await _repository.exportCategoriesCsv(
        outputPath: categoriesOutputPath,
        language: language,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );
      switch (result) {
        case Left(value: final failure):
          return Left(failure);
        case Right(value: final rows):
          categoryRows = rows;
      }
    }

    return Right((accountRows: accountRows, categoryRows: categoryRows));
  }
}
