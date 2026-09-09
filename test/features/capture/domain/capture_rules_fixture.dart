import 'dart:io';

import 'package:billetudo/features/capture/domain/entities/issuer_rules.dart';

/// Loads the REAL asset from disk, not a fixture copy.
///
/// The rules are the single source of truth shared with the Kotlin engine; a
/// test that parsed its own copy would keep passing while production broke.
IssuerRuleSet loadRealRuleSet() => IssuerRuleSet.fromRawJson(
      File('assets/capture/issuer_rules.json').readAsStringSync(),
    );

/// Every catalogued issuer, so the parser is exercised with the same set the
/// user could realistically have switched on.
const Set<String> allIssuers = <String>{
  'nu',
  'nequi',
  'google_wallet',
};
