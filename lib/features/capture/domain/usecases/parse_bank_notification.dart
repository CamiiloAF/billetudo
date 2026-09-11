import 'package:injectable/injectable.dart';

import '../../../transactions/domain/entities/transaction.dart';
import '../entities/issuer_rules.dart';
import '../entities/notification_message.dart';
import '../entities/parsed_notification.dart';
import '../parsing/notification_amount_parser.dart';

/// Turns one bank notification into a capture candidate, or into nothing.
///
/// **This is the MIRROR engine.** In production the parsing happens in Kotlin,
/// inside `NotificationListenerService`, because the service runs with the app
/// closed and no Flutter engine alive, and zero retention forbids buffering
/// the text until the app opens (HU-03). This Dart copy exists so the example
/// battery can be run with `flutter test` and for the Fase 4 path.
///
/// The ENGINE is duplicated, the RULES are not: both sides read
/// `assets/capture/issuer_rules.json`. A rule that only works on one side is a
/// bug — `NotificationRuleEngine.kt` must be kept behaviorally identical.
@injectable
class ParseBankNotification {
  const ParseBankNotification();

  /// Returns the capture candidate, or `null` when the notification must not
  /// produce one. `null` covers, in order:
  ///
  /// 1. the emitting package is not in [ruleSet] or is not in [enabledIssuers]
  ///    — checked BEFORE any rule looks at the title or the body, mirroring
  ///    `IssuerFilter` on the native side;
  /// 2. an ignore rule matched (OTP, security notice, promo, statement,
  ///    payment reminder);
  /// 3. no rule matched at all;
  /// 4. a capture rule matched but no usable amount came out of it — no
  ///    amount, no capture.
  ParsedNotification? call(
    NotificationMessage message, {
    required IssuerRuleSet ruleSet,
    required Set<String> enabledIssuers,
  }) {
    // ---- Issuer filter -------------------------------------------------
    // Nothing above this line touches `message.title` or `message.text`, and
    // nothing may. The notification shade also holds chats, e-mail and SMS
    // one-time codes; reading them at all is the failure mode this ordering
    // prevents (HU-08).
    final IssuerDefinition? issuer =
        ruleSet.issuerForPackage(message.packageName);
    if (issuer == null || !enabledIssuers.contains(issuer.issuerId)) {
      return null;
    }

    final List<IssuerRule> rules = <IssuerRule>[
      ...ruleSet.globalIgnoreRules,
      ...issuer.rules,
    ]..sort((IssuerRule a, IssuerRule b) => b.priority.compareTo(a.priority));

    for (final IssuerRule rule in rules) {
      final RegExpMatch? match = rule.compile().firstMatch(
            _surfaceFor(rule.target, message),
          );
      if (match == null) {
        continue;
      }
      if (rule.action == RuleAction.ignore) {
        // Highest-priority match wins and it is an ignore: this notification
        // is not a movement. Nothing is persisted or counted.
        return null;
      }

      final int? amountMinor = _amountOf(rule, match);
      if (amountMinor == null) {
        // The rule shape matched but the figure was unusable. Do NOT fall
        // through to a lower-priority rule: a second reading of the same
        // message is how a wrong amount gets invented.
        return null;
      }

      final String? merchant = _cleanup(_group(rule, match, 'merchant'));
      final String? last4 = _last4(_group(rule, match, 'last4'));
      final String? currency = _cleanup(_group(rule, match, 'currency'));
      final String? cardNetwork = _cleanup(_group(rule, match, 'cardNetwork'));

      return ParsedNotification(
        issuerId: issuer.issuerId,
        sourcePackage: message.packageName,
        ruleId: rule.ruleId,
        amountMinor: amountMinor,
        currency: currency?.toUpperCase() ?? issuer.defaultCurrency,
        entryType: rule.entryType ?? TransactionType.expense,
        postedAt: message.postedAt,
        merchantRaw: merchant,
        accountHint: last4,
        cardNetwork: cardNetwork,
      );
    }

    // No rule matched. The issuer may count this locally to prioritize which
    // rule to write next, but the content is never kept (HU-03).
    return null;
  }

  String _surfaceFor(RuleTarget target, NotificationMessage message) =>
      switch (target) {
        RuleTarget.title => message.title,
        RuleTarget.text => message.text,
        RuleTarget.combined => message.combined,
      };

  int? _amountOf(IssuerRule rule, RegExpMatch match) {
    final String? raw = _group(rule, match, 'amount');
    if (raw == null) {
      return null;
    }
    return NotificationAmountParser.parseMinor(raw);
  }

  /// Reads the named group a rule declared for [field], tolerating rules that
  /// do not declare the field at all.
  String? _group(IssuerRule rule, RegExpMatch match, String field) {
    final String? groupName = rule.captures[field];
    if (groupName == null) {
      return null;
    }
    if (!match.groupNames.contains(groupName)) {
      return null;
    }
    return match.namedGroup(groupName);
  }

  String? _cleanup(String? value) {
    final String trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Normalizes whatever masking the issuer used (`••5615`, `*5615`,
  /// `**** 5615`, `x5615`, `...5615`) down to the four digits.
  String? _last4(String? value) {
    if (value == null) {
      return null;
    }
    final String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) {
      return null;
    }
    return digits.substring(digits.length - 4);
  }
}
