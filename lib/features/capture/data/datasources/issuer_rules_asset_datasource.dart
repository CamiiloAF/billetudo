import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:injectable/injectable.dart';

/// Reads `assets/capture/issuer_rules.json` from the app bundle.
///
/// The very same file is read by the Kotlin engine through
/// `flutter_assets/assets/capture/issuer_rules.json`, so this path must not
/// change without changing `IssuerRulesLoader.kt` too.
@lazySingleton
class IssuerRulesAssetDatasource {
  const IssuerRulesAssetDatasource() : _bundle = null;

  /// Injects a test bundle. The production constructor takes no arguments on
  /// purpose: `rootBundle` is not a container dependency.
  @visibleForTesting
  const IssuerRulesAssetDatasource.withBundle(AssetBundle bundle)
      : _bundle = bundle;

  static const String assetPath = 'assets/capture/issuer_rules.json';

  final AssetBundle? _bundle;

  Future<String> readRawJson() => (_bundle ?? rootBundle).loadString(assetPath);
}
