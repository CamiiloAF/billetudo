import 'package:billetudo/core/sync/presentation/utils/sync_freshness.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 24 h threshold is the literal lesson of the incident behind HU-08: past
/// it, "sincronizando" and "sincronizando desde hace tres días" must stop
/// looking the same. The exact boundary is pinned in both directions because a
/// refactor that flips `>=` to `>` would move the alarm by a whole day.
void main() {
  final now = DateTime(2026, 7, 28, 12);

  test('el umbral documentado es de 24 h', () {
    expect(SyncFreshness.staleAfter, const Duration(hours: 24));
  });

  test('nunca sincronizó (null) NO es viejo: es informativo, no ámbar', () {
    expect(SyncFreshness.isStale(null, now: now), isFalse);
  });

  test('justo en el límite (exactamente 24 h) YA es viejo', () {
    expect(
      SyncFreshness.isStale(now.subtract(const Duration(hours: 24)), now: now),
      isTrue,
    );
  });

  test('un segundo antes del límite (23:59:59) todavía NO es viejo', () {
    expect(
      SyncFreshness.isStale(
        now.subtract(const Duration(hours: 23, minutes: 59, seconds: 59)),
        now: now,
      ),
      isFalse,
    );
  });

  test('un segundo después del límite (24:00:01) es viejo', () {
    expect(
      SyncFreshness.isStale(
        now.subtract(const Duration(hours: 24, seconds: 1)),
        now: now,
      ),
      isTrue,
    );
  });

  test('tres días (el caso del incidente) es viejo', () {
    expect(
      SyncFreshness.isStale(now.subtract(const Duration(days: 3)), now: now),
      isTrue,
    );
  });

  test('recién sincronizado no es viejo', () {
    expect(
      SyncFreshness.isStale(now.subtract(const Duration(minutes: 2)), now: now),
      isFalse,
    );
  });

  test('un reloj adelantado (futuro) no marca viejo', () {
    expect(
      SyncFreshness.isStale(now.add(const Duration(days: 2)), now: now),
      isFalse,
    );
  });
}
