import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../settings/domain/repositories/app_settings_repository.dart';
import '../repositories/category_repository.dart';

/// HU-06: seeds the onboarding set of common categories exactly once in the
/// lifetime of the installation.
///
/// The set itself now comes from the `category_seeds` table in Postgres, not
/// a static Dart list (`docs/requirements/05-auth-sync.md`, decision #12) —
/// `CategoryRepository.seedDefaultCategories()` fetches it under the hood.
/// That means this can fail with a `NetworkFailure` on a device's first
/// launch with no connectivity: this use case propagates that failure as-is
/// (does **not** swallow it) and, critically, does **not** call
/// `markCategoriesSeeded()` in that case — the latch only ever turns on once
/// the set has actually landed locally, so a retry (wired up once the
/// "sin conexión en el primer arranque" screen exists) can simply call this
/// again.
///
/// Idempotence is guaranteed by the persistent `categoriesSeeded` latch on the
/// `AppSettings` singleton — NOT by `hasAnyCategory`. Once the flag is set it is
/// never cleared, so a user who deletes every category does not get the defaults
/// re-seeded on the next launch (the old row-count check re-seeded in that case).
///
/// On first run: if the user somehow already has categories (a pre-flag
/// installation, or a partial state) we do NOT seed — to avoid duplicating what
/// they built — but we still latch the flag so the check is settled forever.
@injectable
class SeedDefaultCategories {
  const SeedDefaultCategories(this._repository, this._settingsRepository);

  final CategoryRepository _repository;
  final AppSettingsRepository _settingsRepository;

  FutureResult<Unit> call() async {
    final settingsResult = await _settingsRepository.getSettings();
    if (settingsResult case Left(value: final failure)) {
      return Left(failure);
    }
    final settings = settingsResult.getOrElse(
      (_) => throw StateError('unreachable: settingsResult is Left'),
    );
    if (settings.categoriesSeeded) {
      return const Right(unit);
    }

    final hasAnyResult = await _repository.hasAnyCategory();
    if (hasAnyResult case Left(value: final failure)) {
      return Left(failure);
    }
    final hasAny = hasAnyResult.getOrElse(
      (_) => throw StateError('unreachable: hasAnyResult is Left'),
    );

    if (!hasAny) {
      final seedResult = await _repository.seedDefaultCategories();
      if (seedResult case Left(value: final failure)) {
        return Left(failure);
      }
    }

    return _settingsRepository.markCategoriesSeeded();
  }
}
