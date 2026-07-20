import 'package:billetudo/features/auth/presentation/widgets/sheets/delete_opt_in_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../pump_widget.dart';

/// Contrato del componente `Delete Opt-in Row` (`S533j9`, HU-06). Los dos
/// casos que importan son regresiones fáciles de introducir: mover el gesto al
/// checkbox de 24x24 (incumple el mínimo de 44px de MASTER) y dejar el estado
/// marcado solo en color (incumple WCAG 1.4.1).
void main() {
  Future<int> pumpRow(
    WidgetTester tester, {
    required bool selected,
    void Function()? onTap,
  }) async {
    var taps = 0;
    await tester.pumpAuthWidget(
      Center(
        child: DeleteOptInRow(
          title: 'Borrar también los datos de este teléfono',
          subtitle: 'Tu cuenta en la nube no se toca.',
          selected: selected,
          onTap: () {
            taps++;
            onTap?.call();
          },
        ),
      ),
    );
    return taps;
  }

  testWidgets(
      'un tap en el borde de la fila, lejos del checkbox, alterna el estado '
      '(el target es la fila entera, no la caja de 24x24)', (tester) async {
    var taps = 0;
    await pumpRow(tester, selected: false, onTap: () => taps++);

    final rowRect = tester.getRect(find.byType(DeleteOptInRow));
    final boxRect = tester.getRect(find.byType(DeleteOptInCheckbox));

    // Esquina inferior derecha de la fila, 4px hacia adentro: dentro del
    // InkWell y fuera del checkbox por construcción.
    final corner = rowRect.bottomRight - const Offset(4, 4);
    expect(
      boxRect.contains(corner),
      isFalse,
      reason: 'el punto elegido debe caer fuera del checkbox',
    );

    await tester.tapAt(corner);
    await tester.pump();

    expect(
      taps,
      1,
      reason: 'tocar el borde de la fila debe alternar el opt-in; si el gesto '
          'viviera en el checkbox, este tap no haría nada',
    );
  });

  testWidgets('la fila mide al menos 44px de alto (mínimo táctil de MASTER)',
      (tester) async {
    await pumpRow(tester, selected: false);

    final size = tester.getSize(find.byType(DeleteOptInRow));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets(
      'marcada muestra el glifo `check`, no solo color (WCAG 1.4.1)',
      (tester) async {
    await pumpRow(tester, selected: true);

    expect(
      find.descendant(
        of: find.byType(DeleteOptInCheckbox),
        matching: find.byIcon(LucideIcons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sin marcar no muestra el glifo `check`', (tester) async {
    await pumpRow(tester, selected: false);

    expect(find.byIcon(LucideIcons.check), findsNothing);
  });

  testWidgets('expone el estado marcado a accesibilidad (Semantics.checked)',
      (tester) async {
    await pumpRow(tester, selected: true);

    final checked = tester
        .getSemantics(find.byType(DeleteOptInRow))
        .flagsCollection
        .isChecked;
    expect(checked.name, 'isTrue');
  });

  testWidgets('sin marcar, accesibilidad reporta la casilla como no marcada',
      (tester) async {
    await pumpRow(tester, selected: false);

    final checked = tester
        .getSemantics(find.byType(DeleteOptInRow))
        .flagsCollection
        .isChecked;
    expect(checked.name, 'isFalse');
  });

  testWidgets('el checkbox no tiene gesto propio (el dueño es la fila)',
      (tester) async {
    await tester.pumpAuthWidget(
      const Center(child: DeleteOptInCheckbox(selected: false)),
    );

    expect(
      find.descendant(
        of: find.byType(DeleteOptInCheckbox),
        matching: find.byWidgetPredicate(
          (widget) => widget is InkWell || widget is GestureDetector,
        ),
      ),
      findsNothing,
    );
  });
}
