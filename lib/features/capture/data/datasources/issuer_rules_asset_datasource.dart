import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:injectable/injectable.dart';

/// Reads `assets/capture/issuer_rules.json` from the app bundle.
///
/// The very same file is read by the Kotlin engine through
/// `flutter_assets/assets/capture/issuer_rules.json`, so this path must not
/// change without changing `IssuerRulesLoader.kt` too.
@lazySingleton
class IssuerRulesAssetDatasource {
  IssuerRulesAssetDatasource({AssetBundle? bundle}) : _bundle = bundle;

  static const String assetPath = 'assets/capture/issuer_rules.json';

  final AssetBundle? _bundle;

  Future<String> readRawJson() => (_bundle ?? rootBundle).loadString(assetPath);
}
