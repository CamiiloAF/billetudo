import 'package:billetudo/features/capture/data/datasources/capture_shortcut_channel_datasource.dart';
import 'package:billetudo/features/capture/data/repositories/capture_shortcut_repository_impl.dart';
import 'package:billetudo/features/capture/domain/entities/capture_shortcut.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.billetudo.app/capture_shortcuts');
  late CaptureShortcutChannelDatasource datasource;
  late CaptureShortcutRepositoryImpl repository;
  String? initialShortcutId;

  setUp(() {
    initialShortcutId = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return call.method == 'getInitialShortcut' ? initialShortcutId : null;
    });
    datasource = CaptureShortcutChannelDatasource(channel);
    repository = CaptureShortcutRepositoryImpl(datasource);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads the shortcut the app was launched with', () async {
    initialShortcutId = 'income';

    final result = await repository.initialShortcut();

    expect(result.getRight().toNullable(), CaptureShortcut.income);
  });

  test('a normal launch reports no shortcut', () async {
    final result = await repository.initialShortcut();

    expect(result.getRight().toNullable(), isNull);
  });

  test('an unknown id is dropped instead of failing', () async {
    // Older app, newer widget: the app opens and nothing else happens.
    initialShortcutId = 'receipt_photo';

    final result = await repository.initialShortcut();

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable(), isNull);
  });

  test('shortcuts tapped while running arrive on the stream', () async {
    final received = repository.shortcuts().take(1).first;

    await TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        const MethodCall('onShortcut', 'expense'),
      ),
      (_) {},
    );

    expect(await received, CaptureShortcut.expense);
  });
}
