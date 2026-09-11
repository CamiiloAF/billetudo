import 'package:injectable/injectable.dart';

import '../entities/legal_manifest.dart';

/// The two-condition gate that decides whether the re-acceptance sheet must
/// be shown on this launch (`docs/legal/entrega-de-documentos-legales.md`,
/// "`minAppVersion`: no lo quites"):
///
/// ```
/// versión_aceptada < versión_vigente   Y   versión_de_la_app >= minAppVersion
/// ```
///
/// **Both** conditions are required. Without the second one, someone who
/// has not updated their app would be asked to accept terms describing
/// functionality their installed version does not have.
@lazySingleton
class ShouldShowReacceptance {
  const ShouldShowReacceptance();

  bool call({
    required int acceptedVersion,
    required LegalManifest manifest,
    required String installedAppVersion,
  }) {
    final versionOutdated = acceptedVersion < manifest.currentVersion;
    if (!versionOutdated) {
      return false;
    }
    return _compareSemver(installedAppVersion, manifest.minAppVersion) >= 0;
  }

  /// Compares two `'x.y.z'` semver strings component-wise, treating a
  /// missing/non-numeric component as `0`. Returns <0, 0 or >0 like
  /// `Comparable.compareTo`.
  ///
  /// Deliberately not a full semver parser (no pre-release/build metadata):
  /// both the installed app version (`package_info_plus`) and
  /// `minAppVersion` in `legal.json` are always plain `MAJOR.MINOR.PATCH`.
  int _compareSemver(String a, String b) {
    final partsA = _parts(a);
    final partsB = _parts(b);
    final length =
        partsA.length > partsB.length ? partsA.length : partsB.length;
    for (var i = 0; i < length; i++) {
      final valueA = i < partsA.length ? partsA[i] : 0;
      final valueB = i < partsB.length ? partsB[i] : 0;
      final comparison = valueA.compareTo(valueB);
      if (comparison != 0) {
        return comparison;
      }
    }
    return 0;
  }

  List<int> _parts(String version) => version
      .split('.')
      .map((part) => int.tryParse(part.trim()) ?? 0)
      .toList(growable: false);
}
