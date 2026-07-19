// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:billetudo/core/bootstrap/first_launch_offline_cubit.dart'
    as _i101;
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
import 'package:billetudo/features/auth/data/datasources/local_data_ownership_datasource.dart'
    as _i718;
import 'package:billetudo/features/auth/data/datasources/local_data_summary_datasource.dart'
    as _i835;
import 'package:billetudo/features/auth/data/datasources/local_data_wipe_datasource.dart'
    as _i173;
import 'package:billetudo/features/auth/data/datasources/powersync_connector.dart'
    as _i872;
import 'package:billetudo/features/auth/data/datasources/seed_category_ownership_remote_datasource.dart'
    as _i226;
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
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart'
    as _i99;
import 'package:billetudo/features/budgets/data/repositories/budget_repository_impl.dart'
    as _i308;
import 'package:billetudo/features/budgets/domain/repositories/budget_repository.dart'
    as _i1023;
import 'package:billetudo/features/budgets/domain/services/budget_progress_calculator.dart'
    as _i685;
import 'package:billetudo/features/budgets/domain/services/zero_based_summary_calculator.dart'
    as _i529;
import 'package:billetudo/features/budgets/domain/usecases/close_budget.dart'
    as _i1008;
import 'package:billetudo/features/budgets/domain/usecases/create_budget.dart'
    as _i526;
import 'package:billetudo/features/budgets/domain/usecases/delete_budget.dart'
    as _i210;
import 'package:billetudo/features/budgets/domain/usecases/get_active_budgets.dart'
    as _i674;
import 'package:billetudo/features/budgets/domain/usecases/get_archived_budgets.dart'
    as _i829;
import 'package:billetudo/features/budgets/domain/usecases/get_budget_by_id.dart'
    as _i871;
import 'package:billetudo/features/budgets/domain/usecases/get_budget_progress.dart'
    as _i559;
import 'package:billetudo/features/budgets/domain/usecases/get_zero_based_summary.dart'
    as _i458;
import 'package:billetudo/features/budgets/domain/usecases/reactivate_budget.dart'
    as _i405;
import 'package:billetudo/features/budgets/domain/usecases/update_budget.dart'
    as _i857;
import 'package:billetudo/features/budgets/presentation/cubit/archived_budgets_cubit.dart'
    as _i635;
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_cubit.dart'
    as _i827;
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_cubit.dart'
    as _i759;
import 'package:billetudo/features/budgets/presentation/cubit/budgets_list_cubit.dart'
    as _i244;
import 'package:billetudo/features/budgets/presentation/cubit/zero_based_summary_cubit.dart'
    as _i843;
import 'package:billetudo/features/categories/data/datasources/categories_local_datasource.dart'
    as _i151;
import 'package:billetudo/features/categories/data/datasources/category_seeds_remote_datasource.dart'
    as _i180;
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
import 'package:billetudo/features/scheduled_payments/data/datasources/scheduled_payment_tags_local_datasource.dart'
    as _i276;
import 'package:billetudo/features/scheduled_payments/data/datasources/scheduled_payments_local_datasource.dart'
    as _i928;
import 'package:billetudo/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart'
    as _i9;
import 'package:billetudo/features/scheduled_payments/domain/repositories/scheduled_payment_repository.dart'
    as _i680;
import 'package:billetudo/features/scheduled_payments/domain/usecases/confirm_scheduled_occurrence.dart'
    as _i1034;
import 'package:billetudo/features/scheduled_payments/domain/usecases/create_scheduled_payment.dart'
    as _i242;
import 'package:billetudo/features/scheduled_payments/domain/usecases/create_tag.dart'
    as _i877;
import 'package:billetudo/features/scheduled_payments/domain/usecases/delete_scheduled_payment.dart'
    as _i636;
