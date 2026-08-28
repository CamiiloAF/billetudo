/// Shared by the two payloads the assistant sends to the model — the
/// snapshot (`BuildFinancialSnapshot`) and every tool result
/// (`ResolveAiToolCall`) — because the same promise is made about both.
///
/// The server prompt ASSERTS to the model that every amount arrives
/// pre-formatted, and tells it to copy that string instead of dividing by
/// 100 itself. Where the twin was missing the model did the arithmetic
/// anyway and quoted a balance a hundred times too large ("$379.931.350"
/// for $3.799.313,50). This walks the wire payload instead of naming
/// fields, so an amount added later without its twin fails the moment it
/// appears.
library;

/// Every `<name>Minor` key in [json] whose `<name>Formatted` sibling is
/// missing or empty, as a dotted path — the failure message names the field
/// instead of just saying "not empty".
///
/// Walks maps and lists alike, so a twin lost inside any list row (accounts,
/// cash-flow points, category lines) surfaces the same way.
List<String> amountsMissingFormattedTwin(Object? json, [String path = '']) {
  const minorSuffix = 'Minor';
  final missing = <String>[];
  if (json is Map<String, Object?>) {
    for (final entry in json.entries) {
      final key = entry.key;
      final here = path.isEmpty ? key : '$path.$key';
      if (key.endsWith(minorSuffix)) {
        final twin =
            '${key.substring(0, key.length - minorSuffix.length)}Formatted';
        final value = json[twin];
        if (value is! String || value.isEmpty) {
          missing.add(path.isEmpty ? twin : '$path.$twin');
        }
      }
      missing.addAll(amountsMissingFormattedTwin(entry.value, here));
    }
  } else if (json is List) {
    for (var i = 0; i < json.length; i++) {
      missing.addAll(amountsMissingFormattedTwin(json[i], '$path[$i]'));
    }
  }
  return missing;
}
