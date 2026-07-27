import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nivel 0: Transacciones es gratis, ilimitada y sin anuncios (CLAUDE.md).
/// Ninguna de sus capacidades (registrar gasto/ingreso/transferencia, editar,
/// eliminar con papelera, buscar y filtrar, etiquetar, ver detalle) puede
/// quedar detrás de un anuncio, un cupo o un paywall.
///
/// Esto se verifica sobre el código fuente porque es una regla de producto: un
/// test de comportamiento no puede probar la *ausencia* de un paywall que
/// nadie escribió todavía, pero sí puede fallar el día que alguien lo agregue.
/// Mismo patrón que `test/features/accounts/tier0_test.dart` y
/// `test/features/categories/tier0_test.dart`.
void main() {
  final featureDir = Directory('lib/features/transactions');

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
      reason: 'No se encontró lib/features/transactions',
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
      reason: 'Nivel 0: Transacciones no puede depender de monetización.\n'
          '${offenders.join('\n')}',
    );
  });

  test(
      'ninguna capacidad de Transacciones está condicionada por premium o '
      'cupo', () {
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
      reason: 'Nivel 0: ninguna capacidad de Transacciones va detrás de '
          'pago/cupo.\n${offenders.join('\n')}',
    );
  });

  test('no existe un límite de cantidad de transacciones', () {
    // El registro manual es ilimitado (CLAUDE.md): un límite aquí rompería la
    // promesa "100% funcional gratis" de Nivel 0.
    final limitPattern = RegExp(
      r'\b(maxTransactions|transactionLimit|maxTransactionCount|'
      r'freeTransactionLimit|transactionsLimit|limitReached|'
      r'tooManyTransactions)\b',
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
      reason: 'Nivel 0: no puede haber tope de transacciones.\n'
          '${offenders.join('\n')}',
    );
  });

  test(
      'crear una transacción no consulta ningún gate: solo valida y '
      'persiste', () {
    // CreateTransaction es el punto natural donde aparecería un "ya usaste
    // tus N registros gratis" (ej. para diferenciar captura manual de IA).
    // Sus dependencias deben ser únicamente el repositorio.
    final source = File(
      'lib/features/transactions/domain/usecases/create_transaction.dart',
    ).readAsStringSync();

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
        reason: 'CreateTransaction no puede depender de monetización',
      );
    }
  });

  test('crear una etiqueta (HU-07) no consulta ningún gate', () {
    final source = File(
      'lib/features/transactions/domain/usecases/create_tag.dart',
    ).readAsStringSync();

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
        reason: 'CreateTag no puede depender de monetización',
      );
    }
  });
}
