/// Normalizes a name for case/tilde/whitespace-insensitive matching, used by
/// destination resolution (HU-06 — "comida y bebida" must land on "Comida y
/// bebida") and by header autodetection (HU-05 — a CSV whose own export used
/// slightly different spacing/casing still recognizes as the app's own
/// format). Pure, no Drift/Flutter dependency, so it is directly testable.
String normalizeForMatching(String value) {
  final lower = value.trim().toLowerCase();
  final withoutDiacritics = lower.split('').map((char) {
    final index = _accented.indexOf(char);
    return index == -1 ? char : _plain[index];
  }).join();
  return withoutDiacritics.replaceAll(RegExp(r'\s+'), ' ');
}

const String _accented = 'áàäâãéèëêíìïîóòöôõúùüûñç';
const String _plain = 'aaaaaeeeeiiiiooooouuuunc';
