import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/transactions/presentation/cubit/tag_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/tag_filter_row.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/tag_filter_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../transaction_fixtures.dart';

class MockTagFilterCubit extends MockCubit<TagFilterState>
    implements TagFilterCubit {}

void main() {
  late MockTagFilterCubit cubit;

  final food = buildTag(name: 'comida');
  final travel = buildTag(id: 'tag-2');

  setUp(() {
    cubit = MockTagFilterCubit();
    when(() => cubit.state).thenReturn(
      TagFilterState(
        status: TagFilterStatus.ready,
        tags: [food, travel],
      ),
    );
    when(() => cubit.selectAll()).thenReturn(null);
    when(() => cubit.selectNone()).thenReturn(null);
    when(() => cubit.toggle(any())).thenReturn(null);
  });

  Widget appWith(String? title, String? confirmLabel) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<TagFilterCubit>.value(
            value: cubit,
            child: TagFilterSheetBody(
              title: title,
              confirmLabel: confirmLabel,
            ),
          ),
        ),
      );

  testWidgets('contexto de filtro (sin title): muestra Todas/Ninguna, no el +',
      (tester) async {
    await tester.pumpWidget(appWith(null, null));

    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Ninguna'), findsOneWidget);
    expect(find.byIcon(LucideIcons.plus), findsNothing);
    expect(find.text('Filtrar por etiqueta'), findsOneWidget);
    expect(find.text('Aplicar'), findsOneWidget);
  });

  testWidgets(
      'contexto de selección (con title): muestra el + en vez de '
      'Todas/Ninguna', (tester) async {
    await tester.pumpWidget(appWith('Etiquetas', 'Listo'));

    expect(find.text('Todas'), findsNothing);
    expect(find.text('Ninguna'), findsNothing);
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    expect(find.text('Etiquetas'), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);
  });

  testWidgets('muestra un buscador y filtra las filas por nombre',
      (tester) async {
    await tester.pumpWidget(appWith(null, null));

    expect(find.byType(TagFilterRow), findsNWidgets(2));
    expect(find.text('Buscar etiqueta'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'via');
    await tester.pump();

    expect(find.byType(TagFilterRow), findsOneWidget);
    expect(find.text('viaje'), findsOneWidget);
    expect(find.text('comida'), findsNothing);
  });

  testWidgets('tocar "Todas" llama a cubit.selectAll', (tester) async {
    await tester.pumpWidget(appWith(null, null));

    await tester.tap(find.text('Todas'));
    verify(() => cubit.selectAll()).called(1);
  });

  testWidgets('tocar "Ninguna" llama a cubit.selectNone', (tester) async {
    await tester.pumpWidget(appWith(null, null));

    await tester.tap(find.text('Ninguna'));
    verify(() => cubit.selectNone()).called(1);
  });

  testWidgets('tocar una fila llama a cubit.toggle con su id', (tester) async {
    await tester.pumpWidget(appWith(null, null));

    await tester.tap(find.text('comida'));
    verify(() => cubit.toggle('tag-1')).called(1);
  });

  testWidgets('cada fila usa el carácter "#" en vez de un ícono Lucide',
      (tester) async {
    await tester.pumpWidget(appWith(null, null));

    expect(find.text('#'), findsNWidgets(2));
  });
}
