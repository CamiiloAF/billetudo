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
    gh.lazySingleton<_i249.AppDatabase>(() => registerModule.appDatabase());
    gh.lazySingleton<_i558.FlutterSecureStorage>(
        () => registerModule.secureStorage());
    gh.lazySingleton<_i474.CrashReporter>(() => registerModule.crashReporter());
    gh.lazySingleton<_i486.SecureClipboard>(() => _i486.SecureClipboard());
    gh.lazySingleton<_i731.MoneyFormatter>(() => const _i731.MoneyFormatter());
    gh.lazySingleton<_i1034.SecureStorageService>(
        () => _i1034.SecureStorageService(gh<_i558.FlutterSecureStorage>()));
    return this;
  }
}

class _$RegisterModule extends _i77.RegisterModule {}
