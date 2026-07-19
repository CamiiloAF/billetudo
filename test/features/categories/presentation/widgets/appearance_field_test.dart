import 'package:billetudo/features/categories/presentation/widgets/appearance_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pump_widget.dart';

/// The Pencil node for the row's lock icon (`N04bc`) is `enabled:false` in
/// every instance — root or subcategory — so `AppearanceField` must never
/// render `LucideIcons.lock`, unlike the icon/color picker sheet it opens,
/// which still shows one next to the "Color" section for a locked
/// subcategory.
void main() {
  testWidgets('nunca muestra el candado, sin importar el contexto',
      (tester) async {
    await tester.pumpAppWidget(
      AppearanceField(
        label: 'Icono y color',
        sublabel: 'Toca para elegir (opcional)',
        onTap: () {},
      ),
    );

    expect(find.byIcon(LucideIcons.lock), findsNothing);
  });
}
