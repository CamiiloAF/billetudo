import 'package:billetudo/features/settings/domain/usecases/get_app_settings.dart';
import 'package:billetudo/features/settings/domain/usecases/set_zero_based_enabled.dart';
import 'package:mocktail/mocktail.dart';

/// The cubit only ever talks to use cases, so these are the only seams the
/// presentation test needs. Mocking the repository here instead would test a
/// dependency the cubit is not allowed to have.
class MockGetAppSettings extends Mock implements GetAppSettings {}

class MockSetZeroBasedEnabled extends Mock implements SetZeroBasedEnabled {}
