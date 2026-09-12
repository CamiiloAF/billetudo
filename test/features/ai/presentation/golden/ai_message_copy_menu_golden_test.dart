import 'package:billetudo/features/ai/presentation/widgets/ai_message_copy_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The long-press menu a message bubble opens (`billetudo.pen`
/// `Cbssw`/`PpcIh`): "Copiar" alone for a user's own message, "Copiar" +
/// "Reportar" divided for an assistant message.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required VoidCallback? onReport,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Center(
          child: AiMessageCopyMenu(
            textToCopy: 'Este mes gastaste 320.000 en Comida.',
            onReport: onReport,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text('Este mes gastaste 320.000 en Comida.'),
            ),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.longPress(find.byType(Container));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ai_message_copy_menu_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('assistant message: Copiar + Reportar divided ($suffix)',
        (tester) async {
      await golden(
        tester,
        'assistant_$suffix',
        brightness: brightness,
        onReport: () {},
      );
    });

    testWidgets('user message: Copiar only, no divider ($suffix)',
        (tester) async {
      await golden(
        tester,
        'user_$suffix',
        brightness: brightness,
        onReport: null,
      );
    });
  }
}
