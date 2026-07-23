import 'package:billetudo/core/preferences/account_filter_preference_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late AccountFilterPreferenceDatasource datasource;

  setUp(() {
    // Swaps the real platform channel for an in-memory store — this is the
    // async counterpart of `SharedPreferences.setMockInitialValues`, which
    // only covers the legacy (non-async) API.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    datasource = AccountFilterPreferenceDatasource(SharedPreferencesAsync());
  });

  group('AccountFilterPreferenceDatasource', () {
    test(
        'readAccountIds() defaults to an empty set ("todas las cuentas") '
        'when nothing was saved', () async {
      expect(await datasource.readAccountIds(), isEmpty);
    });

    test('writeAccountIds() then readAccountIds() roundtrips the set',
        () async {
      await datasource.writeAccountIds({'acc-1', 'acc-2'});

      expect(await datasource.readAccountIds(), {'acc-1', 'acc-2'});
    });

    test(
        'writeAccountIds() with an empty set clears the saved key instead '
        'of storing an empty list', () async {
      await datasource.writeAccountIds({'acc-1'});
      expect(await datasource.readAccountIds(), {'acc-1'});

      await datasource.writeAccountIds(<String>{});

      expect(await datasource.readAccountIds(), isEmpty);
      // Confirms the key itself was removed, not just re-saved as an empty
      // list, per the datasource's "keep persisted state minimal" contract.
      expect(
        await SharedPreferencesAsync().getStringList(
          'movements_account_filter',
        ),
        isNull,
      );
    });

    test('a later write() overrides an earlier one', () async {
      await datasource.writeAccountIds({'acc-1'});
      await datasource.writeAccountIds({'acc-2', 'acc-3'});

      expect(await datasource.readAccountIds(), {'acc-2', 'acc-3'});
    });
  });
}
