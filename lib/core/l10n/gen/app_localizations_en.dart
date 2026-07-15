// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Billetudo';

  @override
  String get bootstrapReady =>
      'Technical foundation ready. Screens arrive with each feature.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRetry => 'Retry';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get errorDatabase =>
      'We couldn\'t save your changes. Please try again.';

  @override
  String get errorSecureStorage =>
      'We couldn\'t access the device\'s secure storage.';
}
