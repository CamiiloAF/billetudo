import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nivel 0: Categorías es gratis y completa (AC 16 en
/// `docs/dev-runs/categorias-feature.md`). Ninguna de sus capacidades (crear,
/// editar, reordenar, eliminar con sus 3 resoluciones, seed de onboarding)
/// puede quedar detrás de un anuncio, un cupo o un paywall (CLAUDE.md).
///
/// Esto se verifica sobre el código fuente porque es una regla de producto: un
/// test de comportamiento no puede probar la *ausencia* de un paywall que
/// nadie escribió todavía, pero sí puede fallar el día que alguien lo agregue.
/// Mismo patrón que `test/features/accounts/tier0_test.dart`.
void main() {
  final featureDir = Directory('lib/features/categories');

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
      reason: 'No se encontró lib/features/categories',
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
      reason: 'Nivel 0: Categorías no puede depender de monetización.\n'
          '${offenders.join('\n')}',
    );
  });

  test('ninguna capacidad de Categorías está condicionada por premium o '
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
      reason: 'Nivel 0: ninguna capacidad de Categorías va detrás de '
          'pago/cupo.\n${offenders.join('\n')}',
    );
  });

  test('no existe un límite de cantidad de categorías o subcategorías', () {
    final limitPattern = RegExp(
      r'\b(maxCategories|categoryLimit|maxCategoryCount|'
      r'freeCategoryLimit|categoriesLimit|limitReached|'
      r'tooManyCategories)\b',
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
      reason: 'Nivel 0: no puede haber tope de categorías.\n'
          '${offenders.join('\n')}',
    );
  });

  test('crear una categoría no consulta ningún gate: solo valida y '
      'persiste', () {
    // CreateCategory es el punto natural donde aparecería un "ya usaste tus
    // N categorías gratis". Sus dependencias deben ser únicamente el
    // repositorio.
    final source =
        File('lib/features/categories/domain/usecases/create_category.dart')
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
        reason: 'CreateCategory no puede depender de monetización',
      );
    }
  });

  test('el seed de onboarding (HU-06) no consulta ningún gate', () {
    // El set semilla de categorías es parte del Nivel 0 gratuito: no debe
    // depender de si el usuario tiene cupo o es premium.
    final source = File(
      'lib/features/categories/domain/usecases/seed_default_categories.dart',
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
        reason: 'SeedDefaultCategories no puede depender de monetización',
      );
    }
  });
}
