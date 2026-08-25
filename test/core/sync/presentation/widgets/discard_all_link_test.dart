import 'package:billetudo/core/sync/presentation/widgets/discard_all_link.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump_sync.dart';

/// El link "Descartar todo (N)" (`CXdn5`) que entra a la confirmación de
/// bulk desde la lista completa (`rxUil`).
void main() {
  testWidgets('muestra el conteo real en el propio label', (tester) async {
    await tester.pumpSyncWidget(
      DiscardAllLink(count: 89, onTap: () {}),
    );

    expect(find.text('Descartar todo (89)'), findsOneWidget);
  });

  testWidgets('un solo pendiente también se lee bien', (tester) async {
    await tester.pumpSyncWidget(
      DiscardAllLink(count: 1, onTap: () {}),
    );

    expect(find.text('Descartar todo (1)'), findsOneWidget);
  });

  testWidgets('tocar el link dispara el callback', (tester) async {
    var tapped = false;
    await tester.pumpSyncWidget(
      DiscardAllLink(count: 5, onTap: () => tapped = true),
    );

    await tester.tap(find.text('Descartar todo (5)'));

    expect(tapped, isTrue);
  });
}
