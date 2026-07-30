import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/cancellation_token.dart';
import '../../domain/entities/csv_vocabulary.dart';
import '../../domain/entities/export_scope.dart';
import '../../domain/entities/progress_callback.dart';
import '../../domain/repositories/export_repository.dart';
import '../datasources/csv_writer_datasource.dart';
import '../datasources/export_local_datasource.dart';
import '../datasources/zip_packager_datasource.dart';
import '../models/account_csv_mapper.dart';
import '../models/category_csv_mapper.dart';
import '../models/transaction_csv_mapper.dart';

/// Drift + `csv` implementation of [ExportRepository] (HU-01/HU-02).
@LazySingleton(as: ExportRepository)
class ExportRepositoryImpl implements ExportRepository {
  const ExportRepositoryImpl(this._local, this._writer, this._zip);

  final ExportLocalDatasource _local;
  final CsvWriterDatasource _writer;
  final ZipPackagerDatasource _zip;

  static const Map<CsvLanguage, CsvVocabulary> _vocabularies = {
    CsvLanguage.es: CsvVocabulary.es,
    CsvLanguage.en: CsvVocabulary.en,
  };

  @override
  FutureResult<int> exportTransactionsCsv({
    required String outputPath,
    required ExportScope scope,
    required CsvLanguage language,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final vocabulary = _vocabularies[language]!;
    final sinkResult = await _writer.open(outputPath);
    if (sinkResult case Left(value: final failure)) {
      return Left(failure);
    }
    final sink = (sinkResult as Right<Failure, CsvRowSink>).value;

    try {
      sink.writeRow(vocabulary.transactionHeaderRow);

      final total = await _local.countTransactions(
        filter: scope.transactionFilter,
        allHistory: scope.allHistory,
      );
      onProgress?.call(0, total);

      final accounts = await _local.getAllAccountsForExport();
      final categories = await _local.getAllCategoriesForExport();
      final accountNames = {for (final a in accounts) a.id: a.name};
      final categoryNames = {for (final c in categories) c.id: c.name};
      final categoryParentIds = {for (final c in categories) c.id: c.parentId};

      var written = 0;
      var offset = 0;
      while (true) {
        if (cancellationToken?.isCancelled ?? false) {
          throw const OperationCancelledException();
        }
        final page = await _local.getTransactionsPage(
          filter: scope.transactionFilter,
          allHistory: scope.allHistory,
          offset: offset,
        );
        if (page.isEmpty) {
          break;
        }
        final tagNames = await _local.getTagNamesByTransactionId(
          {for (final t in page) t.id},
        );
        final context = TransactionCsvContext(
          accountNames: accountNames,
          categoryNames: categoryNames,
          categoryParentIds: categoryParentIds,
          tagNamesByTransactionId: tagNames,
        );
        for (final row in page) {
          if (cancellationToken?.isCancelled ?? false) {
            throw const OperationCancelledException();
          }
          sink.writeRow(
            TransactionCsvMapper.toRow(row, context: context, vocabulary: vocabulary),
          );
          written++;
          onProgress?.call(written, total);
        }
        if (page.length < exportPageSize) {
          break;
        }
        offset += exportPageSize;
      }

      await sink.close();
      return Right(written);
    } on OperationCancelledException {
      await sink.abort();
      return const Left(
        IoFailure('export cancelled', reason: IoFailureReason.cancelled),
      );
    } catch (e, st) {
      await sink.abort();
      return Left(
        IoFailure('could not export transactions', cause: e, stackTrace: st),
      );
    }
  }

  @override
  FutureResult<int> exportAccountsCsv({
    required String outputPath,
    required CsvLanguage language,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final vocabulary = _vocabularies[language]!;
    final sinkResult = await _writer.open(outputPath);
    if (sinkResult case Left(value: final failure)) {
      return Left(failure);
    }
    final sink = (sinkResult as Right<Failure, CsvRowSink>).value;
    try {
      sink.writeRow(vocabulary.accountHeaderRow);
      final accounts = await _local.getAllAccountsForExport();
      onProgress?.call(0, accounts.length);
      var written = 0;
      for (final row in accounts) {
        if (cancellationToken?.isCancelled ?? false) {
          throw const OperationCancelledException();
        }
        sink.writeRow(AccountCsvMapper.toRow(row, vocabulary: vocabulary));
        written++;
        onProgress?.call(written, accounts.length);
      }
      await sink.close();
      return Right(accounts.length);
    } on OperationCancelledException {
      await sink.abort();
      return const Left(
        IoFailure('export cancelled', reason: IoFailureReason.cancelled),
      );
    } catch (e, st) {
      await sink.abort();
      return Left(IoFailure('could not export accounts', cause: e, stackTrace: st));
    }
  }

  @override
  FutureResult<int> exportCategoriesCsv({
    required String outputPath,
    required CsvLanguage language,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final vocabulary = _vocabularies[language]!;
    final sinkResult = await _writer.open(outputPath);
    if (sinkResult case Left(value: final failure)) {
      return Left(failure);
    }
    final sink = (sinkResult as Right<Failure, CsvRowSink>).value;
    try {
      sink.writeRow(vocabulary.categoryHeaderRow);
      final categories = await _local.getAllCategoriesForExport();
      onProgress?.call(0, categories.length);
      final namesById = {for (final c in categories) c.id: c.name};
      var written = 0;
      for (final row in categories) {
        if (cancellationToken?.isCancelled ?? false) {
          throw const OperationCancelledException();
        }
        sink.writeRow(
          CategoryCsvMapper.toRow(
            row,
            parentName: row.parentId == null ? null : namesById[row.parentId],
            vocabulary: vocabulary,
          ),
        );
        written++;
        onProgress?.call(written, categories.length);
      }
      await sink.close();
      return Right(categories.length);
    } on OperationCancelledException {
      await sink.abort();
      return const Left(
        IoFailure('export cancelled', reason: IoFailureReason.cancelled),
      );
    } catch (e, st) {
      await sink.abort();
      return Left(
        IoFailure('could not export categories', cause: e, stackTrace: st),
      );
    }
  }

  @override
  FutureResult<Unit> zipFiles({
    required String outputPath,
    required List<String> inputPaths,
  }) =>
      _zip.zipFiles(outputPath: outputPath, inputPaths: inputPaths);
}
