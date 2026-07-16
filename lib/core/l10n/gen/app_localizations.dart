import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// Nombre visible de la app.
  ///
  /// In es, this message translates to:
  /// **'Billetudo'**
  String get appTitle;

  /// Placeholder de arranque, visible hasta que exista el shell real.
  ///
  /// In es, this message translates to:
  /// **'Base técnica lista. Las pantallas llegan con cada feature.'**
  String get bootstrapReady;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// Etiqueta accesible del botón atrás del Page Header.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get commonBack;

  /// Mensaje genérico para UnexpectedFailure.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal. Intenta de nuevo.'**
  String get errorUnexpected;

  /// No description provided for @errorDatabase.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar los cambios. Intenta de nuevo.'**
  String get errorDatabase;

  /// No description provided for @errorSecureStorage.
  ///
  /// In es, this message translates to:
  /// **'No pudimos acceder al almacenamiento seguro del dispositivo.'**
  String get errorSecureStorage;

  /// Título de la pantalla de listado de cuentas.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get accountsTitle;

  /// Acceso temporal a Cuentas desde el Hero de Inicio.
  ///
  /// In es, this message translates to:
  /// **'Ver mis cuentas'**
  String get accountsOpenAction;

  /// CTA para crear una cuenta (header + estado vacío).
  ///
  /// In es, this message translates to:
  /// **'Agregar cuenta'**
  String get accountsAdd;

  /// No description provided for @accountsTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Patrimonio total'**
  String get accountsTotalLabel;

  /// Sub-línea de deudas del Total Card. El monto llega ya formateado.
  ///
  /// In es, this message translates to:
  /// **'Deudas: -{amount}'**
  String accountsTotalDebtsLine(String amount);

  /// Estado vacío del listado. Tono neutral, nunca culpa al usuario.
  ///
  /// In es, this message translates to:
  /// **'Aún no has agregado ninguna cuenta'**
  String get accountsEmptyMessage;

  /// No description provided for @accountsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus cuentas'**
  String get accountsErrorTitle;

  /// Recordatorio local-first del estado de error.
  ///
  /// In es, this message translates to:
  /// **'Tus datos siguen guardados en tu dispositivo'**
  String get accountsErrorLocalFirst;

  /// No description provided for @accountsArchivedTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuentas archivadas'**
  String get accountsArchivedTitle;

  /// No description provided for @accountsArchivedEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Aún no has archivado ninguna cuenta'**
  String get accountsArchivedEmptyMessage;

  /// No description provided for @accountsUnarchive.
  ///
  /// In es, this message translates to:
  /// **'Desarchivar'**
  String get accountsUnarchive;

  /// Etiqueta accesible del estado de carga (skeletons).
  ///
  /// In es, this message translates to:
  /// **'Cargando tus cuentas'**
  String get accountsLoading;

  /// No description provided for @accountTypeCash.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In es, this message translates to:
  /// **'Banco'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta de crédito'**
  String get accountTypeCard;

  /// No description provided for @accountTypeSavings.
  ///
  /// In es, this message translates to:
  /// **'Ahorros'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeInvestment.
  ///
  /// In es, this message translates to:
  /// **'Inversión'**
  String get accountTypeInvestment;

  /// No description provided for @accountTypeOther.
  ///
  /// In es, this message translates to:
  /// **'Otra'**
  String get accountTypeOther;

  /// No description provided for @accountBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo actual'**
  String get accountBalanceLabel;

  /// No description provided for @accountAvailableCreditLabel.
  ///
  /// In es, this message translates to:
  /// **'Cupo disponible'**
  String get accountAvailableCreditLabel;

  /// No description provided for @accountDebtLabel.
  ///
  /// In es, this message translates to:
  /// **'Deuda actual'**
  String get accountDebtLabel;

  /// No description provided for @accountOverLimitBadge.
  ///
  /// In es, this message translates to:
  /// **'Sobrecupo'**
  String get accountOverLimitBadge;

  /// No description provided for @accountOverLimitCaption.
  ///
  /// In es, this message translates to:
  /// **'Excedido en {amount}'**
  String accountOverLimitCaption(String amount);

  /// No description provided for @accountCreditUsedCaption.
  ///
  /// In es, this message translates to:
  /// **'{used} de {limit} usado'**
  String accountCreditUsedCaption(String used, String limit);

  /// Etiqueta accesible de los dots del carrusel del Balance Card.
  ///
  /// In es, this message translates to:
  /// **'Página {index} de {total}'**
  String accountBalancePage(int index, int total);

  /// No description provided for @accountInfoInstitution.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get accountInfoInstitution;

  /// No description provided for @accountInfoType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get accountInfoType;

  /// No description provided for @accountInfoInterestRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de interés'**
  String get accountInfoInterestRate;

  /// No description provided for @accountInfoNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de cuenta'**
  String get accountInfoNumber;

  /// No description provided for @accountInfoStatementDay.
  ///
  /// In es, this message translates to:
  /// **'Día de corte'**
  String get accountInfoStatementDay;

  /// No description provided for @accountInfoPaymentDueDay.
  ///
  /// In es, this message translates to:
  /// **'Día de pago'**
  String get accountInfoPaymentDueDay;

  /// Tasa anual ya formateada desde puntos básicos (2450 -> 24,5).
  ///
  /// In es, this message translates to:
  /// **'{rate}%'**
  String accountInterestRateValue(String rate);

  /// No description provided for @accountDayOfMonthValue.
  ///
  /// In es, this message translates to:
  /// **'{day} de cada mes'**
  String accountDayOfMonthValue(int day);

  /// No description provided for @accountNumberMasked.
  ///
  /// In es, this message translates to:
  /// **'•••• {last4}'**
  String accountNumberMasked(String last4);

  /// No description provided for @accountNumberReveal.
  ///
  /// In es, this message translates to:
  /// **'Mostrar número'**
  String get accountNumberReveal;

  /// No description provided for @accountNumberHide.
  ///
  /// In es, this message translates to:
  /// **'Ocultar número'**
  String get accountNumberHide;

  /// No description provided for @accountNumberCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar número'**
  String get accountNumberCopy;

  /// No description provided for @accountNumberCopied.
  ///
  /// In es, this message translates to:
  /// **'Número copiado. Se borra del portapapeles en un minuto.'**
  String get accountNumberCopied;

  /// No description provided for @accountArchiveAction.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get accountArchiveAction;

  /// No description provided for @accountDeleteAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get accountDeleteAction;

  /// No description provided for @accountFormNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva cuenta'**
  String get accountFormNewTitle;

  /// No description provided for @accountFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar cuenta'**
  String get accountFormEditTitle;

  /// No description provided for @accountFormTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cuenta'**
  String get accountFormTypeLabel;

  /// No description provided for @accountFormTypeChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get accountFormTypeChange;

  /// No description provided for @accountFormNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get accountFormNameLabel;

  /// No description provided for @accountFormNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Cuenta de ahorros'**
  String get accountFormNameHint;

  /// No description provided for @accountFormInstitutionLabel.
  ///
  /// In es, this message translates to:
  /// **'Institución'**
  String get accountFormInstitutionLabel;

  /// No description provided for @accountFormInstitutionHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Bancolombia'**
  String get accountFormInstitutionHint;

  /// No description provided for @accountFormInitialBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo inicial'**
  String get accountFormInitialBalanceLabel;

  /// No description provided for @accountFormCurrencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get accountFormCurrencyLabel;

  /// No description provided for @accountFormInterestRateLabel.
  ///
  /// In es, this message translates to:
  /// **'Tasa de interés'**
  String get accountFormInterestRateLabel;

  /// No description provided for @accountFormInterestRateHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 24,5'**
  String get accountFormInterestRateHint;

  /// No description provided for @accountFormNumberLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de cuenta'**
  String get accountFormNumberLabel;

  /// No description provided for @accountFormNumberHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get accountFormNumberHint;

  /// HU-03: el número completo vive únicamente en el almacén seguro.
  ///
  /// In es, this message translates to:
  /// **'Se guarda solo en este dispositivo, nunca en la nube.'**
  String get accountFormNumberHelp;

  /// Aviso bajo el campo del número cuando el almacén seguro no devolvió el número guardado. Explica que el campo está vacío porque no se pudo leer, no porque no haya número, y que guardar no lo borrará.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer el número guardado en este dispositivo. Lo dejamos tal cual está: si quieres cambiarlo, escríbelo de nuevo.'**
  String get accountFormNumberReadError;

  /// No description provided for @accountFormLast4Label.
  ///
  /// In es, this message translates to:
  /// **'Últimos 4 dígitos'**
  String get accountFormLast4Label;

  /// No description provided for @accountFormLast4Hint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 4321'**
  String get accountFormLast4Hint;

  /// No description provided for @accountFormCardSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de la tarjeta'**
  String get accountFormCardSectionTitle;

  /// No description provided for @accountFormCreditLimitLabel.
  ///
  /// In es, this message translates to:
  /// **'Cupo máximo'**
  String get accountFormCreditLimitLabel;

  /// No description provided for @accountFormStatementDayLabel.
  ///
  /// In es, this message translates to:
  /// **'Día de corte'**
  String get accountFormStatementDayLabel;

  /// No description provided for @accountFormPaymentDueDayLabel.
  ///
  /// In es, this message translates to:
  /// **'Día de pago'**
  String get accountFormPaymentDueDayLabel;

  /// No description provided for @accountFormAmountHint.
  ///
  /// In es, this message translates to:
  /// **'0'**
  String get accountFormAmountHint;

  /// No description provided for @accountFormSelectHint.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar'**
  String get accountFormSelectHint;

  /// No description provided for @accountErrorType.
  ///
  /// In es, this message translates to:
  /// **'Elige el tipo de cuenta.'**
  String get accountErrorType;

  /// No description provided for @accountErrorName.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre de hasta 100 caracteres.'**
  String get accountErrorName;

  /// No description provided for @accountErrorCurrency.
  ///
  /// In es, this message translates to:
  /// **'Elige una moneda.'**
  String get accountErrorCurrency;

  /// No description provided for @accountErrorInstitution.
  ///
  /// In es, this message translates to:
  /// **'La institución admite hasta 100 caracteres.'**
  String get accountErrorInstitution;

  /// No description provided for @accountErrorFullNumber.
  ///
  /// In es, this message translates to:
  /// **'Revisa el número de cuenta: solo dígitos.'**
  String get accountErrorFullNumber;

  /// No description provided for @accountErrorLast4.
  ///
  /// In es, this message translates to:
  /// **'Ingresa hasta 4 dígitos.'**
  String get accountErrorLast4;

  /// No description provided for @accountErrorInterestRate.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una tasa válida, por ejemplo 24,5.'**
  String get accountErrorInterestRate;

  /// No description provided for @accountErrorInitialBalance.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un saldo válido.'**
  String get accountErrorInitialBalance;

  /// No description provided for @accountErrorCreditLimit.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el cupo de la tarjeta.'**
  String get accountErrorCreditLimit;

  /// No description provided for @accountErrorStatementDay.
  ///
  /// In es, this message translates to:
  /// **'Elige un día entre 1 y 31.'**
  String get accountErrorStatementDay;

  /// No description provided for @accountErrorPaymentDueDay.
  ///
  /// In es, this message translates to:
  /// **'Elige un día entre 1 y 31.'**
  String get accountErrorPaymentDueDay;

  /// No description provided for @accountDeleteSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta cuenta?'**
  String get accountDeleteSheetTitle;

  /// No description provided for @accountDeleteSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'La cuenta dejará de aparecer en tus listas.'**
  String get accountDeleteSheetMessage;

  /// HU-08: impacto en tono neutral, informa sin culpar.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Tiene 1 movimiento asociado.} other{Tiene {count} movimientos asociados.}}'**
  String accountDeleteSheetImpact(int count);

  /// No description provided for @accountArchiveSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Archivar esta cuenta?'**
  String get accountArchiveSheetTitle;

  /// No description provided for @accountArchiveSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Podrás recuperarla cuando quieras desde “Cuentas archivadas”.'**
  String get accountArchiveSheetMessage;

  /// No description provided for @accountChangeSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmas el cambio?'**
  String get accountChangeSheetTitle;

  /// No description provided for @accountChangeSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta ya tiene movimientos. Cambiar su tipo o su moneda cambia cómo se leen sus cifras.'**
  String get accountChangeSheetMessage;

  /// No description provided for @accountChangeConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get accountChangeConfirm;

  /// No description provided for @accountCurrencySheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get accountCurrencySheetTitle;

  /// No description provided for @currencyCopName.
  ///
  /// In es, this message translates to:
  /// **'Peso colombiano'**
  String get currencyCopName;

  /// No description provided for @currencyUsdName.
  ///
  /// In es, this message translates to:
  /// **'Dólar estadounidense'**
  String get currencyUsdName;

  /// No description provided for @accountCannotDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar'**
  String get accountCannotDeleteTitle;

  /// No description provided for @accountCannotDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'Necesitas al menos una cuenta para registrar tus movimientos. Crea otra y luego podrás eliminar esta.'**
  String get accountCannotDeleteMessage;

  /// No description provided for @accountCannotDeleteUnderstood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get accountCannotDeleteUnderstood;

  /// No description provided for @categoriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categoriesTitle;

  /// Acceso temporal a Categorías desde el Hero de Inicio.
  ///
  /// In es, this message translates to:
  /// **'Ver mis categorías'**
  String get categoriesOpenAction;

  /// No description provided for @categoriesAdd.
  ///
  /// In es, this message translates to:
  /// **'Crear categoría'**
  String get categoriesAdd;

  /// No description provided for @categoriesErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus categorías'**
  String get categoriesErrorTitle;

  /// Estado vacío del listado (tab Gasto). Tono neutral.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes categorías de gasto'**
  String get categoriesEmptyExpense;

  /// Estado vacío del listado (tab Ingreso). Tono neutral.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes categorías de ingreso'**
  String get categoriesEmptyIncome;

  /// Etiqueta accesible del estado de carga (skeletons).
  ///
  /// In es, this message translates to:
  /// **'Cargando tus categorías'**
  String get categoriesLoading;

  /// No description provided for @categorySubcategoryCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin subcategorías} =1{1 subcategoría} other{{count} subcategorías}}'**
  String categorySubcategoryCount(int count);

  /// No description provided for @categoryAddSubcategory.
  ///
  /// In es, this message translates to:
  /// **'Agregar subcategoría'**
  String get categoryAddSubcategory;

  /// No description provided for @categoryKindExpense.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get categoryKindExpense;

  /// No description provided for @categoryKindIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingreso'**
  String get categoryKindIncome;

  /// No description provided for @categoryFormNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get categoryFormNewTitle;

  /// No description provided for @categoryFormNewSubcategoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva subcategoría'**
  String get categoryFormNewSubcategoryTitle;

  /// No description provided for @categoryFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar categoría'**
  String get categoryFormEditTitle;

  /// No description provided for @categoryFormEditSubcategoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar subcategoría'**
  String get categoryFormEditSubcategoryTitle;

  /// No description provided for @categoryFormAppearanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Icono y color'**
  String get categoryFormAppearanceLabel;

  /// No description provided for @categoryFormAppearanceEmptySublabel.
  ///
  /// In es, this message translates to:
  /// **'Toca para elegir (opcional)'**
  String get categoryFormAppearanceEmptySublabel;

  /// No description provided for @categoryFormAppearanceFilledSublabel.
  ///
  /// In es, this message translates to:
  /// **'Toca para cambiar'**
  String get categoryFormAppearanceFilledSublabel;

  /// No description provided for @categoryFormNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get categoryFormNameLabel;

  /// No description provided for @categoryFormNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Comida y bebida'**
  String get categoryFormNameHint;

  /// No description provided for @categoryFormKindLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get categoryFormKindLabel;

  /// No description provided for @categoryFormParentLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría padre'**
  String get categoryFormParentLabel;

  /// No description provided for @categoryErrorName.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre de hasta 100 caracteres.'**
  String get categoryErrorName;

  /// No description provided for @categoryKindLockedSubcategory.
  ///
  /// In es, this message translates to:
  /// **'Hereda el tipo de la categoría padre — no se puede cambiar en subcategorías.'**
  String get categoryKindLockedSubcategory;

  /// No description provided for @categoryKindLockedRoot.
  ///
  /// In es, this message translates to:
  /// **'No se puede cambiar el tipo porque tiene subcategorías activas. Elimina o reasigna las subcategorías primero.'**
  String get categoryKindLockedRoot;

  /// No description provided for @categoryDeleteAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar categoría'**
  String get categoryDeleteAction;

  /// No description provided for @categoryAppearancePickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Icono y color'**
  String get categoryAppearancePickerTitle;

  /// No description provided for @categoryParentPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Categoría padre'**
  String get categoryParentPickerTitle;

  /// No description provided for @categoryParentPickerEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay categorías disponibles todavía.'**
  String get categoryParentPickerEmpty;

  /// No description provided for @categoryDeleteSimpleTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta categoría?'**
  String get categoryDeleteSimpleTitle;

  /// No description provided for @categoryDeleteSimpleMessage.
  ///
  /// In es, this message translates to:
  /// **'Podrás recuperarla después desde la papelera.'**
  String get categoryDeleteSimpleMessage;

  /// No description provided for @categoryDeleteTransactionsTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta categoría?'**
  String get categoryDeleteTransactionsTitle;

  /// HU-04 caso 2: impacto en tono neutral, informa sin culpar.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Tiene 1 movimiento asociado.} other{Tiene {count} movimientos asociados.}}'**
  String categoryDeleteTransactionsCount(int count);

  /// No description provided for @categoryDeleteReassignOption.
  ///
  /// In es, this message translates to:
  /// **'Reasignar a otra categoría'**
  String get categoryDeleteReassignOption;

  /// No description provided for @categoryDeleteClearOption.
  ///
  /// In es, this message translates to:
  /// **'Dejar sin categoría'**
  String get categoryDeleteClearOption;

  /// No description provided for @categoryReassignTransactionsPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Reasignar a otra categoría'**
  String get categoryReassignTransactionsPickerTitle;

  /// No description provided for @categoryDeleteSubcategoriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Esta categoría tiene subcategorías'**
  String get categoryDeleteSubcategoriesTitle;

  /// No description provided for @categoryDeleteSubcategoriesMessage.
  ///
  /// In es, this message translates to:
  /// **'Antes de eliminarla, decide qué pasa con sus subcategorías.'**
  String get categoryDeleteSubcategoriesMessage;

  /// No description provided for @categoryReassignSubcategoriesOption.
  ///
  /// In es, this message translates to:
  /// **'Reasignar subcategorías'**
  String get categoryReassignSubcategoriesOption;

  /// No description provided for @categoryReassignSubcategoriesPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Mover subcategorías a'**
  String get categoryReassignSubcategoriesPickerTitle;

  /// No description provided for @categoryCascadeDeleteOption.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todo en cascada'**
  String get categoryCascadeDeleteOption;

  /// No description provided for @categoryCascadeConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la categoría y sus subcategorías?'**
  String get categoryCascadeConfirmTitle;

  /// No description provided for @categoryCascadeConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán la categoría y todas sus subcategorías. Podrás recuperarlas después desde la papelera.'**
  String get categoryCascadeConfirmMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
