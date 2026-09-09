import 'package:billetudo/features/capture/domain/entities/issuer_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'capture_rules_fixture.dart';

/// Integrity of the catalog itself. These checks guard the shared file that
/// the Kotlin engine also reads: a malformed rule there fails silently in
/// production (nothing is captured, nothing is logged).
void main() {
  final IssuerRuleSet ruleSet = loadRealRuleSet();

  test('the launch catalog is exactly the three issuers in use', () {
    expect(
      ruleSet.issuers.map((IssuerDefinition i) => i.issuerId).toSet(),
      allIssuers,
    );
  });

  test('package names are the ones confirmed on a real device', () {
    // Compared EXACTLY by the native filter. A typo here captures nothing and
    // raises no error, so it is pinned by a test instead.
    expect(ruleSet.issuerById('nequi')?.packageName, 'com.nequi.MobileApp');
    expect(ruleSet.issuerById('nu')?.packageName, 'com.nu.production');
    expect(ruleSet.issuerById('google_wallet')?.packageName,
        'com.google.android.apps.walletnfcrel');
  });

  test('every package resolves to one and only one issuer', () {
    final List<String> packages = <String>[
      for (final IssuerDefinition issuer in ruleSet.issuers)
        ...issuer.allPackageNames,
    ];
    expect(packages.toSet().length, packages.length);
  });

  test('rule ids are unique across the whole catalog', () {
    final List<String> ids = <String>[
      for (final IssuerRule rule in ruleSet.globalIgnoreRules) rule.ruleId,
      for (final IssuerDefinition issuer in ruleSet.issuers)
        for (final IssuerRule rule in issuer.rules) rule.ruleId,
    ];
    expect(ids.toSet().length, ids.length);
  });

  test('every capture rule declares an amount group and an entry type', () {
    for (final IssuerDefinition issuer in ruleSet.issuers) {
      for (final IssuerRule rule in issuer.rules) {
        if (rule.action != RuleAction.capture) {
          continue;
        }
        expect(rule.captures['amount'], isNotNull,
            reason: '${rule.ruleId} has no amount group');
        expect(rule.entryType, isNotNull,
            reason: '${rule.ruleId} has no entry type');
      }
    }
  });

  test('every regex compiles', () {
    for (final IssuerRule rule in <IssuerRule>[
      ...ruleSet.globalIgnoreRules,
      for (final IssuerDefinition issuer in ruleSet.issuers) ...issuer.rules,
    ]) {
      expect(rule.compile, returnsNormally, reason: rule.ruleId);
    }
  });

  test('ignore rules outrank capture rules', () {
    // An OTP that happens to carry a figure must lose to the ignore rule, not
    // win by declaration order.
    final int lowestIgnore = <int>[
      for (final IssuerRule rule in ruleSet.globalIgnoreRules) rule.priority,
    ].reduce((int a, int b) => a < b ? a : b);
    for (final IssuerDefinition issuer in ruleSet.issuers) {
      for (final IssuerRule rule in issuer.rules) {
        if (rule.action == RuleAction.capture) {
          expect(rule.priority, lessThan(lowestIgnore), reason: rule.ruleId);
        }
      }
    }
  });

  test('Bancolombia is NOT in the catalog', () {
    // It sends SMS, not push notifications, and an SMS arrives as a
    // notification of the MESSAGING app. Capturing it would mean reading the
    // sender of every message the user gets, which breaks the "filter by
    // packageName before reading anything" rule of HU-08. Reintroducing it
    // needs a fresh decision, not just a rule — hence this test.
    expect(ruleSet.issuerById('bancolombia'), isNull);
    expect(
      ruleSet.issuerForPackage('co.com.bancolombia.personas.superapp'),
      isNull,
    );
  });

  test('no issuer rule is written blind', () {
    // Every catalogued rule was written against a real captured notification.
    for (final IssuerDefinition issuer in ruleSet.issuers) {
      for (final IssuerRule rule in issuer.rules) {
        expect(rule.validated, isTrue, reason: rule.ruleId);
      }
      expect(issuer.packageNameValidated, isTrue, reason: issuer.issuerId);
    }
  });

  test('the rules covering real notifications are marked validated', () {
    const Set<String> shouldBeValidated = <String>{
      'nu.income.with_counterparty',
      'nu.purchase.with_merchant',
      'nu.sent.with_counterparty',
      'nequi.income',
      'nequi.sent',
      'google_wallet.tap_payment',
      'google_wallet.ignore.reminder',
    };
    final Set<String> validated = <String>{
      for (final IssuerDefinition issuer in ruleSet.issuers)
        for (final IssuerRule rule in issuer.rules)
          if (rule.validated) rule.ruleId,
    };
    expect(validated.containsAll(shouldBeValidated), isTrue);
  });
}
