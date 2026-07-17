// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:billetudo/core/crash/crash_reporter.dart' as _i474;
import 'package:billetudo/core/database/app_database.dart' as _i249;
import 'package:billetudo/core/di/register_module.dart' as _i77;
import 'package:billetudo/core/security/secure_clipboard.dart' as _i486;
import 'package:billetudo/core/security/secure_storage_service.dart' as _i1034;
import 'package:billetudo/core/utils/money_formatter.dart' as _i731;
import 'package:billetudo/features/accounts/data/datasources/account_number_local_datasource.dart'
    as _i612;
import 'package:billetudo/features/accounts/data/datasources/accounts_local_datasource.dart'
    as _i533;
import 'package:billetudo/features/accounts/data/repositories/account_repository_impl.dart'
    as _i304;
import 'package:billetudo/features/accounts/domain/repositories/account_repository.dart'
    as _i1067;
import 'package:billetudo/features/accounts/domain/usecases/archive_account.dart'
    as _i79;
import 'package:billetudo/features/accounts/domain/usecases/create_account.dart'
    as _i703;
import 'package:billetudo/features/accounts/domain/usecases/delete_account.dart'
    as _i574;
import 'package:billetudo/features/accounts/domain/usecases/get_account_deletion_impact.dart'
    as _i807;
import 'package:billetudo/features/accounts/domain/usecases/get_account_number.dart'
    as _i306;
import 'package:billetudo/features/accounts/domain/usecases/reorder_accounts.dart'
    as _i787;
import 'package:billetudo/features/accounts/domain/usecases/set_card_balance_primary.dart'
    as _i574;
import 'package:billetudo/features/accounts/domain/usecases/unarchive_account.dart'
    as _i536;
import 'package:billetudo/features/accounts/domain/usecases/update_account.dart'
    as _i724;
import 'package:billetudo/features/accounts/domain/usecases/watch_account_detail.dart'
    as _i325;
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart'
    as _i837;
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts_overview.dart'
    as _i902;
import 'package:billetudo/features/accounts/domain/usecases/watch_archived_accounts.dart'
    as _i545;
import 'package:billetudo/features/accounts/presentation/cubit/account_detail_cubit.dart'
    as _i502;
import 'package:billetudo/features/accounts/presentation/cubit/account_form_cubit.dart'
    as _i1070;
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_cubit.dart'
    as _i531;
import 'package:billetudo/features/accounts/presentation/cubit/archived_accounts_cubit.dart'
    as _i958;
import 'package:billetudo/features/auth/data/datasources/apple_auth_datasource.dart'
    as _i22;
import 'package:billetudo/features/auth/data/datasources/google_auth_datasource.dart'
    as _i235;
import 'package:billetudo/features/auth/data/datasources/local_data_summary_datasource.dart'
    as _i835;
import 'package:billetudo/features/auth/data/datasources/local_data_wipe_datasource.dart'
    as _i173;
import 'package:billetudo/features/auth/data/repositories/auth_repository_impl.dart'
    as _i13;
import 'package:billetudo/features/auth/domain/repositories/auth_repository.dart'
    as _i913;
import 'package:billetudo/features/auth/domain/usecases/delete_account.dart'
    as _i498;
import 'package:billetudo/features/auth/domain/usecases/merge_local_data.dart'
    as _i916;
import 'package:billetudo/features/auth/domain/usecases/sign_in_with_apple.dart'
    as _i888;
import 'package:billetudo/features/auth/domain/usecases/sign_in_with_google.dart'
    as _i1044;
import 'package:billetudo/features/auth/domain/usecases/sign_out.dart'
    as _i1066;
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart'
    as _i716;
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data.dart'
    as _i537;
import 'package:billetudo/features/auth/presentation/cubit/auth_cubit.dart'
    as _i629;
import 'package:billetudo/features/auth/presentation/cubit/delete_account_cubit.dart'
    as _i140;
import 'package:billetudo/features/auth/presentation/cubit/login_cubit.dart'
    as _i271;
import 'package:billetudo/features/auth/presentation/cubit/merge_cubit.dart'
    as _i489;
import 'package:billetudo/features/categories/data/datasources/categories_local_datasource.dart'
    as _i151;
import 'package:billetudo/features/categories/data/repositories/category_repository_impl.dart'
    as _i983;
