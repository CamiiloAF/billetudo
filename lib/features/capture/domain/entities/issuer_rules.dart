import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction.dart';

/// What a rule does when it matches.
enum RuleAction {
  /// Produce a capture candidate.
  capture,

  /// Swallow the notification: it is not a movement (OTP, promo, security
  /// notice, statement, payment reminder). Nothing is persisted, nothing is
  /// counted.
  ignore,
}

/// Which part of the notification a rule's regex runs against. Declared per
/// rule because issuers are not consistent: Nu puts the amount in the title
/// and the counterparty in the body, and Nequi puts the amount mid-sentence
/// inside the body with no figure in the title at all.
enum RuleTarget { title, text, combined }

/// A single parsing rule, as declared in `assets/capture/issuer_rules.json`.
///
/// Rules are data, never code: adding an issuer format must be editing that
/// JSON plus a test case, nothing else. The Kotlin engine reads the very same
/// file — see `NotificationRuleEngine.kt`.
class IssuerRule extends Equatable {
  const IssuerRule({
    required this.ruleId,
    required this.priority,
    required this.action,
    required this.target,
    required this.pattern,
    required this.validated,
    this.entryType,
    this.captures = const <String, String>{},
    this.note,
  });

  factory IssuerRule.fromJson(Map<String, dynamic> json) {
    final String? entryTypeName = json['entryType'] as String?;
    return IssuerRule(
      ruleId: json['ruleId'] as String,
      priority: json['priority'] as int? ?? 0,
      action: (json['action'] as String? ?? 'capture') == 'ignore'
          ? RuleAction.ignore
          : RuleAction.capture,
      target: _targetFrom(json['target'] as String?),
      pattern: json['match'] as String,
      validated: json['validated'] as bool? ?? false,
      entryType: entryTypeName == null ? null : _entryTypeFrom(entryTypeName),
      captures: <String, String>{
        for (final MapEntry<String, dynamic> e
            in (json['captures'] as Map<String, dynamic>? ??
                    <String, dynamic>{})
                .entries)
          e.key: e.value as String,
      },
      note: json['note'] as String?,
    );
  }

  /// Stable id stored on every capture (`PendingCaptures.sourceRuleId`). With
  /// zero retention this is the only handle to debug a parser that starts
  /// misfiring, so it must never be reused for a different format.
  final String ruleId;

  /// Higher wins. Ignore rules sit above capture rules on purpose: an OTP that
  /// happens to contain a figure must never become a movement.
  final int priority;

  final RuleAction action;
  final RuleTarget target;

  /// The regex source. Always applied case-insensitively.
  final String pattern;

  /// `false` while nobody has seen a real notification in this format. Such a
  /// rule is a guess and is documented as such in `assets/capture/README.md`.
  final bool validated;

  /// The movement this rule produces. Null for [RuleAction.ignore] rules.
  final TransactionType? entryType;

  /// Field name -> named group in [pattern]. Supported field names: `amount`
  /// (mandatory for a capture rule), `merchant`, `last4`.
  final Map<String, String> captures;

  final String? note;

  /// Compiled form. Built lazily by the engine, not stored here, so the entity
  /// stays a value object.
  RegExp compile() => RegExp(pattern, caseSensitive: false);

  static RuleTarget _targetFrom(String? raw) => switch (raw) {
        'title' => RuleTarget.title,
        'text' => RuleTarget.text,
        _ => RuleTarget.combined,
      };

  static TransactionType _entryTypeFrom(String raw) => switch (raw) {
        'income' => TransactionType.income,
        'transfer' => TransactionType.transfer,
        // Ambiguity resolves to expense, the dominant case (HU-03).
        _ => TransactionType.expense,
      };

  @override
  List<Object?> get props => <Object?>[ruleId];
}

/// One catalogued issuer: the app whose notifications may be read, plus its
/// rules. The catalog is CLOSED (decision 2026-08-27): an app not listed here
/// can never be enabled, and therefore is never read.
class IssuerDefinition extends Equatable {
  const IssuerDefinition({
    required this.issuerId,
    required this.displayName,
    required this.packageName,
    required this.defaultCurrency,
    required this.rules,
    this.additionalPackageNames = const <String>[],
    this.packageNameValidated = false,
  });

  factory IssuerDefinition.fromJson(Map<String, dynamic> json) =>
      IssuerDefinition(
        issuerId: json['issuerId'] as String,
        displayName: json['displayName'] as String,
        packageName: json['packageName'] as String,
        defaultCurrency: json['defaultCurrency'] as String? ?? 'COP',
        additionalPackageNames: <String>[
          for (final dynamic p
              in json['additionalPackageNames'] as List<dynamic>? ??
                  <dynamic>[])
            p as String,
        ],
        packageNameValidated: json['packageNameValidated'] as bool? ?? false,
        rules: <IssuerRule>[
          for (final dynamic r in json['rules'] as List<dynamic>)
            IssuerRule.fromJson(r as Map<String, dynamic>),
        ],
      );

  final String issuerId;
  final String displayName;

  /// Primary Android package of the issuer's app.
  final String packageName;

  /// Other packages the same issuer has shipped under (rebrands, regional
  /// builds). Matching any of them counts as this issuer.
  final List<String> additionalPackageNames;

  /// `false` while the package name has not been confirmed against a real
  /// device (`adb shell pm list packages`). A wrong package is a silent
  /// failure: nothing is captured and nothing is logged, by design.
  final bool packageNameValidated;

  /// Currency assumed when the notification does not spell one out — which is
  /// always, for es-CO issuers.
  final String defaultCurrency;

  final List<IssuerRule> rules;

  /// Every package that identifies this issuer.
  List<String> get allPackageNames => <String>[
        packageName,
        ...additionalPackageNames,
      ];

  bool matchesPackage(String candidate) => allPackageNames.contains(candidate);

  @override
  List<Object?> get props => <Object?>[issuerId];
}

/// The whole rule catalog, parsed from `assets/capture/issuer_rules.json`.
class IssuerRuleSet extends Equatable {
  const IssuerRuleSet({
    required this.schemaVersion,
    required this.issuers,
    this.globalIgnoreRules = const <IssuerRule>[],
  });

  factory IssuerRuleSet.fromJson(Map<String, dynamic> json) => IssuerRuleSet(
        schemaVersion: json['schemaVersion'] as int? ?? 1,
        globalIgnoreRules: <IssuerRule>[
          for (final dynamic r
              in json['globalIgnoreRules'] as List<dynamic>? ?? <dynamic>[])
            IssuerRule.fromJson(r as Map<String, dynamic>),
        ],
        issuers: <IssuerDefinition>[
          for (final dynamic i in json['issuers'] as List<dynamic>)
            IssuerDefinition.fromJson(i as Map<String, dynamic>),
        ],
      );

  /// Parses the raw asset contents.
  factory IssuerRuleSet.fromRawJson(String raw) =>
      IssuerRuleSet.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  final int schemaVersion;

  /// Applied to every issuer before its own rules: OTPs, security notices,
  /// promos, statements and payment reminders look the same everywhere.
  final List<IssuerRule> globalIgnoreRules;

  final List<IssuerDefinition> issuers;

  IssuerDefinition? issuerForPackage(String packageName) {
    for (final IssuerDefinition issuer in issuers) {
      if (issuer.matchesPackage(packageName)) {
        return issuer;
      }
    }
    return null;
  }

  IssuerDefinition? issuerById(String issuerId) {
    for (final IssuerDefinition issuer in issuers) {
      if (issuer.issuerId == issuerId) {
        return issuer;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[schemaVersion, issuers];
}
