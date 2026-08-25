import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../../../settings/domain/repositories/app_settings_repository.dart';

/// `docs/requirements/fase-1/13-onboarding.md`, "Persistencia y ciclo de vida del
/// flujo": decides whether the welcome flow should be shown on this launch,
/// evaluated once, after bootstrap.
///
/// Three outcomes:
/// - The `onboardingCompleted` latch is already on: returns `false`, no side
///   effect.
/// - The latch is off but at least one active (non-tombstoned, non-archived)
///   account already exists — a pre-flag installation, or data restored via
///   import/export: turns the latch on **silently** (so nobody who was
///   already using the app sees the flow after an update) and returns `false`.
/// - The latch is off and there are no active accounts: returns `true`, the
///   flow should be shown.
///
/// Reuses `AccountRepository.watchActiveAccounts()` (the same query the
/// Accounts list uses) rather than a bespoke count, so "active" always means
/// the same thing everywhere in the app.
@injectable
class ShouldShowOnboarding {
  const ShouldShowOnboarding(this._settingsRepository, this._accountRepository);

  final AppSettingsRepository _settingsRepository;
  final AccountRepository _accountRepository;

  FutureResult<bool> call() async {
    final settingsResult = await _settingsRepository.getSettings();
    if (settingsResult case Left(value: final failure)) {
      return Left(failure);
    }
    final settings = settingsResult.getOrElse(
      (_) => throw StateError('unreachable: settingsResult is Left'),
    );
    if (settings.onboardingCompleted) {
      return const Right(false);
    }

    final accountsResult = await _accountRepository.watchActiveAccounts().first;
    if (accountsResult case Left(value: final failure)) {
      return Left(failure);
    }
    final accounts = accountsResult.getOrElse(
      (_) => throw StateError('unreachable: accountsResult is Left'),
    );

    if (accounts.isEmpty) {
      return const Right(true);
    }

    final markResult = await _settingsRepository.markOnboardingCompleted();
    if (markResult case Left(value: final failure)) {
      return Left(failure);
    }
    return const Right(false);
  }
}