import 'package:billetudo/features/categories/domain/repositories/category_repository.dart'
    as _i802;
import 'package:billetudo/features/categories/domain/usecases/create_category.dart'
    as _i885;
import 'package:billetudo/features/categories/domain/usecases/delete_category.dart'
    as _i968;
import 'package:billetudo/features/categories/domain/usecases/get_category.dart'
    as _i382;
import 'package:billetudo/features/categories/domain/usecases/get_category_deletion_impact.dart'
    as _i87;
import 'package:billetudo/features/categories/domain/usecases/get_most_used_categories.dart'
    as _i415;
import 'package:billetudo/features/categories/domain/usecases/reorder_categories.dart'
    as _i562;
import 'package:billetudo/features/categories/domain/usecases/restore_category.dart'
    as _i119;
import 'package:billetudo/features/categories/domain/usecases/seed_default_categories.dart'
    as _i693;
import 'package:billetudo/features/categories/domain/usecases/update_category.dart'
    as _i275;
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart'
    as _i722;
import 'package:billetudo/features/categories/domain/usecases/watch_parent_candidates.dart'
    as _i172;
import 'package:billetudo/features/categories/presentation/cubit/categories_list_cubit.dart'
    as _i335;
import 'package:billetudo/features/categories/presentation/cubit/category_form_cubit.dart'
    as _i99;
import 'package:billetudo/features/categories/presentation/cubit/parent_category_picker_cubit.dart'
    as _i141;
import 'package:billetudo/features/home/domain/usecases/watch_month_transactions.dart'
    as _i426;
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart'
    as _i199;
import 'package:billetudo/features/transactions/data/datasources/tags_local_datasource.dart'
    as _i1008;
import 'package:billetudo/features/transactions/data/datasources/transactions_local_datasource.dart'
    as _i556;
import 'package:billetudo/features/transactions/data/repositories/tag_repository_impl.dart'
    as _i672;
import 'package:billetudo/features/transactions/data/repositories/transaction_repository_impl.dart'
    as _i10;
import 'package:billetudo/features/transactions/domain/repositories/tag_repository.dart'
    as _i716;
import 'package:billetudo/features/transactions/domain/repositories/transaction_repository.dart'
    as _i654;
import 'package:billetudo/features/transactions/domain/usecases/create_tag.dart'
    as _i281;
import 'package:billetudo/features/transactions/domain/usecases/create_transaction.dart'
    as _i990;
import 'package:billetudo/features/transactions/domain/usecases/delete_transaction.dart'
    as _i612;
import 'package:billetudo/features/transactions/domain/usecases/get_transaction_edit_impact.dart'
    as _i604;
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart'
    as _i177;
import 'package:billetudo/features/transactions/domain/usecases/set_transaction_tags.dart'
    as _i460;
import 'package:billetudo/features/transactions/domain/usecases/update_transaction.dart'
    as _i885;
import 'package:billetudo/features/transactions/domain/usecases/watch_tags.dart'
    as _i121;
import 'package:billetudo/features/transactions/domain/usecases/watch_transaction_detail.dart'
    as _i276;
import 'package:billetudo/features/transactions/domain/usecases/watch_transactions.dart'
    as _i832;
import 'package:billetudo/features/transactions/presentation/cubit/account_filter_cubit.dart'
    as _i722;
import 'package:billetudo/features/transactions/presentation/cubit/category_filter_cubit.dart'
    as _i315;
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart'
    as _i304;
import 'package:billetudo/features/transactions/presentation/cubit/date_filter_cubit.dart'
    as _i499;
import 'package:billetudo/features/transactions/presentation/cubit/tag_filter_cubit.dart'
    as _i506;