import 'package:billetudo/features/scheduled_payments/domain/usecases/generate_due_scheduled_payments.dart'
    as _i747;
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_finished_scheduled_payments.dart'
    as _i274;
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_pending_occurrences.dart'
    as _i551;
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payment_detail.dart'
    as _i470;
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payment_history.dart'
    as _i49;
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payments.dart'
    as _i265;
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_tags.dart'
    as _i889;
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart'
    as _i450;
import 'package:billetudo/features/scheduled_payments/domain/usecases/set_scheduled_payment_tags.dart'
    as _i452;
import 'package:billetudo/features/scheduled_payments/domain/usecases/skip_scheduled_occurrence.dart'
    as _i97;
import 'package:billetudo/features/scheduled_payments/domain/usecases/snooze_scheduled_occurrence.dart'
    as _i1009;
import 'package:billetudo/features/scheduled_payments/domain/usecases/undo_skip_scheduled_occurrence.dart'
    as _i964;
import 'package:billetudo/features/scheduled_payments/domain/usecases/undo_snooze_scheduled_occurrence.dart'
    as _i319;
import 'package:billetudo/features/scheduled_payments/domain/usecases/update_scheduled_payment.dart'
    as _i843;
import 'package:billetudo/features/scheduled_payments/presentation/cubit/confirmation_sheet_cubit.dart'
    as _i385;
import 'package:billetudo/features/scheduled_payments/presentation/cubit/finished_scheduled_payments_cubit.dart'
    as _i878;
import 'package:billetudo/features/scheduled_payments/presentation/cubit/guided_review_cubit.dart'
    as _i414;
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_cubit.dart'
    as _i793;
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_cubit.dart'
    as _i11;
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_cubit.dart'
    as _i117;
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_tag_picker_cubit.dart'
    as _i824;
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payments_list_cubit.dart'
    as _i458;
import 'package:billetudo/features/scheduled_payments/presentation/cubit/snooze_sheet_cubit.dart'
    as _i504;
import 'package:billetudo/features/settings/data/datasources/app_settings_local_datasource.dart'
    as _i95;
import 'package:billetudo/features/settings/data/repositories/app_settings_repository_impl.dart'
    as _i733;
import 'package:billetudo/features/settings/domain/repositories/app_settings_repository.dart'
    as _i487;
import 'package:billetudo/features/settings/domain/usecases/get_app_settings.dart'
    as _i182;
