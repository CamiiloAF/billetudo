import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/tag.dart';
import '../../domain/usecases/create_tag.dart';
import '../../domain/usecases/watch_tags.dart';

enum TagFilterStatus { loading, ready, failure }

/// HU-06/HU-07: the tag filter sheet's live tag list, pending selection, and
/// the "create on the fly" flow.
class TagFilterState extends Equatable {
  TagFilterState({
    this.status = TagFilterStatus.loading,
    this.tags = const <Tag>[],
    Set<String> selected = const <String>{},
    this.creating = false,
    this.failure,
  }) : selected = Set.unmodifiable(selected);

  final TagFilterStatus status;
  final List<Tag> tags;

  /// Empty means "no tag filter" (HU-06).
  final Set<String> selected;

  final bool creating;
  final Failure? failure;

  TagFilterState copyWith({
    TagFilterStatus? status,
    List<Tag>? tags,
    Set<String>? selected,
    bool? creating,
    Failure? failure,
  }) =>
      TagFilterState(
        status: status ?? this.status,
        tags: tags ?? this.tags,
        selected: selected ?? this.selected,
        creating: creating ?? this.creating,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, tags, selected, creating, failure];
}

/// Drives the tag filter sheet: multi-select over the live tag list plus
/// creating a new tag on the fly (HU-07), which is selected as soon as it is
/// created.
@injectable
class TagFilterCubit extends Cubit<TagFilterState> {
  TagFilterCubit(this._watchTags, this._createTag) : super(TagFilterState());

  final WatchTags _watchTags;
  final CreateTag _createTag;

  StreamSubscription<Result<List<Tag>>>? _subscription;

  Future<void> start(Set<String> initialSelected) async {
    await _subscription?.cancel();
    emit(TagFilterState(selected: initialSelected));
    _subscription = _watchTags().listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) =>
              state.copyWith(status: TagFilterStatus.failure, failure: failure),
          (tags) => state.copyWith(status: TagFilterStatus.ready, tags: tags),
        ),
      );
    });
  }

  void toggle(String tagId) {
    final next = Set<String>.of(state.selected);
    if (!next.remove(tagId)) {
      next.add(tagId);
    }
    emit(state.copyWith(selected: next));
  }

  /// HU-07: creates (or reuses) a tag by [name] and selects it right away.
  Future<void> createTag(String name) async {
    emit(state.copyWith(creating: true));
    final result = await _createTag(name);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(creating: false, failure: failure));
      case Right(value: final tag):
        emit(
          state.copyWith(
            creating: false,
            selected: {...state.selected, tag.id},
          ),
        );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
