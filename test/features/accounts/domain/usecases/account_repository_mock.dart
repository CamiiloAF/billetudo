import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_draft.dart';
import 'package:billetudo/features/accounts/domain/repositories/account_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

/// Registers the fallbacks mocktail needs for `any()` on custom types.
void registerAccountFallbacks() {
  registerFallbackValue(
    const AccountDraft(
      name: 'fallback',
      type: AccountType.bank,
      currency: 'COP',
    ),
  );
}
