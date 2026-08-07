/// Why a CSV row cannot be imported as-is. Attached to a row whose required
/// field is missing/unparseable — HU-06: "filas inválidas no bloquean el
/// resto", only the offending row is skipped.
enum ImportRowIssue {
  missingAccount,
  missingDate,
  invalidDate,
  missingAmount,
  invalidAmount,
  invalidType,
}
