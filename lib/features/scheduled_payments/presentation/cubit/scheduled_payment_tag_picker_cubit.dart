import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/tag.dart';
import '../../domain/usecases/create_tag.dart';
import '../../domain/usecases/get_tags.dart';

enum ScheduledPaymentTagPickerStatus { loading, ready, failure }

/// The template form's Etiquetas field's live tag list, pending selection and
/// the "create on the fly" flow.
///
/// Not in the original file plan, but indispensable: `CLAUDE.md` requires
/// state to live only in bloc/cubit, and `ScheduledPaymentTagsField`
/// (criterion 2) needs somewhere to hold the live tag list and the selection
/// while the picker sheet is open — same precedent as
/// `transactions/presentation/cubit/tag_filter_cubit.dart`, mirrored here for
/// this feature's own `Tag` entity.
class ScheduledPaymentTagPickerState extends Equatable {
  ScheduledPaymentTagPickerState({
    this.status = ScheduledPaymentTagPickerStatus.loading,
    this.tags = const <Tag>[],
    Set<String> selected = const <String>{},
    this.creating = false,
    this.failure,
  }) : selected = Set.unmodifiable(selected);

  final ScheduledPaymentTagPickerStatus status;
  final List<Tag> tags;
  final Set<String> selected;
  final bool creating;
  final Failure? failure;

  ScheduledPaymentTagPickerState copyWith({
    ScheduledPaymentTagPickerStatus? status,
    List<Tag>? tags,
    Set<String>? selected,
    bool? creating,
    Failure? failure,
  }) =>
      ScheduledPaymentTagPickerState(
        status: status ?? this.status,
        tags: tags ?? this.tags,
        selected: selected ?? this.selected,
        creating: creating ?? this.creating,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, tags, selected, creating, failure];
}

@injectable
class ScheduledPaymentTagPickerCubit
    extends Cubit<ScheduledPaymentTagPickerState> {
  ScheduledPaymentTagPickerCubit(this._getTags, this._createTag)
      : super(ScheduledPaymentTagPickerState());

  final GetTags _getTags;
  final CreateTag _createTag;

  StreamSubscription<Result<List<Tag>>>? _subscription;

  Future<void> start(Set<String> initialSelected) async {
    await _subscription?.cancel();
    emit(ScheduledPaymentTagPickerState(selected: initialSelected));
    _subscription = _getTags().listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: ScheduledPaymentTagPickerStatus.failure,
            failure: failure,
          ),
          (tags) => state.copyWith(
            status: ScheduledPaymentTagPickerStatus.ready,
            tags: tags,
          ),
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
