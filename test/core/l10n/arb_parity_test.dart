import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the rule `avoid_hardcoded_ui_strings` leans on: every user-facing
/// string comes from `AppLocalizations`, and the app ships in es **and** en.
///
/// A key added to only one file is a screen that falls back to the other
/// language at runtime. The lint cannot see that; this test can.
void main() {
  const arbDir = 'lib/core/l10n/arb';

  Map<String, dynamic> readArb(String name) =>
      jsonDecode(File('$arbDir/$name').readAsStringSync())
          as Map<String, dynamic>;

  /// Translatable keys only: `@@locale` is metadata and `@key` is the
  /// description of another key, neither is a string the user reads.
  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((key) => !key.startsWith('@')).toSet();

  late Map<String, dynamic> es;
  late Map<String, dynamic> en;

  setUpAll(() {
    es = readArb('app_es.arb');
    en = readArb('app_en.arb');
  });

  test('app_es.arb y app_en.arb tienen exactamente las mismas claves', () {
    final esKeys = messageKeys(es);
    final enKeys = messageKeys(en);

    expect(
      esKeys.difference(enKeys),
      isEmpty,
      reason: 'faltan en app_en.arb',
    );
    expect(
      enKeys.difference(esKeys),
      isEmpty,
      reason: 'faltan en app_es.arb (la plantilla)',
    );
  });

  test('ninguna traducción quedó vacía', () {
    for (final arb in [es, en]) {
      for (final key in messageKeys(arb)) {
        expect(
          (arb[key]! as String).trim(),
          isNotEmpty,
          reason: '"$key" está vacía en ${arb['@@locale']}',
        );
      }
    }
  });

  test('los placeholders de cada clave coinciden entre idiomas', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    Set<String> placeholdersOf(String value) =>
        placeholder.allMatches(value).map((m) => m.group(1)!).toSet();

    for (final key in messageKeys(es)) {
      expect(
        placeholdersOf(en[key]! as String),
        placeholdersOf(es[key]! as String),
        // Un placeholder que no existe en el otro idioma revienta en tiempo de
        // ejecución, no al compilar.
        reason: 'los placeholders de "$key" no coinciden',
      );
    }
  });
}
