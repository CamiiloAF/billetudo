import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nivel 0: Cuentas es gratis y completa. Ninguna de sus capacidades (crear,
/// editar, archivar, eliminar, reordenar, número de cuenta, tarjeta,
/// multi-moneda) puede quedar detrás de un anuncio, un cupo o un paywall, y no
/// existe límite de cantidad de cuentas (CLAUDE.md).
///
/// Esto se verifica sobre el código fuente porque es una regla de producto: un
/// test de comportamiento no puede probar la *ausencia* de un paywall que nadie
/// escribió todavía, pero sí puede fallar el día que alguien lo agregue.
void main() {
  final featureDir = Directory('lib/features/accounts');

  List<File> dartFiles() => featureDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  setUpAll(() {
    // Si la feature se moviera de sitio, el test debe gritar, no pasar vacío.
    expect(
      featureDir.existsSync(),
      isTrue,
      reason: 'No se encontró lib/features/accounts',
    );
    expect(dartFiles(), isNotEmpty);
  });

  test('la feature no importa monetización (ads, RevenueCat, paywall)', () {
    const forbidden = [
      'google_mobile_ads',
      'revenuecat',
      'purchases_flutter',
      'admob',
      'in_app_purchase',
    ];

    final offenders = <String>[];
    for (final file in dartFiles()) {
      final source = file.readAsStringSync().toLowerCase();
      for (final import in forbidden) {
        if (source.contains(import)) {
          offenders.add('${file.path} -> $import');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Nivel 0: Cuentas no puede depender de monetización.\n'
          '${offenders.join('\n')}',
    );
  });

  test('ninguna capacidad de Cuentas está condicionada por premium o cupo', () {
    // Identificadores que delatarían un gate: `isPremium`, `hasQuota`,
    // `showRewardedAd`, `entitlement`... Se busca por símbolo, no por palabra
    // suelta, para no castigar un comentario.
    final gatePattern = RegExp(
      r'\b(isPremium|isPro|hasPremium|requiresPremium|premiumOnly|'
      r'showPaywall|paywall|entitlement|rewardedAd|showRewarded|'
      r'hasQuota|quotaLeft|remainingQuota|checkQuota|consumeQuota|'
      r'isLocked|unlockWithAd)\b',
    );

    final offenders = <String>[];
    for (final file in dartFiles()) {
      for (final (index, line) in file.readAsLinesSync().indexed) {
        if (gatePattern.hasMatch(line)) {
          offenders.add('${file.path}:${index + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Nivel 0: ninguna capacidad de Cuentas va detrás de pago/cupo.\n'
          '${offenders.join('\n')}',
    );
  });

  test('no existe un límite de cantidad de cuentas', () {
    // El único bloqueo legítimo al crear/eliminar es "no puedes borrar la
    // última cuenta" (HU-08), que es integridad de datos, no monetización.
    final limitPattern = RegExp(
      r'\b(maxAccounts|accountLimit|maxAccountCount|freeAccountLimit|'
      r'accountsLimit|limitReached|tooManyAccounts)\b',
    );

    final offenders = <String>[];
    for (final file in dartFiles()) {
      for (final (index, line) in file.readAsLinesSync().indexed) {
        if (limitPattern.hasMatch(line)) {
          offenders.add('${file.path}:${index + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Nivel 0: no puede haber tope de cuentas.\n'
          '${offenders.join('\n')}',
    );
  });

  test('crear una cuenta no consulta ningún gate: solo valida y persiste', () {
    // CreateAccount es el punto natural donde aparecería un "ya usaste tus N
    // cuentas gratis". Sus dependencias deben ser únicamente el repositorio.
    final source =
        File('lib/features/accounts/domain/usecases/create_account.dart')
            .readAsStringSync();

    final imports = RegExp(r"^import\s+'([^']+)'", multiLine: true)
        .allMatches(source)
        .map((match) => match.group(1)!)
        .toList();

    expect(imports, isNotEmpty);
    for (final import in imports) {
      expect(
        import,
        isNot(
          anyOf(contains('ads'), contains('purchase'), contains('billing')),
        ),
        reason: 'CreateAccount no puede depender de monetización',
      );
    }
  });
}
