import 'package:billetudo/core/security/secure_clipboard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // `testWidgets` runs inside a fake clock, so the 60s timer can be advanced
  // without the test actually waiting a minute.
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureClipboard clipboard;
  String? clipboardText;

  setUp(() {
    clipboard = SecureClipboard();
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          clipboardText = (call.arguments as Map)['text'] as String?;
          return null;
        case 'Clipboard.getData':
          return <String, dynamic>{'text': clipboardText};
      }
      return null;
    });
  });

  tearDown(() {
    clipboard.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('copia el valor al portapapeles de inmediato', (tester) async {
    await clipboard.copySensitive('00123456784321');

    expect(clipboardText, '00123456784321');
    // El timer de limpieza queda vivo: se cancela dentro del test para que el
    // binding no lo reporte como pendiente.
    clipboard.dispose();
  });

  testWidgets('a los 60s se limpia solo (HU-03)', (tester) async {
    await clipboard.copySensitive('00123456784321');

    // Un segundo antes del cupo el número todavía está disponible para pegar.
    await tester.pump(const Duration(seconds: 59));
    expect(clipboardText, '00123456784321');

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(clipboardText, isEmpty);
  });

  testWidgets('no pisa lo que el usuario copió después', (tester) async {
    await clipboard.copySensitive('00123456784321');

    // El usuario copia otra cosa dentro de la ventana de 60s.
    await tester.pump(const Duration(seconds: 10));
    clipboardText = 'una lista de mercado';

    await tester.pump(const Duration(seconds: 51));
    await tester.pump();
    expect(clipboardText, 'una lista de mercado');
  });

  testWidgets('una copia nueva reinicia la ventana de limpieza',
      (tester) async {
    await clipboard.copySensitive('primero');
    await tester.pump(const Duration(seconds: 50));

    await clipboard.copySensitive('segundo');
    // Si el primer timer siguiera vivo, a los 10s borraría el segundo valor.
    await tester.pump(const Duration(seconds: 11));
    expect(clipboardText, 'segundo');

    await tester.pump(const Duration(seconds: 49));
    await tester.pump();
    expect(clipboardText, isEmpty);
  });

  testWidgets('dispose cancela la limpieza pendiente', (tester) async {
    await clipboard.copySensitive('00123456784321');
    clipboard.dispose();

    await tester.pump(const Duration(seconds: 61));
    expect(clipboardText, '00123456784321');
  });
}
