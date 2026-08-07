import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// A `PathProviderPlatform` that hands out a real temp directory, so cubits
/// that call `getTemporaryDirectory()` (export/save-copy) can run in a plain
/// `flutter_test` unit test without a platform channel.
class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}
