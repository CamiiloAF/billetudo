import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/presentation/widgets/category_accordion_row.dart';
import 'package:billetudo/features/categories/presentation/widgets/category_subrow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/usecases/category_repository_mock.dart';
import 'pump_widget.dart';

void main() {
  final node = CategoryNode(
    root: buildCategory(id: 'root-1', name: 'Transporte'),
    subcategories: [
      buildCategory(id: 'sub-1', name: 'Taxi/App', parentId: 'root-1'),
      buildCategory(id: 'sub-2', name: 'Transporte público', parentId: 'root-1'),
    ],
  );

  testWidgets('colapsada: solo muestra el conteo, no las subcategorías', (
    tester,
  ) async {
    await tester.pumpAppWidget(
      CategoryAccordionRow(
        node: node,
        expanded: false,
        onToggle: () {},
        onAddSubcategory: () {},
      ),
    );

    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('2 subcategorías'), findsOneWidget);
    expect(find.byType(CategorySubrow), findsNothing);
  });

  testWidgets('expandida: muestra cada subcategoría y "Agregar subcategoría"', (
    tester,
  ) async {
    await tester.pumpAppWidget(
      CategoryAccordionRow(
        node: node,
        expanded: true,
        onToggle: () {},
        onAddSubcategory: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CategorySubrow), findsNWidgets(2));
    expect(find.text('Taxi/App'), findsOneWidget);
    expect(find.text('Transporte público'), findsOneWidget);
    expect(find.text('Agregar subcategoría'), findsOneWidget);
  });

  testWidgets('tocar la fila llama a onToggle', (tester) async {
    var toggled = false;
    await tester.pumpAppWidget(
      CategoryAccordionRow(
        node: node,
        expanded: false,
        onToggle: () => toggled = true,
        onAddSubcategory: () {},
      ),
    );

    await tester.tap(find.text('Transporte'));
    await tester.pump();

    expect(toggled, isTrue);
  });

  testWidgets('tocar "Agregar subcategoría" llama a onAddSubcategory', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpAppWidget(
      CategoryAccordionRow(
        node: node,
        expanded: true,
        onToggle: () {},
        onAddSubcategory: () => tapped = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar subcategoría'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('tocar una subcategoría llama a onTapSubcategory con su id', (
    tester,
  ) async {
    String? tappedId;
    await tester.pumpAppWidget(
      CategoryAccordionRow(
        node: node,
        expanded: true,
        onToggle: () {},
        onAddSubcategory: () {},
        onTapSubcategory: (id) => tappedId = id,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Taxi/App'));
    await tester.pump();

    expect(tappedId, 'sub-1');
  });
}
