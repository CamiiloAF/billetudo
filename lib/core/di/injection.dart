import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

/// The app's dependency injection container.
///
/// Each feature registers its repositories (`@LazySingleton(as: XRepository)`),
/// use cases (`@injectable`) and cubits (`@injectable`) by annotation;
/// infrastructure dependencies are registered in `register_module.dart`.
/// The generated graph lives in `injection.config.dart` (build_runner).
final GetIt getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
