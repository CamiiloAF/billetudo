// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Billetudo';

  @override
  String get bootstrapReady =>
      'Base técnica lista. Las pantallas llegan con cada feature.';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get errorUnexpected => 'Algo salió mal. Intenta de nuevo.';

  @override
  String get errorDatabase =>
      'No pudimos guardar los cambios. Intenta de nuevo.';

  @override
  String get errorSecureStorage =>
      'No pudimos acceder al almacenamiento seguro del dispositivo.';
}
