import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/issuer_rules.dart';
import '../../domain/repositories/issuer_rules_repository.dart';
import '../datasources/issuer_rules_asset_datasource.dart';

/// Loads the parsing catalog from the bundled asset and keeps it in memory:
/// the file cannot change without a new release, so re-reading it per
/// notification would be pure waste.
@LazySingleton(as: IssuerRulesRepository)
class IssuerRulesRepositoryImpl implements IssuerRulesRepository {
  IssuerRulesRepositoryImpl(this._datasource);

  final IssuerRulesAssetDatasource _datasource;

  IssuerRuleSet? _cached;

  @override
  FutureResult<IssuerRuleSet> load() async {
    final IssuerRuleSet? cached = _cached;
    if (cached != null) {
      return Right(cached);
    }
    try {
      final String raw = await _datasource.readRawJson();
      final IssuerRuleSet ruleSet = IssuerRuleSet.fromRawJson(raw);
      _cached = ruleSet;
      return Right(ruleSet);
    } catch (e, st) {
      // A malformed catalog disables capture; it must never crash the app.
      return Left(
        IoFailure(
          'failed to read the issuer rules asset',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
