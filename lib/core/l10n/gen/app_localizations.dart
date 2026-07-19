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

  /// No description provided for @commonApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get commonApply;

  /// No description provided for @commonDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get commonDone;

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

  /// No description provided for @transactionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get transactionsTitle;

  /// No description provided for @transactionsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nota o categoría'**
  String get transactionsSearchHint;

  /// No description provided for @transactionsLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando movimientos'**
  String get transactionsLoading;

  /// No description provided for @transactionsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay movimientos registrados.'**
  String get transactionsEmptyMessage;

  /// No description provided for @transactionsEmptyPeriodMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay movimientos en este periodo.'**
  String get transactionsEmptyPeriodMessage;

  /// No description provided for @transactionsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus movimientos'**
  String get transactionsErrorTitle;

  /// No description provided for @transactionsErrorLocalFirst.
  ///
  /// In es, this message translates to:
  /// **'Tus datos siguen a salvo en este dispositivo.'**
  String get transactionsErrorLocalFirst;

  /// No description provided for @transactionsAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar movimiento'**
  String get transactionsAdd;

  /// No description provided for @transactionsUndoDeletedMessage.
  ///
  /// In es, this message translates to:
  /// **'Movimiento eliminado.'**
  String get transactionsUndoDeletedMessage;

  /// No description provided for @transactionsUndoAction.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get transactionsUndoAction;

  /// No description provided for @transactionsFilterAccounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get transactionsFilterAccounts;

  /// No description provided for @transactionsFilterCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get transactionsFilterCategories;

  /// No description provided for @transactionsFilterType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get transactionsFilterType;

  /// No description provided for @transactionsFilterDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get transactionsFilterDate;

  /// No description provided for @transactionsFilterTag.
  ///
  /// In es, this message translates to:
  /// **'Etiqueta'**
  String get transactionsFilterTag;

  /// No description provided for @transactionsSortDateDesc.
  ///
  /// In es, this message translates to:
  /// **'Más recientes primero'**
  String get transactionsSortDateDesc;

  /// No description provided for @transactionsSortAmountDesc.
  ///
  /// In es, this message translates to:
  /// **'Monto: mayor a menor'**
  String get transactionsSortAmountDesc;

  /// No description provided for @transactionTypeExpense.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get transactionTypeExpense;

  /// No description provided for @transactionTypeIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingreso'**
  String get transactionTypeIncome;

  /// No description provided for @transactionTypeTransfer.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get transactionTypeTransfer;

  /// No description provided for @transactionFormNewExpenseTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo gasto'**
  String get transactionFormNewExpenseTitle;

  /// No description provided for @transactionFormNewIncomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo ingreso'**
  String get transactionFormNewIncomeTitle;

  /// No description provided for @transactionFormNewTransferTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva transferencia'**
  String get transactionFormNewTransferTitle;

  /// No description provided for @transactionFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar movimiento'**
  String get transactionFormEditTitle;

  /// No description provided for @transactionFormAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get transactionFormAmountLabel;

  /// No description provided for @transactionFormAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get transactionFormAccountLabel;

  /// No description provided for @transactionFormAccountChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir cuenta'**
  String get transactionFormAccountChoose;

  /// No description provided for @transactionFormTransferAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta destino'**
  String get transactionFormTransferAccountLabel;

  /// No description provided for @transactionFormCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get transactionFormCategoryLabel;

  /// No description provided for @categorySelectTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegir categoría'**
  String get categorySelectTitle;

  /// No description provided for @categorySelectSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar categoría'**
  String get categorySelectSearchHint;

  /// No description provided for @categorySelectMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get categorySelectMore;

  /// No description provided for @categorySelectEmpty.
  ///
  /// In es, this message translates to:
  /// **'No encontramos categorías con ese nombre'**
  String get categorySelectEmpty;

  /// No description provided for @categorySelectExpand.
  ///
  /// In es, this message translates to:
  /// **'Mostrar subcategorías'**
  String get categorySelectExpand;

  /// No description provided for @categorySelectCollapse.
  ///
  /// In es, this message translates to:
  /// **'Ocultar subcategorías'**
  String get categorySelectCollapse;

  /// No description provided for @transactionFormDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get transactionFormDateLabel;

  /// No description provided for @transactionFormNoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get transactionFormNoteLabel;

  /// No description provided for @transactionFormNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Agrega una nota (opcional)'**
  String get transactionFormNoteHint;

  /// No description provided for @transactionFormTagsLabel.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas'**
  String get transactionFormTagsLabel;

  /// No description provided for @transactionFormAddTag.
  ///
  /// In es, this message translates to:
  /// **'Agregar etiqueta'**
  String get transactionFormAddTag;

  /// No description provided for @transactionFormTagNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva'**
  String get transactionFormTagNew;

  /// No description provided for @transactionFormTagsSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas'**
  String get transactionFormTagsSheetTitle;

  /// No description provided for @transactionFormSourceLabel.
  ///
  /// In es, this message translates to:
  /// **'Origen'**
  String get transactionFormSourceLabel;

  /// No description provided for @transactionFormTransferAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto a transferir'**
  String get transactionFormTransferAmountLabel;

  /// No description provided for @transactionFormTransferFromLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta origen'**
  String get transactionFormTransferFromLabel;

  /// No description provided for @transactionFormTransferInfo.
  ///
  /// In es, this message translates to:
  /// **'Las transferencias no cuentan como gasto ni ingreso.'**
  String get transactionFormTransferInfo;

  /// No description provided for @transactionFormSwapAccounts.
  ///
  /// In es, this message translates to:
  /// **'Intercambiar cuentas'**
  String get transactionFormSwapAccounts;

  /// No description provided for @transactionFormDateToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get transactionFormDateToday;

  /// No description provided for @transactionFormDateYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get transactionFormDateYesterday;

  /// Valor mostrado en el campo Fecha, ej. 'Hoy, 13 jul'.
  ///
  /// In es, this message translates to:
  /// **'{prefix}, {date}'**
  String transactionFormDateValue(String prefix, String date);

  /// Título del sheet selector de fecha.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get datePickerTitle;

  /// No description provided for @datePickerPreviousMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes anterior'**
  String get datePickerPreviousMonth;

  /// No description provided for @datePickerNextMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes siguiente'**
  String get datePickerNextMonth;

  /// No description provided for @transactionFormExpandAmount.
  ///
  /// In es, this message translates to:
  /// **'Editar monto'**
  String get transactionFormExpandAmount;

  /// No description provided for @transactionFormCollapseAmount.
  ///
  /// In es, this message translates to:
  /// **'Ocultar teclado'**
  String get transactionFormCollapseAmount;

  /// No description provided for @transactionFormKeypadAdd.
  ///
  /// In es, this message translates to:
  /// **'Sumar'**
  String get transactionFormKeypadAdd;

  /// No description provided for @transactionFormKeypadSubtract.
  ///
  /// In es, this message translates to:
  /// **'Restar'**
  String get transactionFormKeypadSubtract;

  /// No description provided for @transactionFormKeypadMultiply.
  ///
  /// In es, this message translates to:
  /// **'Multiplicar'**
  String get transactionFormKeypadMultiply;

  /// No description provided for @transactionFormKeypadDivide.
  ///
  /// In es, this message translates to:
  /// **'Dividir'**
  String get transactionFormKeypadDivide;

  /// No description provided for @transactionFormKeypadEquals.
  ///
  /// In es, this message translates to:
  /// **'Calcular resultado'**
  String get transactionFormKeypadEquals;

  /// No description provided for @transactionFormKeypadDecimal.
  ///
  /// In es, this message translates to:
  /// **'Punto decimal'**
  String get transactionFormKeypadDecimal;

  /// No description provided for @transactionFormKeypadBackspace.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get transactionFormKeypadBackspace;

  /// No description provided for @transactionSourceManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get transactionSourceManual;

  /// No description provided for @transactionSourceVoice.
  ///
  /// In es, this message translates to:
  /// **'Voz'**
  String get transactionSourceVoice;

  /// No description provided for @transactionSourceOcr.
  ///
  /// In es, this message translates to:
  /// **'Foto de recibo'**
  String get transactionSourceOcr;

  /// No description provided for @transactionSourceNotification.
  ///
  /// In es, this message translates to:
  /// **'Notificación bancaria'**
  String get transactionSourceNotification;

  /// No description provided for @transactionSourceImported.
  ///
  /// In es, this message translates to:
  /// **'Importado'**
  String get transactionSourceImported;

  /// No description provided for @transactionSourceScheduled.
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get transactionSourceScheduled;

  /// No description provided for @transactionEditImpactTitle.
  ///
  /// In es, this message translates to:
  /// **'Este movimiento está vinculado'**
  String get transactionEditImpactTitle;

  /// No description provided for @transactionEditImpactScheduled.
  ///
  /// In es, this message translates to:
  /// **'Afecta su pago programado asociado.'**
  String get transactionEditImpactScheduled;

  /// No description provided for @transactionEditImpactGoal.
  ///
  /// In es, this message translates to:
  /// **'Afecta la meta a la que aporta.'**
  String get transactionEditImpactGoal;

  /// No description provided for @transactionEditImpactDebt.
  ///
  /// In es, this message translates to:
  /// **'Afecta la deuda a la que abona.'**
  String get transactionEditImpactDebt;

  /// No description provided for @transactionEditImpactConfirm.
  ///
  /// In es, this message translates to:
  /// **'Guardar de todas formas'**
  String get transactionEditImpactConfirm;

  /// No description provided for @transactionDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este movimiento?'**
  String get transactionDeleteTitle;

  /// No description provided for @transactionDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'Podrás recuperarlo después desde la papelera.'**
  String get transactionDeleteMessage;

  /// No description provided for @transactionDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle del movimiento'**
  String get transactionDetailTitle;

  /// No description provided for @transactionDetailEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get transactionDetailEdit;

  /// No description provided for @transactionDetailDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get transactionDetailDelete;

  /// No description provided for @transactionDetailSource.
  ///
  /// In es, this message translates to:
  /// **'Registrado como {source}'**
  String transactionDetailSource(String source);

  /// No description provided for @transactionDetailAccountLine.
  ///
  /// In es, this message translates to:
  /// **'Cuenta: {account}'**
  String transactionDetailAccountLine(String account);

  /// No description provided for @transactionDetailTransferLine.
  ///
  /// In es, this message translates to:
  /// **'Cuenta destino: {account}'**
  String transactionDetailTransferLine(String account);

  /// No description provided for @transactionDetailCategoryLine.
  ///
  /// In es, this message translates to:
  /// **'Categoría: {category}'**
  String transactionDetailCategoryLine(String category);

  /// No description provided for @transactionDetailNoteLine.
  ///
  /// In es, this message translates to:
  /// **'Nota: {note}'**
  String transactionDetailNoteLine(String note);

  /// No description provided for @transactionDetailTagsLine.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas: {tags}'**
  String transactionDetailTagsLine(String tags);

  /// No description provided for @accountFilterSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por cuenta'**
  String get accountFilterSheetTitle;

  /// No description provided for @accountFilterSelectAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get accountFilterSelectAll;

  /// No description provided for @accountFilterSelectNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguna'**
  String get accountFilterSelectNone;

  /// No description provided for @categoryFilterSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por categoría'**
  String get categoryFilterSheetTitle;

  /// No description provided for @typeFilterSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por tipo'**
  String get typeFilterSheetTitle;

  /// No description provided for @dateFilterSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por fecha'**
  String get dateFilterSheetTitle;

  /// No description provided for @dateFilterWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get dateFilterWeek;

  /// No description provided for @dateFilterMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get dateFilterMonth;

  /// No description provided for @dateFilterYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get dateFilterYear;

  /// No description provided for @dateFilterCustomRange.
  ///
  /// In es, this message translates to:
  /// **'Rango personalizado'**
  String get dateFilterCustomRange;

  /// No description provided for @dateFilterStart.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get dateFilterStart;

  /// No description provided for @dateFilterEnd.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get dateFilterEnd;

  /// No description provided for @dateFilterRangeLabel.
  ///
  /// In es, this message translates to:
  /// **'{start} - {end}'**
  String dateFilterRangeLabel(String start, String end);

  /// No description provided for @tagFilterSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por etiqueta'**
  String get tagFilterSheetTitle;

  /// No description provided for @newTagSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva etiqueta'**
  String get newTagSheetTitle;

  /// No description provided for @newTagNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la etiqueta'**
  String get newTagNameHint;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navBudgets.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos'**
  String get navBudgets;

  /// No description provided for @navGoals.
  ///
  /// In es, this message translates to:
  /// **'Metas'**
  String get navGoals;

  /// No description provided for @navMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get navMore;

  /// Saludo genérico del header cuando no hay cuenta ni nombre local.
  ///
  /// In es, this message translates to:
  /// **'Hola de nuevo'**
  String get homeGreeting;

  /// Saludo del header cuando hay sesión, con el nombre del usuario.
  ///
  /// In es, this message translates to:
  /// **'Hola de nuevo, {name}'**
  String homeGreetingNamed(String name);

  /// No description provided for @homeNotificationsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get homeNotificationsTooltip;

  /// No description provided for @homeSyncSynced.
  ///
  /// In es, this message translates to:
  /// **'Sincronizado'**
  String get homeSyncSynced;

  /// No description provided for @homeSyncSyncing.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando'**
  String get homeSyncSyncing;

  /// No description provided for @homeSyncOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get homeSyncOffline;

  /// Etiqueta del hero con el mes visible.
  ///
  /// In es, this message translates to:
  /// **'Gastado en {month}'**
  String homeSpentInMonth(String month);

  /// No description provided for @homeBudgetInvitation.
  ///
  /// In es, this message translates to:
  /// **'Define un presupuesto para ver cuánto te queda este mes'**
  String get homeBudgetInvitation;

  /// No description provided for @homeNoSpendingYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay gastos este mes'**
  String get homeNoSpendingYet;

  /// No description provided for @homeRecentTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos recientes'**
  String get homeRecentTitle;

  /// No description provided for @homeSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get homeSeeAll;

  /// No description provided for @homeEmptyMovements.
  ///
  /// In es, this message translates to:
  /// **'Aún no registras movimientos'**
  String get homeEmptyMovements;

  /// No description provided for @homeLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando inicio'**
  String get homeLoading;

  /// No description provided for @homeMonthPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegir mes'**
  String get homeMonthPickerTitle;

  /// No description provided for @homeAiBanner.
  ///
  /// In es, this message translates to:
  /// **'Pronto: pregúntale a Billetudo'**
  String get homeAiBanner;

  /// No description provided for @homeAiSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Pronto podrás preguntarle a Billetudo sobre tu plata en lenguaje natural.'**
  String get homeAiSheetMessage;

  /// No description provided for @homeAiDisclaimer.
  ///
  /// In es, this message translates to:
  /// **'No es asesoría financiera.'**
  String get homeAiDisclaimer;

  /// No description provided for @homeNotificationsSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones llegarán pronto.'**
  String get homeNotificationsSheetMessage;

  /// No description provided for @comingSoonTitle.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos preparando esta sección. Muy pronto la tendrás aquí.'**
  String get comingSoonMessage;

  /// No description provided for @comingSoonBadge.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get comingSoonBadge;

  /// No description provided for @comingSoonUnderstood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get comingSoonUnderstood;

  /// No description provided for @moreTitle.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get moreTitle;

  /// No description provided for @moreDebts.
  ///
  /// In es, this message translates to:
  /// **'Deudas'**
  String get moreDebts;

  /// No description provided for @moreScheduledPayments.
  ///
  /// In es, this message translates to:
  /// **'Pagos programados'**
  String get moreScheduledPayments;

  /// No description provided for @moreReports.
  ///
  /// In es, this message translates to:
  /// **'Gráficas e informes'**
  String get moreReports;

  /// No description provided for @moreImportExport.
  ///
  /// In es, this message translates to:
  /// **'Importar y exportar'**
  String get moreImportExport;

  /// No description provided for @moreSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get moreSettings;

  /// No description provided for @moreSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get moreSignOut;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get authContinueWithApple;

  /// No description provided for @authContinueWithoutAccount.
  ///
  /// In es, this message translates to:
  /// **'Continuar sin cuenta'**
  String get authContinueWithoutAccount;

  /// No description provided for @authLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Nunca pierdas tu progreso'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un respaldo automático de tus cuentas y movimientos, listo para cuando lo necesites.'**
  String get authLoginSubtitle;

  /// No description provided for @authTrustRow.
  ///
  /// In es, this message translates to:
  /// **'Usa la app desde cualquier celular sin perder tu historial'**
  String get authTrustRow;

  /// No description provided for @authGoogleLoading.
  ///
  /// In es, this message translates to:
  /// **'Conectando con Google…'**
  String get authGoogleLoading;

  /// No description provided for @authGoogleErrorSnackbar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar sesión con Google'**
  String get authGoogleErrorSnackbar;

  /// No description provided for @authAppleErrorSnackbar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar sesión con Apple'**
  String get authAppleErrorSnackbar;

  /// No description provided for @authMergeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus datos están a salvo'**
  String get authMergeTitle;

  /// No description provided for @authMergeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Combinamos todo lo que ya tenías guardado con tu cuenta. Nada se perdió en el camino.'**
  String get authMergeSubtitle;

  /// No description provided for @authMergeStatAccounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get authMergeStatAccounts;

  /// No description provided for @authMergeStatTransactions.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get authMergeStatTransactions;

  /// No description provided for @authMergeStatCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get authMergeStatCategories;

  /// No description provided for @authMergeCaption.
  ///
  /// In es, this message translates to:
  /// **'Tus dispositivos se mantendrán sincronizados automáticamente'**
  String get authMergeCaption;

  /// No description provided for @authMergeCta.
  ///
  /// In es, this message translates to:
  /// **'Ir a mis finanzas'**
  String get authMergeCta;

  /// No description provided for @authMergeErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos fusionar tus datos'**
  String get authMergeErrorTitle;

  /// No description provided for @authMergeErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Tus datos siguen a salvo en este dispositivo. Intenta de nuevo cuando tengas conexión.'**
  String get authMergeErrorMessage;

  /// No description provided for @authSignOutSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get authSignOutSheetTitle;

  /// No description provided for @authSignOutSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Tus cuentas y movimientos seguirán guardados en este dispositivo, no se borran. Pero los cambios que hagas aquí después no se sincronizarán hasta que vuelvas a iniciar sesión.'**
  String get authSignOutSheetMessage;

  /// No description provided for @authSignOutCta.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get authSignOutCta;

  /// No description provided for @authDeleteStep1Title.
  ///
  /// In es, this message translates to:
  /// **'Eliminar tu cuenta'**
  String get authDeleteStep1Title;

  /// No description provided for @authDeleteStep1Message.
  ///
  /// In es, this message translates to:
  /// **'Vamos a borrar tus cuentas, movimientos, categorías y todo lo demás asociado a tu cuenta en la nube. Esta acción no se puede deshacer.'**
  String get authDeleteStep1Message;

  /// No description provided for @authDeleteStep1Cta.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get authDeleteStep1Cta;

  /// No description provided for @authDeleteStep1ErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos eliminar tu cuenta'**
  String get authDeleteStep1ErrorTitle;

  /// No description provided for @authDeleteStep1ErrorMessage.
  ///
  /// In es, this message translates to:
  /// **'Tus datos siguen a salvo en este dispositivo. Intenta de nuevo cuando tengas conexión.'**
  String get authDeleteStep1ErrorMessage;

  /// No description provided for @authDeleteStep2Title.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hacemos con tus datos en este teléfono?'**
  String get authDeleteStep2Title;

  /// No description provided for @authDeleteStep2Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta en la nube ya se eliminó. Esto es solo sobre este dispositivo.'**
  String get authDeleteStep2Subtitle;

  /// No description provided for @authDeleteStep2KeepTitle.
  ///
  /// In es, this message translates to:
  /// **'Conservar mis datos en este dispositivo'**
  String get authDeleteStep2KeepTitle;

  /// No description provided for @authDeleteStep2KeepSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sigue usando billetudo sin cuenta, con lo que ya tienes registrado.'**
  String get authDeleteStep2KeepSubtitle;

  /// No description provided for @authDeleteStep2DeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrar también los datos de este dispositivo'**
  String get authDeleteStep2DeleteTitle;

  /// No description provided for @authDeleteStep2DeleteSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se elimina todo tu historial local.'**
  String get authDeleteStep2DeleteSubtitle;

  /// No description provided for @authDeleteStep2Cta.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get authDeleteStep2Cta;

  /// No description provided for @authDeleteStep3Title.
  ///
  /// In es, this message translates to:
  /// **'Listo, tu cuenta fue eliminada'**
  String get authDeleteStep3Title;

  /// No description provided for @authDeleteStep3Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Ya no tenemos ningún dato tuyo en la nube. Puedes seguir usando billetudo cuando quieras, con o sin cuenta.'**
  String get authDeleteStep3Subtitle;

  /// No description provided for @authDeleteStep3Cta.
  ///
  /// In es, this message translates to:
  /// **'Ir al inicio'**
  String get authDeleteStep3Cta;

  /// No description provided for @authSessionProviderGoogle.
  ///
  /// In es, this message translates to:
  /// **'Sesión iniciada con Google'**
  String get authSessionProviderGoogle;

  /// No description provided for @authSessionProviderApple.
  ///
  /// In es, this message translates to:
  /// **'Sesión iniciada con Apple'**
  String get authSessionProviderApple;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsAccountSection.
  ///
  /// In es, this message translates to:
  /// **'Cuenta y respaldo'**
  String get settingsAccountSection;

  /// No description provided for @settingsBackupTitle.
  ///
  /// In es, this message translates to:
  /// **'Respaldar en la nube'**
  String get settingsBackupTitle;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda tus datos de forma segura'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsPreferencesSection.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get settingsPreferencesSection;

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearance;

  /// No description provided for @settingsCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get settingsCurrency;

  /// No description provided for @settingsCurrencySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige la moneda con la que registras tus movimientos'**
  String get settingsCurrencySubtitle;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settingsDeleteAccount;

  /// No description provided for @budgetsTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos'**
  String get budgetsTitle;

  /// No description provided for @budgetsAdd.
  ///
  /// In es, this message translates to:
  /// **'Nuevo presupuesto'**
  String get budgetsAdd;

  /// No description provided for @budgetsNewCta.
  ///
  /// In es, this message translates to:
  /// **'+ Nuevo presupuesto'**
  String get budgetsNewCta;

  /// No description provided for @budgetsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes presupuestos'**
  String get budgetsEmptyMessage;

  /// No description provided for @budgetsEmptyCta.
  ///
  /// In es, this message translates to:
  /// **'Crear presupuesto'**
  String get budgetsEmptyCta;

  /// No description provided for @budgetsLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tus presupuestos'**
  String get budgetsLoading;

  /// No description provided for @budgetsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus presupuestos'**
  String get budgetsErrorTitle;

  /// No description provided for @budgetsMenuHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver histórico'**
  String get budgetsMenuHistory;

  /// No description provided for @budgetRemainingLabel.
  ///
  /// In es, this message translates to:
  /// **'Te quedan'**
  String get budgetRemainingLabel;

  /// No description provided for @budgetOverspentLabel.
  ///
  /// In es, this message translates to:
  /// **'Excedido por'**
  String get budgetOverspentLabel;

  /// No description provided for @budgetResetsOn.
  ///
  /// In es, this message translates to:
  /// **'se reinicia el {date}'**
  String budgetResetsOn(String date);

  /// No description provided for @budgetEndsOn.
  ///
  /// In es, this message translates to:
  /// **'termina el {date}'**
  String budgetEndsOn(String date);

  /// No description provided for @budgetScopeGlobal.
  ///
  /// In es, this message translates to:
  /// **'Todo el gasto'**
  String get budgetScopeGlobal;

  /// No description provided for @budgetScopeStranded.
  ///
  /// In es, this message translates to:
  /// **'Sin alcance válido'**
  String get budgetScopeStranded;

  /// No description provided for @budgetScopeAccounts.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} cuenta} other{{count} cuentas}}'**
  String budgetScopeAccounts(int count);

  /// No description provided for @budgetScopeCategories.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} categoría} other{{count} categorías}}'**
  String budgetScopeCategories(int count);

  /// No description provided for @budgetPercent.
  ///
  /// In es, this message translates to:
  /// **'{pct}%'**
  String budgetPercent(int pct);

  /// No description provided for @budgetDaysLeft.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Último día} one{Resta {count} día} other{Restan {count} días}}'**
  String budgetDaysLeft(int count);

  /// No description provided for @budgetProgressBreakdown.
  ///
  /// In es, this message translates to:
  /// **'{spent} de {amount}'**
  String budgetProgressBreakdown(String spent, String amount);

  /// No description provided for @budgetActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad del periodo'**
  String get budgetActivityTitle;

  /// No description provided for @budgetActivityEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin movimientos en este periodo'**
  String get budgetActivityEmpty;

  /// No description provided for @budgetLoadMore.
  ///
  /// In es, this message translates to:
  /// **'Cargar más'**
  String get budgetLoadMore;

  /// No description provided for @budgetOpenInTransactions.
  ///
  /// In es, this message translates to:
  /// **'Abrir en Movimientos'**
  String get budgetOpenInTransactions;

  /// No description provided for @budgetPeriodStatusCurrent.
  ///
  /// In es, this message translates to:
  /// **'vigente'**
  String get budgetPeriodStatusCurrent;

  /// No description provided for @budgetPeriodStatusPast.
  ///
  /// In es, this message translates to:
  /// **'pasado'**
  String get budgetPeriodStatusPast;

  /// No description provided for @budgetPeriodStatusFuture.
  ///
  /// In es, this message translates to:
  /// **'futuro'**
  String get budgetPeriodStatusFuture;

  /// No description provided for @budgetActionClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar (guardar en histórico)'**
  String get budgetActionClose;

  /// No description provided for @budgetActionDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get budgetActionDelete;

  /// No description provided for @budgetDeleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar presupuesto?'**
  String get budgetDeleteConfirmTitle;

  /// No description provided for @budgetDeleteConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Podrás recuperarlo desde la papelera.'**
  String get budgetDeleteConfirmMessage;

  /// No description provided for @budgetFormNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo presupuesto'**
  String get budgetFormNewTitle;

  /// No description provided for @budgetFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar presupuesto'**
  String get budgetFormEditTitle;

  /// No description provided for @budgetFormNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get budgetFormNameLabel;

  /// No description provided for @budgetFormNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Mercado del mes'**
  String get budgetFormNameHint;

  /// No description provided for @budgetFormIconLabel.
  ///
  /// In es, this message translates to:
  /// **'Ícono'**
  String get budgetFormIconLabel;

  /// No description provided for @budgetFormAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get budgetFormAmountLabel;

  /// No description provided for @budgetFormRepeatLabel.
  ///
  /// In es, this message translates to:
  /// **'Repetir'**
  String get budgetFormRepeatLabel;

  /// No description provided for @budgetFormRepeatPeriodic.
  ///
  /// In es, this message translates to:
  /// **'Periódico'**
  String get budgetFormRepeatPeriodic;

  /// No description provided for @budgetFormRepeatOneOff.
  ///
  /// In es, this message translates to:
  /// **'Una única vez'**
  String get budgetFormRepeatOneOff;

  /// No description provided for @budgetFormPeriodLabel.
  ///
  /// In es, this message translates to:
  /// **'Periodicidad'**
  String get budgetFormPeriodLabel;

  /// No description provided for @budgetPeriodWeekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get budgetPeriodWeekly;

  /// No description provided for @budgetPeriodBiweekly.
  ///
  /// In es, this message translates to:
  /// **'Quincenal'**
  String get budgetPeriodBiweekly;

  /// No description provided for @budgetPeriodMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get budgetPeriodMonthly;

  /// No description provided for @budgetPeriodYearly.
  ///
  /// In es, this message translates to:
  /// **'Anual'**
  String get budgetPeriodYearly;

  /// No description provided for @budgetFormStartLabel.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get budgetFormStartLabel;

  /// No description provided for @budgetFormEndLabel.
  ///
  /// In es, this message translates to:
  /// **'Fin'**
  String get budgetFormEndLabel;

  /// No description provided for @budgetFormRepeatUntilLabel.
  ///
  /// In es, this message translates to:
  /// **'Repetir hasta'**
  String get budgetFormRepeatUntilLabel;

  /// No description provided for @budgetFormForever.
  ///
  /// In es, this message translates to:
  /// **'Para siempre'**
  String get budgetFormForever;

  /// No description provided for @budgetFormUntilDate.
  ///
  /// In es, this message translates to:
  /// **'Hasta una fecha'**
  String get budgetFormUntilDate;

  /// No description provided for @budgetFormScopeLabel.
  ///
  /// In es, this message translates to:
  /// **'Alcance'**
  String get budgetFormScopeLabel;

  /// No description provided for @budgetFormScopeAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get budgetFormScopeAll;

  /// No description provided for @budgetFormScopeCustom.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get budgetFormScopeCustom;

  /// No description provided for @budgetFormAccountsRow.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get budgetFormAccountsRow;

  /// No description provided for @budgetFormCategoriesRow.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get budgetFormCategoriesRow;

  /// No description provided for @budgetScopeAllAccounts.
  ///
  /// In es, this message translates to:
  /// **'Todas las cuentas'**
  String get budgetScopeAllAccounts;

  /// No description provided for @budgetScopeAllCategories.
  ///
  /// In es, this message translates to:
  /// **'Todas las categorías'**
  String get budgetScopeAllCategories;

  /// No description provided for @budgetFormThresholdRow.
  ///
  /// In es, this message translates to:
  /// **'Avisarme al {pct}% del presupuesto'**
  String budgetFormThresholdRow(int pct);

  /// No description provided for @budgetFormThresholdOff.
  ///
  /// In es, this message translates to:
  /// **'No avisarme'**
  String get budgetFormThresholdOff;

  /// No description provided for @budgetFormCreateCta.
  ///
  /// In es, this message translates to:
  /// **'Crear presupuesto'**
  String get budgetFormCreateCta;

  /// No description provided for @budgetFormSaveCta.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get budgetFormSaveCta;

  /// No description provided for @budgetThresholdTitle.
  ///
  /// In es, this message translates to:
  /// **'Umbral de alerta'**
  String get budgetThresholdTitle;

  /// No description provided for @budgetThresholdCustom.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get budgetThresholdCustom;

  /// No description provided for @budgetIconSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegir ícono'**
  String get budgetIconSheetTitle;

  /// No description provided for @budgetsHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Histórico'**
  String get budgetsHistoryTitle;

  /// No description provided for @budgetsHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'No has cerrado ningún presupuesto'**
  String get budgetsHistoryEmpty;

  /// No description provided for @budgetsHistoryLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tu histórico'**
  String get budgetsHistoryLoading;

  /// No description provided for @budgetReactivate.
  ///
  /// In es, this message translates to:
  /// **'Reactivar'**
  String get budgetReactivate;

  /// No description provided for @budgetResultWithin.
  ///
  /// In es, this message translates to:
  /// **'Dentro del presupuesto'**
  String get budgetResultWithin;

  /// No description provided for @budgetResultOverspent.
  ///
  /// In es, this message translates to:
  /// **'Excedido por {amount}'**
  String budgetResultOverspent(String amount);

  /// Aviso neutral: cuántos presupuestos usan la cuenta/categoría que se va a eliminar. No se elimina el presupuesto en cascada.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se usa en 1 presupuesto.} other{Se usa en {count} presupuestos.}}'**
  String deleteImpactBudgets(int count);

  /// No description provided for @settingsEnvelopeMode.
  ///
  /// In es, this message translates to:
  /// **'Modo sobres'**
  String get settingsEnvelopeMode;

  /// No description provided for @settingsEnvelopeModeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reparte tu ingreso del mes entre tus presupuestos'**
  String get settingsEnvelopeModeSubtitle;

  /// No description provided for @settingsEnvelopeWhatIs.
  ///
  /// In es, this message translates to:
  /// **'¿Qué es?'**
  String get settingsEnvelopeWhatIs;

  /// No description provided for @envelopeInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué es el modo sobres?'**
  String get envelopeInfoTitle;

  /// No description provided for @envelopeInfoBody.
  ///
  /// In es, this message translates to:
  /// **'Es una forma sencilla de organizar tu dinero: en vez de gastar de un montón común, repartes lo que recibes cada mes en sobres, uno por cada cosa que te importa (mercado, arriendo, salidas). Así, antes de gastar, ya sabes cuánto tiene cada sobre. La idea es que todo tu ingreso quede repartido, para que cada peso tenga un propósito. Es opcional y puedes prenderlo o apagarlo cuando quieras.'**
  String get envelopeInfoBody;

  /// No description provided for @envelopeInfoGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get envelopeInfoGotIt;

  /// No description provided for @budgetsMenuDisableEnvelope.
  ///
  /// In es, this message translates to:
  /// **'Desactivar modo sobres'**
  String get budgetsMenuDisableEnvelope;

  /// No description provided for @budgetsEnvelopeUnassignedLabel.
  ///
  /// In es, this message translates to:
  /// **'Sin asignar'**
  String get budgetsEnvelopeUnassignedLabel;

  /// No description provided for @budgetsEnvelopeOverLabel.
  ///
  /// In es, this message translates to:
  /// **'Asignado de más'**
  String get budgetsEnvelopeOverLabel;

  /// No description provided for @budgetsEnvelopeAllAssigned.
  ///
  /// In es, this message translates to:
  /// **'Cada peso tiene un trabajo'**
  String get budgetsEnvelopeAllAssigned;

  /// No description provided for @budgetsEnvelopeCaption.
  ///
  /// In es, this message translates to:
  /// **'{income} de ingreso · {assigned} asignado'**
  String budgetsEnvelopeCaption(String income, String assigned);

  /// Título de la pantalla de bloqueo por falta de red en el primerísimo arranque (decisión #12, docs/requirements/05-auth-sync.md). Copy deliberadamente agnóstico: no menciona categorías ni sincronización.
  ///
  /// In es, this message translates to:
  /// **'Conéctate para continuar'**
  String get firstLaunchOfflineTitle;

  /// No description provided for @firstLaunchOfflineSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos conexión a internet para terminar de configurar tu cuenta. Cuando tengas señal, vuelve a intentarlo.'**
  String get firstLaunchOfflineSubtitle;

  /// Label del botón Reintentar mientras la petición está en curso.
  ///
  /// In es, this message translates to:
  /// **'Reintentando...'**
  String get firstLaunchOfflineRetrying;
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
