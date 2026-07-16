import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../datasources/tags_local_datasource.dart';
import '../models/tag_mapper.dart';

/// Drift implementation of [TagRepository]. Stamps `updatedAt` on every
/// write, same as the rest of the app.
@LazySingleton(as: TagRepository)
class TagRepositoryImpl implements TagRepository {
  const TagRepositoryImpl(this._local);

  final TagsLocalDatasource _local;

  @override
  Stream<Result<List<Tag>>> watchTags() => _guardStream(
        _local.watchTags().map(
              (rows) => Right(rows.map(TagMapper.toEntity).toList()),
            ),
      );

  @override
  FutureResult<Tag?> findTagByName(String name) => _guard(() async {
        final row = await _local.getTagByName(name);
        return Right(row == null ? null : TagMapper.toEntity(row));
      });

  @override
  FutureResult<Tag> createTag(String name) => _guard(() async {
        final now = DateTime.now();
        final row = await _local.insertTag(
          TagMapper.toInsertCompanion(name, now: now),
        );
        return Right(TagMapper.toEntity(row));
      });

  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      return Left(
          DatabaseFailure('tags query failed', cause: e, stackTrace: st));
    }
  }

  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) => sink.add(
            Left(
              DatabaseFailure(
                'tags stream failed',
                cause: error,
                stackTrace: stackTrace,
              ),
            ),
          ),
        ),
      );
}