import 'package:billetudo/features/transactions/presentation/cubit/transaction_detail_cubit.dart'
    as _i774;
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_cubit.dart'
    as _i724;
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart'
    as _i536;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.factory<_i604.GetTransactionEditImpact>(
        () => const _i604.GetTransactionEditImpact());
    gh.factory<_i499.DateFilterCubit>(() => _i499.DateFilterCubit());
    gh.lazySingleton<_i249.AppDatabase>(() => registerModule.appDatabase());
    gh.lazySingleton<_i558.FlutterSecureStorage>(
        () => registerModule.secureStorage());
    gh.lazySingleton<_i474.CrashReporter>(() => registerModule.crashReporter());
    gh.lazySingleton<_i486.SecureClipboard>(() => _i486.SecureClipboard());
    gh.lazySingleton<_i731.MoneyFormatter>(() => const _i731.MoneyFormatter());
    gh.lazySingleton<_i22.AppleAuthDatasource>(
        () => _i22.AppleAuthDatasource());
    gh.lazySingleton<_i235.GoogleAuthDatasource>(
        () => _i235.GoogleAuthDatasource());
    gh.lazySingleton<_i1034.SecureStorageService>(
        () => _i1034.SecureStorageService(gh<_i558.FlutterSecureStorage>()));
    gh.lazySingleton<_i533.AccountsLocalDatasource>(
        () => _i533.AccountsLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i835.LocalDataSummaryDatasource>(
        () => _i835.LocalDataSummaryDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i173.LocalDataWipeDatasource>(
        () => _i173.LocalDataWipeDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i151.CategoriesLocalDatasource>(
        () => _i151.CategoriesLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i1008.TagsLocalDatasource>(
        () => _i1008.TagsLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i556.TransactionsLocalDatasource>(
        () => _i556.TransactionsLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i654.TransactionRepository>(
        () => _i10.TransactionRepositoryImpl(
              gh<_i556.TransactionsLocalDatasource>(),
              gh<_i1008.TagsLocalDatasource>(),
            ));
    gh.lazySingleton<_i612.AccountNumberLocalDatasource>(() =>
        _i612.AccountNumberLocalDatasource(gh<_i1034.SecureStorageService>()));
    gh.lazySingleton<_i1067.AccountRepository>(
        () => _i304.AccountRepositoryImpl(
              gh<_i533.AccountsLocalDatasource>(),
              gh<_i612.AccountNumberLocalDatasource>(),
            ));
    gh.lazySingleton<_i913.AuthRepository>(() => _i13.AuthRepositoryImpl(
          gh<_i235.GoogleAuthDatasource>(),
          gh<_i22.AppleAuthDatasource>(),
          gh<_i835.LocalDataSummaryDatasource>(),
          gh<_i173.LocalDataWipeDatasource>(),
        ));
    gh.factory<_i426.WatchMonthTransactions>(
        () => _i426.WatchMonthTransactions(gh<_i654.TransactionRepository>()));
    gh.factory<_i990.CreateTransaction>(
        () => _i990.CreateTransaction(gh<_i654.TransactionRepository>()));
    gh.factory<_i612.DeleteTransaction>(
        () => _i612.DeleteTransaction(gh<_i654.TransactionRepository>()));
    gh.factory<_i177.RestoreTransaction>(
        () => _i177.RestoreTransaction(gh<_i654.TransactionRepository>()));
    gh.factory<_i460.SetTransactionTags>(
        () => _i460.SetTransactionTags(gh<_i654.TransactionRepository>()));
    gh.factory<_i885.UpdateTransaction>(
        () => _i885.UpdateTransaction(gh<_i654.TransactionRepository>()));
    gh.factory<_i276.WatchTransactionDetail>(
        () => _i276.WatchTransactionDetail(gh<_i654.TransactionRepository>()));
    gh.factory<_i832.WatchTransactions>(
        () => _i832.WatchTransactions(gh<_i654.TransactionRepository>()));
    gh.lazySingleton<_i802.CategoryRepository>(() =>
        _i983.CategoryRepositoryImpl(gh<_i151.CategoriesLocalDatasource>()));
    gh.factory<_i885.CreateCategory>(
        () => _i885.CreateCategory(gh<_i802.CategoryRepository>()));
    gh.factory<_i968.DeleteCategory>(
        () => _i968.DeleteCategory(gh<_i802.CategoryRepository>()));
    gh.factory<_i382.GetCategory>(
        () => _i382.GetCategory(gh<_i802.CategoryRepository>()));
    gh.factory<_i87.GetCategoryDeletionImpact>(
        () => _i87.GetCategoryDeletionImpact(gh<_i802.CategoryRepository>()));
    gh.factory<_i415.GetMostUsedCategories>(
        () => _i415.GetMostUsedCategories(gh<_i802.CategoryRepository>()));
    gh.factory<_i562.ReorderCategories>(
        () => _i562.ReorderCategories(gh<_i802.CategoryRepository>()));
    gh.factory<_i119.RestoreCategory>(
        () => _i119.RestoreCategory(gh<_i802.CategoryRepository>()));
    gh.factory<_i693.SeedDefaultCategories>(
        () => _i693.SeedDefaultCategories(gh<_i802.CategoryRepository>()));
    gh.factory<_i275.UpdateCategory>(
        () => _i275.UpdateCategory(gh<_i802.CategoryRepository>()));
    gh.factory<_i722.WatchCategories>(
        () => _i722.WatchCategories(gh<_i802.CategoryRepository>()));
    gh.factory<_i172.WatchParentCandidates>(
        () => _i172.WatchParentCandidates(gh<_i802.CategoryRepository>()));
    gh.factory<_i335.CategoriesListCubit>(() => _i335.CategoriesListCubit(
          gh<_i722.WatchCategories>(),
          gh<_i562.ReorderCategories>(),
        ));
    gh.factory<_i315.CategoryFilterCubit>(
        () => _i315.CategoryFilterCubit(gh<_i722.WatchCategories>()));
    gh.lazySingleton<_i716.TagRepository>(
        () => _i672.TagRepositoryImpl(gh<_i1008.TagsLocalDatasource>()));
    gh.factory<_i304.CategoryQuickPickerCubit>(
        () => _i304.CategoryQuickPickerCubit(
              gh<_i415.GetMostUsedCategories>(),
              gh<_i382.GetCategory>(),
            ));
    gh.factory<_i281.CreateTag>(
        () => _i281.CreateTag(gh<_i716.TagRepository>()));
    gh.factory<_i121.WatchTags>(
        () => _i121.WatchTags(gh<_i716.TagRepository>()));
    gh.factory<_i774.TransactionDetailCubit>(() => _i774.TransactionDetailCubit(
          gh<_i276.WatchTransactionDetail>(),
          gh<_i612.DeleteTransaction>(),
        ));
    gh.factory<_i79.ArchiveAccount>(
        () => _i79.ArchiveAccount(gh<_i1067.AccountRepository>()));
    gh.factory<_i703.CreateAccount>(
        () => _i703.CreateAccount(gh<_i1067.AccountRepository>()));
    gh.factory<_i574.DeleteAccount>(
        () => _i574.DeleteAccount(gh<_i1067.AccountRepository>()));
    gh.factory<_i807.GetAccountDeletionImpact>(
        () => _i807.GetAccountDeletionImpact(gh<_i1067.AccountRepository>()));
    gh.factory<_i306.GetAccountNumber>(
        () => _i306.GetAccountNumber(gh<_i1067.AccountRepository>()));
    gh.factory<_i787.ReorderAccounts>(
        () => _i787.ReorderAccounts(gh<_i1067.AccountRepository>()));
    gh.factory<_i574.SetCardBalancePrimary>(
        () => _i574.SetCardBalancePrimary(gh<_i1067.AccountRepository>()));
    gh.factory<_i536.UnarchiveAccount>(
        () => _i536.UnarchiveAccount(gh<_i1067.AccountRepository>()));
    gh.factory<_i724.UpdateAccount>(
        () => _i724.UpdateAccount(gh<_i1067.AccountRepository>()));
    gh.factory<_i325.WatchAccountDetail>(
        () => _i325.WatchAccountDetail(gh<_i1067.AccountRepository>()));
    gh.factory<_i837.WatchAccounts>(
        () => _i837.WatchAccounts(gh<_i1067.AccountRepository>()));
    gh.factory<_i902.WatchAccountsOverview>(
        () => _i902.WatchAccountsOverview(gh<_i1067.AccountRepository>()));
    gh.factory<_i545.WatchArchivedAccounts>(
        () => _i545.WatchArchivedAccounts(gh<_i1067.AccountRepository>()));
    gh.factory<_i506.TagFilterCubit>(() => _i506.TagFilterCubit(
          gh<_i121.WatchTags>(),
          gh<_i281.CreateTag>(),
        ));
    gh.factory<_i724.TransactionFormCubit>(() => _i724.TransactionFormCubit(
          gh<_i990.CreateTransaction>(),
          gh<_i885.UpdateTransaction>(),
          gh<_i276.WatchTransactionDetail>(),
          gh<_i604.GetTransactionEditImpact>(),
          gh<_i460.SetTransactionTags>(),
        ));
    gh.factory<_i722.AccountFilterCubit>(
        () => _i722.AccountFilterCubit(gh<_i837.WatchAccounts>()));
    gh.factory<_i141.ParentCategoryPickerCubit>(
        () => _i141.ParentCategoryPickerCubit(
              gh<_i172.WatchParentCandidates>(),
              gh<_i722.WatchCategories>(),
            ));
    gh.factory<_i958.ArchivedAccountsCubit>(() => _i958.ArchivedAccountsCubit(
          gh<_i545.WatchArchivedAccounts>(),
          gh<_i536.UnarchiveAccount>(),
        ));
    gh.factory<_i1070.AccountFormCubit>(() => _i1070.AccountFormCubit(
          gh<_i703.CreateAccount>(),
          gh<_i724.UpdateAccount>(),
          gh<_i325.WatchAccountDetail>(),
          gh<_i306.GetAccountNumber>(),
          gh<_i731.MoneyFormatter>(),
        ));
    gh.factory<_i536.TransactionsListCubit>(() => _i536.TransactionsListCubit(
          gh<_i832.WatchTransactions>(),
          gh<_i612.DeleteTransaction>(),
          gh<_i177.RestoreTransaction>(),
        ));
    gh.factory<_i498.DeleteAccount>(
        () => _i498.DeleteAccount(gh<_i913.AuthRepository>()));
    gh.factory<_i916.MergeLocalData>(
        () => _i916.MergeLocalData(gh<_i913.AuthRepository>()));
    gh.factory<_i888.SignInWithApple>(
        () => _i888.SignInWithApple(gh<_i913.AuthRepository>()));
    gh.factory<_i1044.SignInWithGoogle>(
        () => _i1044.SignInWithGoogle(gh<_i913.AuthRepository>()));
    gh.factory<_i1066.SignOut>(
        () => _i1066.SignOut(gh<_i913.AuthRepository>()));
    gh.factory<_i716.WatchAuthSession>(
        () => _i716.WatchAuthSession(gh<_i913.AuthRepository>()));
    gh.factory<_i537.WipeLocalData>(
        () => _i537.WipeLocalData(gh<_i913.AuthRepository>()));
    gh.factory<_i99.CategoryFormCubit>(() => _i99.CategoryFormCubit(
          gh<_i885.CreateCategory>(),
          gh<_i275.UpdateCategory>(),
          gh<_i382.GetCategory>(),
          gh<_i87.GetCategoryDeletionImpact>(),
          gh<_i968.DeleteCategory>(),
        ));
    gh.factory<_i489.MergeCubit>(
        () => _i489.MergeCubit(gh<_i916.MergeLocalData>()));
    gh.factory<_i502.AccountDetailCubit>(() => _i502.AccountDetailCubit(
          gh<_i325.WatchAccountDetail>(),
          gh<_i306.GetAccountNumber>(),
          gh<_i574.SetCardBalancePrimary>(),
          gh<_i807.GetAccountDeletionImpact>(),
          gh<_i79.ArchiveAccount>(),
          gh<_i574.DeleteAccount>(),
          gh<_i486.SecureClipboard>(),
        ));
    gh.factory<_i531.AccountsListCubit>(() => _i531.AccountsListCubit(
          gh<_i837.WatchAccounts>(),
          gh<_i902.WatchAccountsOverview>(),
          gh<_i787.ReorderAccounts>(),
        ));
    gh.factory<_i140.DeleteAccountCubit>(() => _i140.DeleteAccountCubit(
          gh<_i498.DeleteAccount>(),
          gh<_i537.WipeLocalData>(),
        ));
    gh.factory<_i271.LoginCubit>(() => _i271.LoginCubit(
          gh<_i1044.SignInWithGoogle>(),
          gh<_i888.SignInWithApple>(),
        ));
    gh.factory<_i199.HomeCubit>(() => _i199.HomeCubit(
          gh<_i837.WatchAccounts>(),
          gh<_i426.WatchMonthTransactions>(),
          gh<_i716.WatchAuthSession>(),
        ));
    gh.singleton<_i629.AuthCubit>(() => _i629.AuthCubit(
          gh<_i716.WatchAuthSession>(),
          gh<_i1066.SignOut>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i77.RegisterModule {}
