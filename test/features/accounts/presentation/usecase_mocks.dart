import 'package:billetudo/core/security/secure_clipboard.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_draft.dart';
import 'package:billetudo/features/accounts/domain/usecases/archive_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/create_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/delete_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/get_account_deletion_impact.dart';
import 'package:billetudo/features/accounts/domain/usecases/get_account_number.dart';
import 'package:billetudo/features/accounts/domain/usecases/reorder_accounts.dart';
import 'package:billetudo/features/accounts/domain/usecases/set_card_balance_primary.dart';
import 'package:billetudo/features/accounts/domain/usecases/unarchive_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/update_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_account_detail.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts_overview.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_archived_accounts.dart';
import 'package:mocktail/mocktail.dart';

/// The cubits only ever talk to use cases, so these are the only seams the
/// presentation tests need. Mocking the repository here instead would test a
/// dependency the cubits are not allowed to have.
class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockWatchAccountsOverview extends Mock implements WatchAccountsOverview {}

class MockWatchArchivedAccounts extends Mock implements WatchArchivedAccounts {}

class MockWatchAccountDetail extends Mock implements WatchAccountDetail {}

class MockReorderAccounts extends Mock implements ReorderAccounts {}

class MockCreateAccount extends Mock implements CreateAccount {}

class MockUpdateAccount extends Mock implements UpdateAccount {}

class MockArchiveAccount extends Mock implements ArchiveAccount {}

class MockUnarchiveAccount extends Mock implements UnarchiveAccount {}

class MockDeleteAccount extends Mock implements DeleteAccount {}

class MockGetAccountDeletionImpact extends Mock
    implements GetAccountDeletionImpact {}

class MockGetAccountNumber extends Mock implements GetAccountNumber {}

class MockSetCardBalancePrimary extends Mock implements SetCardBalancePrimary {}

class MockSecureClipboard extends Mock implements SecureClipboard {}

/// Fallbacks mocktail needs for `any()` on the feature's own types.
void registerPresentationFallbacks() {
  registerFallbackValue(
    const AccountDraft(
      name: 'fallback',
      type: AccountType.bank,
      currency: 'COP',
    ),
  );
  registerFallbackValue(CardBalanceView.debt);
}
