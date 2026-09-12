import '../../../../core/error/result.dart';
import '../entities/issuer_rules.dart';

/// Access to the parsing catalog. Implemented in `data/` over the bundled
/// asset `assets/capture/issuer_rules.json` — the same file the Kotlin engine
/// reads, and the only place rules may live (no network, no backend: the
/// capture path must work with the phone in airplane mode).
abstract class IssuerRulesRepository {
  /// Loads and parses the catalog. Implementations cache it: it is read on
  /// every app start and it never changes without a release.
  FutureResult<IssuerRuleSet> load();
}
