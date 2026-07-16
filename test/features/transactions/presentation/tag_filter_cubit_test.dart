import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/presentation/cubit/tag_filter_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../transaction_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockWatchTags watchTags;
  late MockCreateTag createTag;

  final tag = buildTag();

  setUpAll(registerPresentationFallbacks);

  setUp(() {
    watchTags = MockWatchTags();
    createTag = MockCreateTag();
    when(() => watchTags()).thenAnswer((_) => Stream.value(Right([tag])));
  });

  TagFilterCubit build() => TagFilterCubit(watchTags, createTag);

  blocTest<TagFilterCubit, TagFilterState>(
    'carga las etiquetas y la selección inicial',
    build: build,
    act: (cubit) async {
      await cubit.start({'tag-1'});
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      expect(cubit.state.tags, [tag]);
      expect(cubit.state.selected, {'tag-1'});
    },
  );

  blocTest<TagFilterCubit, TagFilterState>(
    'crear una etiqueta al vuelo la deja seleccionada (HU-07)',
    setUp: () => when(() => createTag('nueva')).thenAnswer(
      (_) async => Right(buildTag(id: 'tag-2', name: 'nueva')),
    ),
    build: build,
    act: (cubit) async {
      await cubit.start(const {});
      await cubit.createTag('nueva');
    },
    verify: (cubit) => expect(cubit.state.selected, {'tag-2'}),
  );
}