import 'package:billetudo/features/settings/domain/usecases/set_zero_based_enabled.dart'
    as _i636;
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart'
    as _i270;
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
import 'package:powersync/powersync.dart' as _i433;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

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
    gh.factory<_i450.ProjectUpcomingOccurrences>(
        () => const _i450.ProjectUpcomingOccurrences());
    gh.factory<_i604.GetTransactionEditImpact>(
        () => const _i604.GetTransactionEditImpact());
    gh.factory<_i499.DateFilterCubit>(() => _i499.DateFilterCubit());
    gh.lazySingleton<_i433.PowerSyncDatabase>(
        () => registerModule.powerSyncDatabase());
    gh.lazySingleton<_i249.AppDatabase>(() => registerModule.appDatabase());
    gh.lazySingleton<_i558.FlutterSecureStorage>(
        () => registerModule.secureStorage());
    gh.lazySingleton<_i474.CrashReporter>(() => registerModule.crashReporter());
    gh.lazySingleton<_i454.SupabaseClient>(
        () => registerModule.supabaseClient());
    gh.lazySingleton<_i486.SecureClipboard>(() => _i486.SecureClipboard());
    gh.lazySingleton<_i731.MoneyFormatter>(() => const _i731.MoneyFormatter());
    gh.lazySingleton<_i22.AppleAuthDatasource>(
        () => _i22.AppleAuthDatasource());
    gh.lazySingleton<_i235.GoogleAuthDatasource>(
        () => _i235.GoogleAuthDatasource());
    gh.lazySingleton<_i685.BudgetProgressCalculator>(
        () => const _i685.BudgetProgressCalculator());
    gh.lazySingleton<_i529.ZeroBasedSummaryCalculator>(
        () => const _i529.ZeroBasedSummaryCalculator());
    gh.factory<_i559.GetBudgetProgress>(
        () => _i559.GetBudgetProgress(gh<_i685.BudgetProgressCalculator>()));
    gh.lazySingleton<_i872.PowerSyncConnector>(
        () => _i872.PowerSyncConnector(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i226.SeedCategoryOwnershipRemoteDatasource>(() =>
        _i226.SeedCategoryOwnershipRemoteDatasource(
            gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i180.CategorySeedsRemoteDatasource>(
        () => _i180.CategorySeedsRemoteDatasource(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i718.LocalDataOwnershipDatasource>(
        () => _i718.LocalDataOwnershipDatasource(
              gh<_i249.AppDatabase>(),
              gh<_i226.SeedCategoryOwnershipRemoteDatasource>(),
            ));
    gh.lazySingleton<_i1034.SecureStorageService>(
        () => _i1034.SecureStorageService(gh<_i558.FlutterSecureStorage>()));
    gh.lazySingleton<_i533.AccountsLocalDatasource>(
        () => _i533.AccountsLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i835.LocalDataSummaryDatasource>(
        () => _i835.LocalDataSummaryDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i173.LocalDataWipeDatasource>(
        () => _i173.LocalDataWipeDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i99.BudgetsLocalDatasource>(
        () => _i99.BudgetsLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i151.CategoriesLocalDatasource>(
        () => _i151.CategoriesLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i276.ScheduledPaymentTagsLocalDatasource>(() =>
        _i276.ScheduledPaymentTagsLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i928.ScheduledPaymentsLocalDatasource>(
        () => _i928.ScheduledPaymentsLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i95.AppSettingsLocalDatasource>(
        () => _i95.AppSettingsLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i1008.TagsLocalDatasource>(
        () => _i1008.TagsLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i556.TransactionsLocalDatasource>(
        () => _i556.TransactionsLocalDatasource(gh<_i249.AppDatabase>()));
    gh.lazySingleton<_i654.TransactionRepository>(
        () => _i10.TransactionRepositoryImpl(
              gh<_i556.TransactionsLocalDatasource>(),
              gh<_i1008.TagsLocalDatasource>(),
            ));
    gh.lazySingleton<_i1023.BudgetRepository>(() => _i308.BudgetRepositoryImpl(
          gh<_i99.BudgetsLocalDatasource>(),
          gh<_i685.BudgetProgressCalculator>(),
          gh<_i529.ZeroBasedSummaryCalculator>(),
        ));
    gh.factory<_i1008.CloseBudget>(
        () => _i1008.CloseBudget(gh<_i1023.BudgetRepository>()));
    gh.factory<_i526.CreateBudget>(
        () => _i526.CreateBudget(gh<_i1023.BudgetRepository>()));
    gh.factory<_i210.DeleteBudget>(
        () => _i210.DeleteBudget(gh<_i1023.BudgetRepository>()));
    gh.factory<_i674.GetActiveBudgets>(
        () => _i674.GetActiveBudgets(gh<_i1023.BudgetRepository>()));
    gh.factory<_i829.GetArchivedBudgets>(
        () => _i829.GetArchivedBudgets(gh<_i1023.BudgetRepository>()));
    gh.factory<_i871.GetBudgetById>(
        () => _i871.GetBudgetById(gh<_i1023.BudgetRepository>()));
    gh.factory<_i458.GetZeroBasedSummary>(
        () => _i458.GetZeroBasedSummary(gh<_i1023.BudgetRepository>()));
    gh.factory<_i405.ReactivateBudget>(
        () => _i405.ReactivateBudget(gh<_i1023.BudgetRepository>()));
    gh.factory<_i857.UpdateBudget>(
        () => _i857.UpdateBudget(gh<_i1023.BudgetRepository>()));
    gh.lazySingleton<_i612.AccountNumberLocalDatasource>(() =>
        _i612.AccountNumberLocalDatasource(gh<_i1034.SecureStorageService>()));
    gh.lazySingleton<_i1067.AccountRepository>(
        () => _i304.AccountRepositoryImpl(
              gh<_i533.AccountsLocalDatasource>(),
              gh<_i612.AccountNumberLocalDatasource>(),
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
    gh.factory<_i759.BudgetFormCubit>(() => _i759.BudgetFormCubit(
          gh<_i526.CreateBudget>(),
          gh<_i857.UpdateBudget>(),
          gh<_i871.GetBudgetById>(),
        ));
    gh.lazySingleton<_i913.AuthRepository>(() => _i13.AuthRepositoryImpl(
          gh<_i235.GoogleAuthDatasource>(),
          gh<_i22.AppleAuthDatasource>(),
          gh<_i835.LocalDataSummaryDatasource>(),
          gh<_i173.LocalDataWipeDatasource>(),
          gh<_i718.LocalDataOwnershipDatasource>(),
          gh<_i454.SupabaseClient>(),
          gh<_i433.PowerSyncDatabase>(),
          gh<_i872.PowerSyncConnector>(),
        ));
    gh.lazySingleton<_i716.TagRepository>(
        () => _i672.TagRepositoryImpl(gh<_i1008.TagsLocalDatasource>()));
    gh.lazySingleton<_i802.CategoryRepository>(
        () => _i983.CategoryRepositoryImpl(
              gh<_i151.CategoriesLocalDatasource>(),
              gh<_i180.CategorySeedsRemoteDatasource>(),
            ));
    gh.factory<_i281.CreateTag>(
        () => _i281.CreateTag(gh<_i716.TagRepository>()));
    gh.factory<_i121.WatchTags>(
        () => _i121.WatchTags(gh<_i716.TagRepository>()));
    gh.factory<_i774.TransactionDetailCubit>(() => _i774.TransactionDetailCubit(
          gh<_i276.WatchTransactionDetail>(),
          gh<_i612.DeleteTransaction>(),
        ));
    gh.lazySingleton<_i487.AppSettingsRepository>(() =>
        _i733.AppSettingsRepositoryImpl(gh<_i95.AppSettingsLocalDatasource>()));
    gh.lazySingleton<_i680.ScheduledPaymentRepository>(
        () => _i9.ScheduledPaymentRepositoryImpl(
              gh<_i928.ScheduledPaymentsLocalDatasource>(),
              gh<_i276.ScheduledPaymentTagsLocalDatasource>(),
            ));
    gh.factory<_i635.ArchivedBudgetsCubit>(() => _i635.ArchivedBudgetsCubit(
          gh<_i829.GetArchivedBudgets>(),
          gh<_i405.ReactivateBudget>(),
        ));
    gh.factory<_i182.GetAppSettings>(
        () => _i182.GetAppSettings(gh<_i487.AppSettingsRepository>()));
    gh.factory<_i636.SetZeroBasedEnabled>(
        () => _i636.SetZeroBasedEnabled(gh<_i487.AppSettingsRepository>()));
    gh.factory<_i270.AppSettingsCubit>(() => _i270.AppSettingsCubit(
          gh<_i182.GetAppSettings>(),
          gh<_i636.SetZeroBasedEnabled>(),
        ));
    gh.factory<_i843.ZeroBasedSummaryCubit>(
        () => _i843.ZeroBasedSummaryCubit(gh<_i458.GetZeroBasedSummary>()));
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
    gh.factory<_i693.SeedDefaultCategories>(() => _i693.SeedDefaultCategories(
          gh<_i802.CategoryRepository>(),
          gh<_i487.AppSettingsRepository>(),
        ));
    gh.factory<_i244.BudgetsListCubit>(
        () => _i244.BudgetsListCubit(gh<_i674.GetActiveBudgets>()));
    gh.factory<_i827.BudgetDetailCubit>(() => _i827.BudgetDetailCubit(
          gh<_i871.GetBudgetById>(),
          gh<_i559.GetBudgetProgress>(),
          gh<_i1008.CloseBudget>(),
          gh<_i210.DeleteBudget>(),
        ));
    gh.factory<_i722.AccountFilterCubit>(
        () => _i722.AccountFilterCubit(gh<_i837.WatchAccounts>()));
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
    gh.factory<_i101.FirstLaunchOfflineCubit>(
        () => _i101.FirstLaunchOfflineCubit(gh<_i693.SeedDefaultCategories>()));
    gh.factory<_i1034.ConfirmScheduledOccurrence>(() =>
        _i1034.ConfirmScheduledOccurrence(
            gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i242.CreateScheduledPayment>(() =>
        _i242.CreateScheduledPayment(gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i877.CreateTag>(
        () => _i877.CreateTag(gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i636.DeleteScheduledPayment>(() =>
        _i636.DeleteScheduledPayment(gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i747.GenerateDueScheduledPayments>(() =>
        _i747.GenerateDueScheduledPayments(
            gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i274.GetFinishedScheduledPayments>(() =>
        _i274.GetFinishedScheduledPayments(
            gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i551.GetPendingOccurrences>(() =>
        _i551.GetPendingOccurrences(gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i470.GetScheduledPaymentDetail>(() =>
        _i470.GetScheduledPaymentDetail(
            gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i49.GetScheduledPaymentHistory>(() =>
        _i49.GetScheduledPaymentHistory(
            gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i265.GetScheduledPayments>(() =>
        _i265.GetScheduledPayments(gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i889.GetTags>(
        () => _i889.GetTags(gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i452.SetScheduledPaymentTags>(() =>
        _i452.SetScheduledPaymentTags(gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i97.SkipScheduledOccurrence>(() =>
        _i97.SkipScheduledOccurrence(gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i1009.SnoozeScheduledOccurrence>(() =>
        _i1009.SnoozeScheduledOccurrence(
            gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i964.UndoSkipScheduledOccurrence>(() =>
        _i964.UndoSkipScheduledOccurrence(
            gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i319.UndoSnoozeScheduledOccurrence>(() =>
        _i319.UndoSnoozeScheduledOccurrence(
            gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i843.UpdateScheduledPayment>(() =>
        _i843.UpdateScheduledPayment(gh<_i680.ScheduledPaymentRepository>()));
    gh.factory<_i504.SnoozeSheetCubit>(
        () => _i504.SnoozeSheetCubit(gh<_i1009.SnoozeScheduledOccurrence>()));
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
    gh.factory<_i824.ScheduledPaymentTagPickerCubit>(
        () => _i824.ScheduledPaymentTagPickerCubit(
              gh<_i889.GetTags>(),
              gh<_i877.CreateTag>(),
            ));
    gh.factory<_i117.ScheduledPaymentFormCubit>(
        () => _i117.ScheduledPaymentFormCubit(
              gh<_i242.CreateScheduledPayment>(),
              gh<_i843.UpdateScheduledPayment>(),
              gh<_i470.GetScheduledPaymentDetail>(),
              gh<_i452.SetScheduledPaymentTags>(),
              gh<_i636.DeleteScheduledPayment>(),
            ));
    gh.factory<_i793.PendingOccurrencesCubit>(
        () => _i793.PendingOccurrencesCubit(
              gh<_i551.GetPendingOccurrences>(),
              gh<_i964.UndoSkipScheduledOccurrence>(),
              gh<_i319.UndoSnoozeScheduledOccurrence>(),
            ));
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
    gh.factory<_i304.CategoryQuickPickerCubit>(
        () => _i304.CategoryQuickPickerCubit(
              gh<_i415.GetMostUsedCategories>(),
              gh<_i382.GetCategory>(),
            ));
    gh.factory<_i489.MergeCubit>(
        () => _i489.MergeCubit(gh<_i916.MergeLocalData>()));
    gh.factory<_i536.TransactionsListCubit>(() => _i536.TransactionsListCubit(
          gh<_i832.WatchTransactions>(),
          gh<_i612.DeleteTransaction>(),
          gh<_i177.RestoreTransaction>(),
          gh<_i837.WatchAccounts>(),
        ));
    gh.factory<_i502.AccountDetailCubit>(() => _i502.AccountDetailCubit(
          gh<_i325.WatchAccountDetail>(),
          gh<_i306.GetAccountNumber>(),
          gh<_i574.SetCardBalancePrimary>(),
          gh<_i807.GetAccountDeletionImpact>(),
          gh<_i79.ArchiveAccount>(),
          gh<_i574.DeleteAccount>(),
          gh<_i486.SecureClipboard>(),
        ));
    gh.factory<_i724.TransactionFormCubit>(() => _i724.TransactionFormCubit(
          gh<_i990.CreateTransaction>(),
          gh<_i885.UpdateTransaction>(),
          gh<_i276.WatchTransactionDetail>(),
          gh<_i604.GetTransactionEditImpact>(),
          gh<_i460.SetTransactionTags>(),
          gh<_i837.WatchAccounts>(),
        ));
    gh.factory<_i878.FinishedScheduledPaymentsCubit>(() =>
        _i878.FinishedScheduledPaymentsCubit(
            gh<_i274.GetFinishedScheduledPayments>()));
    gh.factory<_i531.AccountsListCubit>(() => _i531.AccountsListCubit(
          gh<_i837.WatchAccounts>(),
          gh<_i902.WatchAccountsOverview>(),
          gh<_i787.ReorderAccounts>(),
        ));
    gh.factory<_i140.DeleteAccountCubit>(() => _i140.DeleteAccountCubit(
          gh<_i498.DeleteAccount>(),
          gh<_i537.WipeLocalData>(),
        ));
    gh.factory<_i11.ScheduledPaymentDetailCubit>(
        () => _i11.ScheduledPaymentDetailCubit(
              gh<_i470.GetScheduledPaymentDetail>(),
              gh<_i49.GetScheduledPaymentHistory>(),
              gh<_i636.DeleteScheduledPayment>(),
              gh<_i319.UndoSnoozeScheduledOccurrence>(),
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
    gh.factory<_i458.ScheduledPaymentsListCubit>(
        () => _i458.ScheduledPaymentsListCubit(
              gh<_i265.GetScheduledPayments>(),
              gh<_i747.GenerateDueScheduledPayments>(),
              gh<_i274.GetFinishedScheduledPayments>(),
            ));
    gh.factory<_i141.ParentCategoryPickerCubit>(
        () => _i141.ParentCategoryPickerCubit(
              gh<_i172.WatchParentCandidates>(),
              gh<_i722.WatchCategories>(),
            ));
    gh.factory<_i385.ConfirmationSheetCubit>(() => _i385.ConfirmationSheetCubit(
          gh<_i1034.ConfirmScheduledOccurrence>(),
          gh<_i97.SkipScheduledOccurrence>(),
          gh<_i1009.SnoozeScheduledOccurrence>(),
        ));
    gh.factory<_i414.GuidedReviewCubit>(() => _i414.GuidedReviewCubit(
          gh<_i1034.ConfirmScheduledOccurrence>(),
          gh<_i97.SkipScheduledOccurrence>(),
          gh<_i1009.SnoozeScheduledOccurrence>(),
        ));
    gh.singleton<_i629.AuthCubit>(() => _i629.AuthCubit(
          gh<_i716.WatchAuthSession>(),
          gh<_i1066.SignOut>(),
        ));
    gh.factory<_i99.CategoryFormCubit>(() => _i99.CategoryFormCubit(
          gh<_i885.CreateCategory>(),
          gh<_i275.UpdateCategory>(),
          gh<_i382.GetCategory>(),
          gh<_i87.GetCategoryDeletionImpact>(),
          gh<_i968.DeleteCategory>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i77.RegisterModule {}
