import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/issuer_rules.dart';
import '../repositories/issuer_rules_repository.dart';

/// Loads the bundled parsing catalog (`assets/capture/issuer_rules.json`).
@injectable
class LoadIssuerRules {
  const LoadIssuerRules(this._repository);

  final IssuerRulesRepository _repository;

  FutureResult<IssuerRuleSet> call() => _repository.load();
}
