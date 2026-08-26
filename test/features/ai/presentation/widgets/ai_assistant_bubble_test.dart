import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/ai/domain/entities/ai_message.dart';
import 'package:billetudo/features/ai/presentation/widgets/ai_assistant_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? clipboardText;

  setUp(() {
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardText = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  final message = AiMessage(
    id: 'msg-2',
    conversationId: 'conv-1',
    role: AiMessageRole.assistant,
    content: 'Vas bien este mes, gastaste el 40% de tu presupuesto.',
    createdAt: DateTime(2026, 8, 26),
    status: AiMessageStatus.sent,
  );

  Future<void> pumpBubble(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: AiAssistantBubble(
            message: message,
            accountNames: const {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // Guards that copying an assistant bubble only ever takes `message.content`
  // — proposals (if any) never leak into the clipboard through this menu.
  testWidgets('long-press abre el menú y "Copiar" copia solo el texto',
      (tester) async {
    await pumpBubble(tester);

    await tester.longPress(find.text(message.content));
    await tester.pumpAndSettle();

    expect(find.text('Copiar'), findsOneWidget);

    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();

    expect(clipboardText, message.content);
  });
}
