import 'package:sentry_flutter/sentry_flutter.dart';

/// Marker left in place of every value this module strips out.
const String redactionPlaceholder = '<redacted>';

/// Removes row values from the free-text parts of a Sentry event before it
/// leaves the device.
///
/// Why this exists: the sync connector reports raw Postgres/Supabase
/// exceptions, and Postgres embeds the rejected row in its own error text
/// (`Key (id)=(...)`, `Failing row contains (...)`). `sqlite3` does the same
/// with `, parameters: ...`. In a finance app those literals can be an amount,
/// a transaction note or an account name. Sentry's server-side scrubbers run
/// on ingest; this runs before the request is built, so the value never leaves
/// the phone.
///
/// ## What the patterns cover
///  * `Key (col, col)=(v1, v2)` — column names kept, values dropped.
///  * `Failing row contains (...)` — everything up to the end of the line.
///  * `, parameters: ...` (`SqliteException`) — to the end of the line.
///  * Any single-quoted literal — Postgres quotes *values* with single quotes
///    and *schema identifiers* with double quotes, so
///    `unique constraint "transactions_pkey"` stays readable on purpose.
///  * The double-quoted operand of `invalid input syntax for type x: "..."`
///    and `invalid input value for enum x: "..."`, the two common cases where
///    a double-quoted token is a value and not an identifier.
///
/// ## What it does NOT cover (deliberately stated: a filter sold as airtight
/// but leaky would be worse than none)
///  * Values interpolated into prose with no quoting and no known marker
///    (`could not parse cena con Ana`) — unrecognizable without dropping the
///    message entirely.
///  * Any other double-quoted token: treated as a schema identifier.
///  * Values containing an unbalanced `(`/`)` inside a `Key (...)=(...)`
///    group: the group ends at the first `)`, so a tail may survive.
///  * Data the caller puts in `contexts`/`extra` (for example
///    `SentryCrashReporter.recordFailure`, which forwards `Failure.message`) —
///    those are structured fields set by our own code and are expected to be
///    technical; this module only sweeps the free text that comes from the
///    database driver.
///  * Values inside stack frames, exception types, HTTP payloads or native
///    (Android/iOS) crash reports produced outside the Dart layer.
String redactSensitiveText(String input) {
  var output = input;
  for (final rule in _rules) {
    output = output.replaceAllMapped(rule.pattern, rule.replace);
  }
  return output;
}

/// Applies [redactSensitiveText] to every free-text field of [event] that can
/// carry driver-generated row values: exception messages, the event message
/// and breadcrumbs.
///
/// Breadcrumbs are included because `CrashReporter.log` takes an arbitrary
/// string from the caller and because SDK integrations add their own; a
/// breadcrumb travels with the event, so leaving it unfiltered would reopen
/// the same hole the exception filter closes.
/// The event is mutated in place and returned: since Sentry 9 the protocol
/// classes expose mutable fields and their `copyWith` is deprecated.
SentryEvent redactSentryEvent(SentryEvent event) {
  for (final exception in event.exceptions ?? const <SentryException>[]) {
    final value = exception.value;
    if (value != null) {
      exception.value = redactSensitiveText(value);
    }
  }

  final message = event.message;
  if (message != null) {
    message.formatted = redactSensitiveText(message.formatted);
    final template = message.template;
    if (template != null) {
      message.template = redactSensitiveText(template);
    }
    message.params = message.params
        ?.map<dynamic>(
          (param) => param is String ? redactSensitiveText(param) : param,
        )
        .toList();
  }

  for (final breadcrumb in event.breadcrumbs ?? const <Breadcrumb>[]) {
    _redactBreadcrumb(breadcrumb);
  }

  return event;
}

void _redactBreadcrumb(Breadcrumb breadcrumb) {
  final message = breadcrumb.message;
  if (message != null) {
    breadcrumb.message = redactSensitiveText(message);
  }
  // Reassigned instead of edited in place: the SDK hands out maps that may be
  // unmodifiable.
  breadcrumb.data = breadcrumb.data?.map<String, dynamic>(
    (key, value) => MapEntry(
      key,
      value is String ? redactSensitiveText(value) : value,
    ),
  );
}

typedef _Replace = String Function(Match match);

final class _RedactionRule {
  const _RedactionRule(this.pattern, this.replace);

  final RegExp pattern;
  final _Replace replace;
}

/// Ordered on purpose: the marker-based rules run before the generic
/// single-quote sweep so their output keeps the readable prefix.
final List<_RedactionRule> _rules = <_RedactionRule>[
  // Postgres unique/foreign key detail: `Key (id)=(abc-123) already exists.`
  _RedactionRule(
    RegExp(r'Key \(([^()]*)\)=\([^()]*\)'),
    (match) => 'Key (${match[1]})=($redactionPlaceholder)',
  ),
  // Postgres check-constraint detail: the whole rejected row.
  _RedactionRule(
    RegExp(r'Failing row contains \(.*'),
    (_) => 'Failing row contains ($redactionPlaceholder)',
  ),
  // `SqliteException` appends the bound variables of the failing statement.
  _RedactionRule(
    RegExp(r', parameters: .*'),
    (_) => ', parameters: $redactionPlaceholder',
  ),
  // Double-quoted operand that is a value, not a schema identifier.
  _RedactionRule(
    RegExp(
        r'(invalid input (?:syntax for type|value for enum) [^:"]*: )"[^"]*"'),
    (match) => '${match[1]}"$redactionPlaceholder"',
  ),
  // Postgres quotes literals with single quotes. Prose contractions
  // ("doesn't ... isn't") can be swallowed by this rule: that over-redacts,
  // it never under-redacts, so it is the acceptable side of the trade.
  _RedactionRule(
    RegExp("'[^']*'"),
    (_) => "'$redactionPlaceholder'",
  ),
];
