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

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// Conjunción para unir el último elemento de una lista en prosa, ej. 'a, b y c'.
  ///
  /// In es, this message translates to:
  /// **'y'**
  String get commonAnd;

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

  /// Etiqueta accesible del botón ⋮ del Page Header.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get commonMoreActions;

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

  /// No description provided for @commonCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get commonCreate;

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
  /// **'Tus datos siguen guardados en tu dispositivo. Intenta de nuevo.'**
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

  /// No description provided for @accountDebtShortLabel.
  ///
  /// In es, this message translates to:
  /// **'Deuda'**
  String get accountDebtShortLabel;

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
  /// **'••••••• {last4}'**
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
  /// **'Nombre de la cuenta'**
  String get accountFormNameLabel;

  /// No description provided for @accountFormNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Cuenta de ahorros'**
  String get accountFormNameHint;

  /// No description provided for @accountFormInstitutionLabel.
  ///
  /// In es, this message translates to:
  /// **'Institución (opcional)'**
  String get accountFormInstitutionLabel;

  /// No description provided for @accountFormInstitutionHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
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
  /// **'\$0'**
  String get accountFormAmountHint;

  /// No description provided for @accountFormSelectHint.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar'**
  String get accountFormSelectHint;

  /// No description provided for @accountFormSaveCta.
  ///
  /// In es, this message translates to:
  /// **'Guardar cuenta'**
  String get accountFormSaveCta;

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

  /// No description provided for @accountDeleteSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta no tiene movimientos asociados. Esta acción no se puede deshacer.'**
  String get accountDeleteSheetMessage;

  /// HU-08: impacto en tono neutral, informa sin culpar.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Esta cuenta tiene 1 transacción asociada. Si la eliminas, ese historial se archivará también. Esta acción no se puede deshacer.} other{Esta cuenta tiene {count} transacciones asociadas. Si la eliminas, ese historial se archivará también. Esta acción no se puede deshacer.}}'**
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

  /// No description provided for @accountChangeSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Cambiar el tipo o la moneda de esta cuenta puede afectar cálculos y reportes de tus transacciones existentes. ¿Deseas continuar?'**
  String get accountChangeSheetMessage;

  /// No description provided for @accountChangeConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get accountChangeConfirm;

  /// No description provided for @accountCurrencySheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona la moneda'**
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
  /// **'Ícono y color'**
  String get categoryFormAppearanceLabel;

  /// No description provided for @categoryFormAppearanceEmptyLabel.
  ///
  /// In es, this message translates to:
  /// **'Elegir ícono y color'**
  String get categoryFormAppearanceEmptyLabel;

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

  /// No description provided for @categoryDeleteSubcategoryAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar subcategoría'**
  String get categoryDeleteSubcategoryAction;

  /// No description provided for @categoryAppearancePickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Ícono y color'**
  String get categoryAppearancePickerTitle;

  /// No description provided for @categoryColorLockedSubcategory.
  ///
  /// In es, this message translates to:
  /// **'El color se hereda de la categoría padre y no se puede cambiar. Elige el ícono que prefieras.'**
  String get categoryColorLockedSubcategory;

  /// No description provided for @categoryAppearanceIconSectionLabel.
  ///
  /// In es, this message translates to:
  /// **'Ícono'**
  String get categoryAppearanceIconSectionLabel;

  /// No description provided for @categoryAppearanceColorSectionLabel.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get categoryAppearanceColorSectionLabel;

  /// No description provided for @categoryParentPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Categoría padre'**
  String get categoryParentPickerTitle;

  /// No description provided for @categoryParentPickerHint.
  ///
  /// In es, this message translates to:
  /// **'Solo se muestran categorías principales de Gasto. Las subcategorías no pueden anidarse dentro de otras subcategorías.'**
  String get categoryParentPickerHint;

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
  /// **'Esta categoría se eliminará de tu lista. Podrás recuperarla luego desde la papelera, en Ajustes.'**
  String get categoryDeleteSimpleMessage;

  /// HU-04 caso 2 (`snXFk`): mensaje único con el nombre real de la categoría y el conteo de movimientos, en tono neutral.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{\"{categoryName}\" tiene 1 movimiento asociado. Elige qué hacer con él antes de eliminar la categoría.} other{\"{categoryName}\" tiene {count} movimientos asociados. Elige qué hacer con ellos antes de eliminar la categoría.}}'**
  String categoryDeleteTransactionsMessage(String categoryName, int count);

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

  /// HU-04 caso 3 (`w9ixr`): mensaje único con el nombre real de la categoría raíz y el conteo de subcategorías activas.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{\"{categoryName}\" tiene 1 subcategoría activa. Debes resolverla antes de eliminar esta categoría raíz.} other{\"{categoryName}\" tiene {count} subcategorías activas. Debes resolverlas antes de eliminar esta categoría raíz.}}'**
  String categoryDeleteSubcategoriesMessage(String categoryName, int count);

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
  /// **'Se eliminarán la categoría y todas sus subcategorías. Podrás deshacerlo justo después de eliminar.'**
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
  /// **'Tus datos siguen guardados en tu dispositivo. Intenta de nuevo.'**
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

  /// No description provided for @transactionsSortDateAsc.
  ///
  /// In es, this message translates to:
  /// **'Más antiguos primero'**
  String get transactionsSortDateAsc;

  /// No description provided for @transactionsSortAmountDesc.
  ///
  /// In es, this message translates to:
  /// **'Mayor a menor'**
  String get transactionsSortAmountDesc;

  /// No description provided for @transactionsSortAmountAsc.
  ///
  /// In es, this message translates to:
  /// **'Menor a mayor'**
  String get transactionsSortAmountAsc;

  /// No description provided for @transactionsSortSectionDate.
  ///
  /// In es, this message translates to:
  /// **'FECHA'**
  String get transactionsSortSectionDate;

  /// No description provided for @transactionsSortSectionAmount.
  ///
  /// In es, this message translates to:
  /// **'MONTO'**
  String get transactionsSortSectionAmount;

  /// No description provided for @transactionsSortActiveByDate.
  ///
  /// In es, this message translates to:
  /// **'Ordenado por fecha'**
  String get transactionsSortActiveByDate;

  /// No description provided for @transactionsSortActiveByAmount.
  ///
  /// In es, this message translates to:
  /// **'Ordenado por monto'**
  String get transactionsSortActiveByAmount;

  /// Etiqueta del chip de cuenta cuando hay más de una cuenta activa como filtro (HU-06a).
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cuenta} other{{count} cuentas}}'**
  String transactionsFilterAccountsSelected(int count);

  /// No description provided for @transactionsGroupToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get transactionsGroupToday;

  /// No description provided for @transactionsGroupYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get transactionsGroupYesterday;

  /// Contador del encabezado de cada grupo de fecha de la lista de movimientos (HU-06).
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 movimiento} other{{count} movimientos}}'**
  String transactionsGroupCount(int count);

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

  /// No description provided for @transactionErrorAccount.
  ///
  /// In es, this message translates to:
  /// **'Elige una cuenta.'**
  String get transactionErrorAccount;

  /// No description provided for @transactionErrorCategory.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría.'**
  String get transactionErrorCategory;

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

  /// No description provided for @transactionEditImpactMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta transacción está vinculada a {links}. Si cambias el monto, revisa que siga coincidiendo.'**
  String transactionEditImpactMessage(String links);

  /// No description provided for @transactionEditImpactLinkScheduled.
  ///
  /// In es, this message translates to:
  /// **'tu pago programado'**
  String get transactionEditImpactLinkScheduled;

  /// No description provided for @transactionEditImpactLinkGoal.
  ///
  /// In es, this message translates to:
  /// **'tu meta'**
  String get transactionEditImpactLinkGoal;

  /// No description provided for @transactionEditImpactLinkDebt.
  ///
  /// In es, this message translates to:
  /// **'tu deuda'**
  String get transactionEditImpactLinkDebt;

  /// No description provided for @transactionDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este movimiento?'**
  String get transactionDeleteTitle;

  /// No description provided for @transactionDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'Podrás deshacerlo justo después de eliminar.'**
  String get transactionDeleteMessage;

  /// No description provided for @transactionDetailTitleExpense.
  ///
  /// In es, this message translates to:
  /// **'Detalle del gasto'**
  String get transactionDetailTitleExpense;

  /// No description provided for @transactionDetailTitleIncome.
  ///
  /// In es, this message translates to:
  /// **'Detalle del ingreso'**
  String get transactionDetailTitleIncome;

  /// No description provided for @transactionDetailTitleTransfer.
  ///
  /// In es, this message translates to:
  /// **'Detalle de la transferencia'**
  String get transactionDetailTitleTransfer;

  /// No description provided for @transactionDetailSource.
  ///
  /// In es, this message translates to:
  /// **'Registrado como {source}'**
  String transactionDetailSource(String source);

  /// No description provided for @transactionDetailAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get transactionDetailAccountLabel;

  /// No description provided for @transactionDetailAccountFromLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta origen'**
  String get transactionDetailAccountFromLabel;

  /// No description provided for @transactionDetailAccountToLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta destino'**
  String get transactionDetailAccountToLabel;

  /// No description provided for @transactionDetailCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get transactionDetailCategoryLabel;

  /// No description provided for @transactionDetailDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get transactionDetailDateLabel;

  /// No description provided for @transactionDetailNoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get transactionDetailNoteLabel;

  /// No description provided for @transactionDetailNoNote.
  ///
  /// In es, this message translates to:
  /// **'Sin nota'**
  String get transactionDetailNoNote;

  /// No description provided for @transactionDetailSourceLabel.
  ///
  /// In es, this message translates to:
  /// **'Origen'**
  String get transactionDetailSourceLabel;

  /// No description provided for @transactionDetailTagsLabel.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas'**
  String get transactionDetailTagsLabel;

  /// No description provided for @transactionDetailTransferSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get transactionDetailTransferSubtitle;

  /// No description provided for @transactionDetailDeleteLink.
  ///
  /// In es, this message translates to:
  /// **'Eliminar movimiento'**
  String get transactionDetailDeleteLink;

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

  /// No description provided for @tagFilterSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar etiqueta'**
  String get tagFilterSearchHint;

  /// No description provided for @tagFilterEmpty.
  ///
  /// In es, this message translates to:
  /// **'No encontramos etiquetas con ese nombre'**
  String get tagFilterEmpty;

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
  /// **'Sincronizando…'**
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

  /// Caption izquierdo de la barra de progreso del hero con presupuesto (HU-03, aOhoY): porcentaje gastado del presupuesto global mensual y su monto total.
  ///
  /// In es, this message translates to:
  /// **'{pct}% de {amount}'**
  String homeHeroBudgetProgress(int pct, String amount);

  /// Caption derecho de la barra de progreso del hero con presupuesto (HU-03, aOhoY): días que quedan del periodo mensual vigente.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{último día} one{falta {count} día} other{faltan {count} días}}'**
  String homeHeroBudgetDaysLeft(int count);

  /// Caption de la fila de accesos directos del Home (HU-05b).
  ///
  /// In es, this message translates to:
  /// **'Acceso rápido'**
  String get homeQuickAccessTitle;

  /// Label del chip de acceso rápido a Pagos programados; distinto de moreScheduledPayments ("Recurrentes") que se usa en el hub Más.
  ///
  /// In es, this message translates to:
  /// **'Pagos programados'**
  String get homeQuickAccessScheduledPayments;

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
  /// **'Selecciona el mes'**
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

  /// No description provided for @homeExitConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Salir de Billetudo?'**
  String get homeExitConfirmTitle;

  /// No description provided for @homeExitConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Puedes volver cuando quieras, tus datos se quedan guardados.'**
  String get homeExitConfirmMessage;

  /// No description provided for @homeExitConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get homeExitConfirmAction;

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

  /// No description provided for @moreAccountsDescription.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tus cuentas y saldos'**
  String get moreAccountsDescription;

  /// No description provided for @moreCategoriesDescription.
  ///
  /// In es, this message translates to:
  /// **'Organiza tus gastos e ingresos'**
  String get moreCategoriesDescription;

  /// No description provided for @moreDebts.
  ///
  /// In es, this message translates to:
  /// **'Deudas'**
  String get moreDebts;

  /// No description provided for @moreDebtsDescription.
  ///
  /// In es, this message translates to:
  /// **'Sigue tus deudas y pagos'**
  String get moreDebtsDescription;

  /// No description provided for @moreScheduledPayments.
  ///
  /// In es, this message translates to:
  /// **'Recurrentes'**
  String get moreScheduledPayments;

  /// No description provided for @moreScheduledPaymentsDescription.
  ///
  /// In es, this message translates to:
  /// **'Pagos e ingresos automáticos'**
  String get moreScheduledPaymentsDescription;

  /// No description provided for @moreReports.
  ///
  /// In es, this message translates to:
  /// **'Gráficas e informes'**
  String get moreReports;

  /// No description provided for @moreReportsDescription.
  ///
  /// In es, this message translates to:
  /// **'Visualiza tus finanzas con gráficas'**
  String get moreReportsDescription;

  /// No description provided for @moreImportExport.
  ///
  /// In es, this message translates to:
  /// **'Importar y exportar'**
  String get moreImportExport;

  /// No description provided for @moreImportExportDescription.
  ///
  /// In es, this message translates to:
  /// **'Respalda o trae tus datos'**
  String get moreImportExportDescription;

  /// No description provided for @moreSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get moreSettings;

  /// No description provided for @moreSettingsDescription.
  ///
  /// In es, this message translates to:
  /// **'Preferencias y tu cuenta'**
  String get moreSettingsDescription;

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

  /// HU-06: mensaje con el opt-in de borrado APAGADO.
  ///
  /// In es, this message translates to:
  /// **'Tus cuentas y movimientos seguirán guardados en este teléfono. Dejarás de sincronizar hasta que vuelvas a iniciar sesión.'**
  String get authSignOutSheetMessage;

  /// HU-06: mensaje con el opt-in ACTIVADO. Pierde la promesa de conservación a propósito: con la casilla marcada sería falsa.
  ///
  /// In es, this message translates to:
  /// **'Dejarás de sincronizar hasta que vuelvas a iniciar sesión.'**
  String get authSignOutSheetMessageDeleting;

  /// No description provided for @authSignOutCta.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get authSignOutCta;

  /// HU-06: CTA cuando el opt-in de borrado está activado.
  ///
  /// In es, this message translates to:
  /// **'Borrar y salir'**
  String get authSignOutDeleteCta;

  /// No description provided for @authSignOutDeleteOptInTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrar también los datos de este teléfono'**
  String get authSignOutDeleteOptInTitle;

  /// No description provided for @authSignOutDeleteOptInSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta en la nube no se toca: al volver a entrar, los recuperas.'**
  String get authSignOutDeleteOptInSubtitle;

  /// No description provided for @authSignOutUnsyncedTitle.
  ///
  /// In es, this message translates to:
  /// **'Hay cambios que aún no se han subido'**
  String get authSignOutUnsyncedTitle;

  /// HU-06: la concordancia alcanza cinco palabras (sigue/siguen, guardado/guardados, ese/esos cambio(s), quedará/quedarán), por eso el plural ICU cubre la frase entera y no la palabra suelta.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cambio sigue guardado solo en este teléfono. Si borras ahora, ese cambio no quedará en la nube.} other{{count} cambios siguen guardados solo en este teléfono. Si borras ahora, esos cambios no quedarán en la nube.}}'**
  String authSignOutUnsyncedBody(int count);

  /// HU-06: el wipe falló después de cerrar sesión. No reportar un éxito falso.
  ///
  /// In es, this message translates to:
  /// **'Cerramos tu sesión, pero no pudimos borrar los datos de este teléfono. Siguen aquí.'**
  String get authSignOutWipeErrorMessage;

  /// HU-06: el cierre de sesión falló, por lo que el borrado se canceló. Deja claro que los datos siguen intactos para que el usuario reintente.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cerrar tu sesión, así que no borramos nada de este teléfono. Inténtalo de nuevo.'**
  String get authSignOutFailedMessage;

  /// No description provided for @authDeleteStep1Title.
  ///
  /// In es, this message translates to:
  /// **'Eliminar tu cuenta'**
  String get authDeleteStep1Title;

  /// No description provided for @authDeleteStep1Message.
  ///
  /// In es, this message translates to:
  /// **'Esta acción es irreversible. Se borrarán para siempre todos tus datos en la nube: cuentas, movimientos, categorías y todo lo demás asociado a tu cuenta.'**
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
  /// **'Hubo un problema para conectar con el servidor y no pudimos completar la solicitud. Tus datos siguen a salvo en este dispositivo — intenta de nuevo.'**
  String get authDeleteStep1ErrorMessage;

  /// No description provided for @authDeleteStep2Title.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hacemos con tus datos en este teléfono?'**
  String get authDeleteStep2Title;

  /// No description provided for @authDeleteStep2Subtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta en la nube ya fue eliminada. Elige qué pasa con lo que queda guardado aquí, en este dispositivo.'**
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

  /// No description provided for @settingsBudgetSection.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get settingsBudgetSection;

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

  /// No description provided for @settingsAppearanceLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsAppearanceLight;

  /// No description provided for @settingsAppearanceDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsAppearanceDark;

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

  /// No description provided for @budgetsEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Crea uno para controlar tu gasto sin esfuerzo'**
  String get budgetsEmptyDescription;

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

  /// No description provided for @budgetsMenuTooltip.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get budgetsMenuTooltip;

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

  /// No description provided for @budgetAtRiskLabel.
  ///
  /// In es, this message translates to:
  /// **'Podría exceder por'**
  String get budgetAtRiskLabel;

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

  /// No description provided for @budgetEndsInDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Último día} one{Termina en {count} día} other{Termina en {count} días}}'**
  String budgetEndsInDays(int count);

  /// No description provided for @budgetProgressBreakdown.
  ///
  /// In es, this message translates to:
  /// **'{spent} de {amount}'**
  String budgetProgressBreakdown(String spent, String amount);

  /// No description provided for @budgetActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos del periodo'**
  String get budgetActivityTitle;

  /// No description provided for @budgetActivityCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} movimiento} other{{count} movimientos}}'**
  String budgetActivityCount(int count);

  /// No description provided for @budgetActivityEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin movimientos en este periodo'**
  String get budgetActivityEmpty;

  /// No description provided for @budgetScheduledLabel.
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get budgetScheduledLabel;

  /// No description provided for @budgetScheduledEntrySub.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} pago próximo} other{{count} pagos próximos}}'**
  String budgetScheduledEntrySub(int count);

  /// No description provided for @budgetScheduledEntrySubRisk.
  ///
  /// In es, this message translates to:
  /// **'Excedería el presupuesto por {amount}'**
  String budgetScheduledEntrySubRisk(String amount);

  /// No description provided for @budgetScheduledCaption.
  ///
  /// In es, this message translates to:
  /// **'+ {amount} programado (llega a {pct}% si se ejecuta)'**
  String budgetScheduledCaption(String amount, int pct);

  /// No description provided for @budgetScheduledCaptionRisk.
  ///
  /// In es, this message translates to:
  /// **'+ {amount} programado — excedería el presupuesto por {overage}'**
  String budgetScheduledCaptionRisk(String amount, String overage);

  /// No description provided for @budgetScheduledSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Pagos programados del período'**
  String get budgetScheduledSheetTitle;

  /// No description provided for @budgetScheduledSheetHint.
  ///
  /// In es, this message translates to:
  /// **'Suman {amount} de lo reservado este período.'**
  String budgetScheduledSheetHint(String amount);

  /// No description provided for @budgetScheduledSheetEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes pagos programados en este período'**
  String get budgetScheduledSheetEmpty;

  /// Subtítulo de una fila de pago programado dentro del presupuesto: fecha de la próxima ocurrencia y la cuenta asociada.
  ///
  /// In es, this message translates to:
  /// **'Próximo: {date} · {accountName}'**
  String budgetScheduledRowSubtitle(String date, String accountName);

  /// No description provided for @budgetLoadMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get budgetLoadMore;

  /// No description provided for @budgetOneOffWindow.
  ///
  /// In es, this message translates to:
  /// **'Ventana única'**
  String get budgetOneOffWindow;

  /// No description provided for @budgetPeriodPreviousTooltip.
  ///
  /// In es, this message translates to:
  /// **'Periodo anterior'**
  String get budgetPeriodPreviousTooltip;

  /// No description provided for @budgetPeriodNextTooltip.
  ///
  /// In es, this message translates to:
  /// **'Periodo siguiente'**
  String get budgetPeriodNextTooltip;

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

  /// No description provided for @budgetActionDeleteBudget.
  ///
  /// In es, this message translates to:
  /// **'Eliminar presupuesto'**
  String get budgetActionDeleteBudget;

  /// No description provided for @budgetActionAdjustAmount.
  ///
  /// In es, this message translates to:
  /// **'Ajustar monto — próximo período'**
  String get budgetActionAdjustAmount;

  /// No description provided for @budgetDetailActionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Acciones del presupuesto'**
  String get budgetDetailActionsSubtitle;

  /// No description provided for @budgetDeleteConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Este presupuesto se eliminará. Podrás deshacerlo justo después de eliminar.'**
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

  /// No description provided for @budgetFormIconNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Ícono y nombre'**
  String get budgetFormIconNameLabel;

  /// No description provided for @budgetFormRowValue.
  ///
  /// In es, this message translates to:
  /// **'{label}: {value}'**
  String budgetFormRowValue(String label, String value);

  /// No description provided for @budgetFormScopeAllHint.
  ///
  /// In es, this message translates to:
  /// **'Incluye todo tu gasto: todas las cuentas y categorías.'**
  String get budgetFormScopeAllHint;

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

  /// No description provided for @budgetFormEndHint.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get budgetFormEndHint;

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
  /// **'Avisarme cuando gaste el…'**
  String get budgetThresholdTitle;

  /// No description provided for @budgetThresholdHint.
  ///
  /// In es, this message translates to:
  /// **'Te enviaremos un aviso local al llegar a ese % — sin costo.'**
  String get budgetThresholdHint;

  /// No description provided for @budgetThresholdRecommended.
  ///
  /// In es, this message translates to:
  /// **'Recomendado'**
  String get budgetThresholdRecommended;

  /// No description provided for @budgetThresholdCustom.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get budgetThresholdCustom;

  /// No description provided for @budgetThresholdCustomSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Define tu propio %'**
  String get budgetThresholdCustomSubtitle;

  /// No description provided for @budgetThresholdCustomTitle.
  ///
  /// In es, this message translates to:
  /// **'Define tu propio %'**
  String get budgetThresholdCustomTitle;

  /// No description provided for @budgetThresholdCustomHint.
  ///
  /// In es, this message translates to:
  /// **'Ajusta el porcentaje en pasos de 5.'**
  String get budgetThresholdCustomHint;

  /// No description provided for @budgetThresholdOffSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Desactiva la alerta de este presupuesto'**
  String get budgetThresholdOffSubtitle;

  /// No description provided for @budgetThresholdDecrease.
  ///
  /// In es, this message translates to:
  /// **'Bajar el porcentaje'**
  String get budgetThresholdDecrease;

  /// No description provided for @budgetThresholdIncrease.
  ///
  /// In es, this message translates to:
  /// **'Subir el porcentaje'**
  String get budgetThresholdIncrease;

  /// No description provided for @budgetIconSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegir ícono'**
  String get budgetIconSheetTitle;

  /// No description provided for @budgetIconSheetHint.
  ///
  /// In es, this message translates to:
  /// **'El ícono se muestra en un fondo neutro — sin color por presupuesto.'**
  String get budgetIconSheetHint;

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

  /// No description provided for @budgetsHistoryEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Cuando cierres uno, lo encontrarás aquí para consultarlo o reactivarlo'**
  String get budgetsHistoryEmptyDescription;

  /// No description provided for @budgetsHistoryLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tu histórico'**
  String get budgetsHistoryLoading;

  /// No description provided for @budgetDetailLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando el presupuesto'**
  String get budgetDetailLoading;

  /// No description provided for @budgetFormLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando el formulario'**
  String get budgetFormLoading;

  /// No description provided for @budgetClosedOn.
  ///
  /// In es, this message translates to:
  /// **'Cerrado {date}'**
  String budgetClosedOn(String date);

  /// No description provided for @budgetsHistorySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos cerrados'**
  String get budgetsHistorySubtitle;

  /// No description provided for @budgetsHistoryHint.
  ///
  /// In es, this message translates to:
  /// **'Los conservas sin borrar. Puedes reactivarlos cuando quieras.'**
  String get budgetsHistoryHint;

  /// No description provided for @budgetsMenuOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get budgetsMenuOptions;

  /// No description provided for @budgetsMenuHistorySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos cerrados'**
  String get budgetsMenuHistorySubtitle;

  /// No description provided for @budgetsMenuEnableEnvelope.
  ///
  /// In es, this message translates to:
  /// **'Activar modo sobres'**
  String get budgetsMenuEnableEnvelope;

  /// No description provided for @budgetsMenuEnableEnvelopeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reparte todo tu ingreso en sobres'**
  String get budgetsMenuEnableEnvelopeSubtitle;

  /// No description provided for @budgetsMenuDisableEnvelopeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a la lista normal'**
  String get budgetsMenuDisableEnvelopeSubtitle;

  /// No description provided for @budgetsEnvelopeBadge.
  ///
  /// In es, this message translates to:
  /// **'Modo sobres'**
  String get budgetsEnvelopeBadge;

  /// No description provided for @budgetsEnvelopeIncome.
  ///
  /// In es, this message translates to:
  /// **'Ingreso {income}'**
  String budgetsEnvelopeIncome(String income);

  /// No description provided for @budgetsEnvelopeAssigned.
  ///
  /// In es, this message translates to:
  /// **'Asignado {assigned}'**
  String budgetsEnvelopeAssigned(String assigned);

  /// No description provided for @budgetsEnvelopeNudge.
  ///
  /// In es, this message translates to:
  /// **'Casi lo logras: dale un trabajo a los {amount} restantes.'**
  String budgetsEnvelopeNudge(String amount);

  /// No description provided for @budgetsEnvelopeNudgeOver.
  ///
  /// In es, this message translates to:
  /// **'Asignaste {amount} más de lo que entró. Ajusta un sobre cuando quieras.'**
  String budgetsEnvelopeNudgeOver(String amount);

  /// No description provided for @budgetAssignedLabel.
  ///
  /// In es, this message translates to:
  /// **'Asignado'**
  String get budgetAssignedLabel;

  /// No description provided for @budgetReactivate.
  ///
  /// In es, this message translates to:
  /// **'Reactivar'**
  String get budgetReactivate;

  /// No description provided for @budgetResultWithin.
  ///
  /// In es, this message translates to:
  /// **'Terminó dentro del presupuesto'**
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
  /// **'Reparte todo tu ingreso en sobres'**
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
  /// **'Es una forma de presupuestar donde le das un trabajo a cada peso. Repartes todo tu ingreso del mes en \'sobres\' —tus presupuestos— hasta que no quede nada sin asignar.'**
  String get envelopeInfoBody;

  /// No description provided for @envelopeInfoBulletJobs.
  ///
  /// In es, this message translates to:
  /// **'Así decides a dónde va tu plata antes de gastarla: gastar, ahorrar o pagar deudas.'**
  String get envelopeInfoBulletJobs;

  /// No description provided for @envelopeInfoBulletZero.
  ///
  /// In es, this message translates to:
  /// **'Cuando \'Sin asignar\' llega a \$0, cada peso tiene un propósito.'**
  String get envelopeInfoBulletZero;

  /// No description provided for @envelopeInfoReassure.
  ///
  /// In es, this message translates to:
  /// **'Es opcional y no te bloquea nada. Actívalo o desactívalo cuando quieras.'**
  String get envelopeInfoReassure;

  /// No description provided for @envelopeInfoActivate.
  ///
  /// In es, this message translates to:
  /// **'Activar modo sobres'**
  String get envelopeInfoActivate;

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
  /// **'Sin asignar este mes'**
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

  /// Caption bajo el spinner indeterminado del splash inicial (design-system/billetudo/pages/splash.md, nodo M0TfmS), mientras arrancan Drift/PowerSync antes de mostrar la app real.
  ///
  /// In es, this message translates to:
  /// **'Cargando tus finanzas...'**
  String get splashLoadingCaption;

  /// Primera parte del wordmark 'billetudo' (lib/core/widgets/brand_wordmark.dart). Igual en todos los locales a propósito — es el nombre de marca, no una traducción real; se parte en 3 claves (en vez de una sola indexada) para no depender de indexado frágil sobre un string.
  ///
  /// In es, this message translates to:
  /// **'b'**
  String get brandWordmarkPrefix;

  /// La 'i' sin punto (U+0131) del wordmark — el punto lo hace la moneda (CoinGlyph), nunca ambos a la vez (assets/branding/MARCA.md). Igual en todos los locales.
  ///
  /// In es, this message translates to:
  /// **'ı'**
  String get brandWordmarkDotlessI;

  /// Última parte del wordmark 'billetudo'. Igual en todos los locales a propósito — nombre de marca, no traducción real.
  ///
  /// In es, this message translates to:
  /// **'lletudo'**
  String get brandWordmarkSuffix;

  /// No description provided for @scheduledPaymentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Pagos programados'**
  String get scheduledPaymentsTitle;

  /// No description provided for @scheduledPaymentsAdd.
  ///
  /// In es, this message translates to:
  /// **'Nuevo pago programado'**
  String get scheduledPaymentsAdd;

  /// No description provided for @scheduledPaymentsLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tus pagos programados'**
  String get scheduledPaymentsLoading;

  /// No description provided for @scheduledPaymentsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes pagos programados'**
  String get scheduledPaymentsEmptyMessage;

  /// No description provided for @scheduledPaymentsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus pagos programados'**
  String get scheduledPaymentsErrorTitle;

  /// No description provided for @scheduledPaymentsErrorLocalFirst.
  ///
  /// In es, this message translates to:
  /// **'Tus datos siguen guardados en tu dispositivo. Intenta de nuevo.'**
  String get scheduledPaymentsErrorLocalFirst;

  /// No description provided for @scheduledPaymentsActiveCount.
  ///
  /// In es, this message translates to:
  /// **'Activos · {count}'**
  String scheduledPaymentsActiveCount(int count);

  /// No description provided for @scheduledPendingTitle.
  ///
  /// In es, this message translates to:
  /// **'Por confirmar'**
  String get scheduledPendingTitle;

  /// No description provided for @scheduledPendingEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes pagos por confirmar.'**
  String get scheduledPendingEmpty;

  /// No description provided for @scheduledReviewAll.
  ///
  /// In es, this message translates to:
  /// **'Revisar todas'**
  String get scheduledReviewAll;

  /// No description provided for @scheduledPendingBadge.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de confirmar'**
  String get scheduledPendingBadge;

  /// No description provided for @scheduledOnceBadge.
  ///
  /// In es, this message translates to:
  /// **'Pago único'**
  String get scheduledOnceBadge;

  /// No description provided for @scheduledInactiveBadge.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get scheduledInactiveBadge;

  /// No description provided for @scheduledConfirmationSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar pago'**
  String get scheduledConfirmationSheetTitle;

  /// No description provided for @scheduledConfirmationSheetConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get scheduledConfirmationSheetConfirm;

  /// No description provided for @scheduledConfirmationSheetSkip.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get scheduledConfirmationSheetSkip;

  /// No description provided for @scheduledConfirmationSheetSnooze.
  ///
  /// In es, this message translates to:
  /// **'Posponer'**
  String get scheduledConfirmationSheetSnooze;

  /// No description provided for @scheduledGuidedReviewPosition.
  ///
  /// In es, this message translates to:
  /// **'Pago {position} de {total}'**
  String scheduledGuidedReviewPosition(int position, int total);

  /// No description provided for @scheduledUndoSkipMessage.
  ///
  /// In es, this message translates to:
  /// **'Pago omitido'**
  String get scheduledUndoSkipMessage;

  /// No description provided for @scheduledUndoSnoozeMessage.
  ///
  /// In es, this message translates to:
  /// **'Pago pospuesto'**
  String get scheduledUndoSnoozeMessage;

  /// No description provided for @scheduledSnoozeSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Posponer pago'**
  String get scheduledSnoozeSheetTitle;

  /// No description provided for @scheduledSnoozeSheetSave.
  ///
  /// In es, this message translates to:
  /// **'Posponer'**
  String get scheduledSnoozeSheetSave;

  /// No description provided for @scheduledDeleteSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este pago programado?'**
  String get scheduledDeleteSheetTitle;

  /// No description provided for @scheduledDeleteSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Se detiene la generación de pagos futuros. Las transacciones que ya generó se conservan en tu historial.'**
  String get scheduledDeleteSheetMessage;

  /// No description provided for @scheduledPaymentFormNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo pago programado'**
  String get scheduledPaymentFormNewTitle;

  /// No description provided for @scheduledPaymentFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar pago programado'**
  String get scheduledPaymentFormEditTitle;

  /// No description provided for @scheduledPaymentFormNextDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Primer pago'**
  String get scheduledPaymentFormNextDateLabel;

  /// No description provided for @scheduledPaymentFormOnceDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha del pago'**
  String get scheduledPaymentFormOnceDateLabel;

  /// No description provided for @scheduledPaymentFormModeSectionLabel.
  ///
  /// In es, this message translates to:
  /// **'Al llegar la fecha'**
  String get scheduledPaymentFormModeSectionLabel;

  /// No description provided for @scheduledPaymentFormTagNew.
  ///
  /// In es, this message translates to:
  /// **'Etiqueta'**
  String get scheduledPaymentFormTagNew;

  /// No description provided for @scheduledPaymentFormFrequencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get scheduledPaymentFormFrequencyLabel;

  /// No description provided for @scheduledPaymentFormCategoryMoreLabel.
  ///
  /// In es, this message translates to:
  /// **'Otra'**
  String get scheduledPaymentFormCategoryMoreLabel;

  /// No description provided for @scheduledPaymentFormIntervalStepperLabel.
  ///
  /// In es, this message translates to:
  /// **'Repetir cada'**
  String get scheduledPaymentFormIntervalStepperLabel;

  /// No description provided for @scheduledPaymentFormEndDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Termina'**
  String get scheduledPaymentFormEndDateLabel;

  /// No description provided for @scheduledPaymentFormEndDateNone.
  ///
  /// In es, this message translates to:
  /// **'Para siempre'**
  String get scheduledPaymentFormEndDateNone;

  /// No description provided for @scheduledPaymentFormModeAutomaticTitle.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get scheduledPaymentFormModeAutomaticTitle;

  /// No description provided for @scheduledPaymentFormModeAutomaticSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se registra solo al llegar la fecha'**
  String get scheduledPaymentFormModeAutomaticSubtitle;

  /// No description provided for @scheduledPaymentFormModeManualTitle.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get scheduledPaymentFormModeManualTitle;

  /// No description provided for @scheduledPaymentFormModeManualSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos para que confirmes antes de afectar tu saldo'**
  String get scheduledPaymentFormModeManualSubtitle;

  /// No description provided for @scheduledPaymentFormDeleteAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar pago programado'**
  String get scheduledPaymentFormDeleteAction;

  /// No description provided for @scheduledFrequencyOnce.
  ///
  /// In es, this message translates to:
  /// **'Solo una vez'**
  String get scheduledFrequencyOnce;

  /// No description provided for @scheduledFrequencyDaily.
  ///
  /// In es, this message translates to:
  /// **'cada día'**
  String get scheduledFrequencyDaily;

  /// No description provided for @scheduledFrequencyWeekly.
  ///
  /// In es, this message translates to:
  /// **'cada semana'**
  String get scheduledFrequencyWeekly;

  /// No description provided for @scheduledFrequencyMonthly.
  ///
  /// In es, this message translates to:
  /// **'cada mes'**
  String get scheduledFrequencyMonthly;

  /// No description provided for @scheduledFrequencyYearly.
  ///
  /// In es, this message translates to:
  /// **'cada año'**
  String get scheduledFrequencyYearly;

  /// No description provided for @scheduledFrequencyChipOnce.
  ///
  /// In es, this message translates to:
  /// **'Único'**
  String get scheduledFrequencyChipOnce;

  /// No description provided for @scheduledFrequencyChipDaily.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get scheduledFrequencyChipDaily;

  /// No description provided for @scheduledFrequencyChipWeekly.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get scheduledFrequencyChipWeekly;

  /// No description provided for @scheduledFrequencyChipMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get scheduledFrequencyChipMonthly;

  /// No description provided for @scheduledFrequencyChipYearly.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get scheduledFrequencyChipYearly;

  /// No description provided for @scheduledPaymentDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle'**
  String get scheduledPaymentDetailTitle;

  /// No description provided for @scheduledPaymentDetailNextPayment.
  ///
  /// In es, this message translates to:
  /// **'Próximo pago: {date}'**
  String scheduledPaymentDetailNextPayment(String date);

  /// No description provided for @scheduledPaymentDetailHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Ya generados'**
  String get scheduledPaymentDetailHistoryTitle;

  /// No description provided for @scheduledPaymentDetailHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no se ha generado ningún movimiento de este pago programado.'**
  String get scheduledPaymentDetailHistoryEmpty;

  /// No description provided for @scheduledPaymentDetailHistorySeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver historial completo ({count})'**
  String scheduledPaymentDetailHistorySeeAll(int count);

  /// No description provided for @scheduledPaymentDetailHeroLabel.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMO PAGO'**
  String get scheduledPaymentDetailHeroLabel;

  /// No description provided for @scheduledPaymentDetailRecurrenceOnce.
  ///
  /// In es, this message translates to:
  /// **'Una sola vez el {date}'**
  String scheduledPaymentDetailRecurrenceOnce(String date);

  /// No description provided for @scheduledPaymentDetailRecurrenceForever.
  ///
  /// In es, this message translates to:
  /// **'Se repite {unit} desde el {date}, para siempre'**
  String scheduledPaymentDetailRecurrenceForever(String unit, String date);

  /// No description provided for @scheduledPaymentDetailRecurrenceUntil.
  ///
  /// In es, this message translates to:
  /// **'Se repite {unit} desde el {date}, hasta el {endDate}'**
  String scheduledPaymentDetailRecurrenceUntil(
      String unit, String date, String endDate);

  /// No description provided for @scheduledRecurrenceUnitDaily.
  ///
  /// In es, this message translates to:
  /// **'cada día'**
  String get scheduledRecurrenceUnitDaily;

  /// No description provided for @scheduledRecurrenceUnitDailyInterval.
  ///
  /// In es, this message translates to:
  /// **'cada {interval} días'**
  String scheduledRecurrenceUnitDailyInterval(int interval);

  /// No description provided for @scheduledRecurrenceUnitWeekly.
  ///
  /// In es, this message translates to:
  /// **'cada semana'**
  String get scheduledRecurrenceUnitWeekly;

  /// No description provided for @scheduledRecurrenceUnitWeeklyInterval.
  ///
  /// In es, this message translates to:
  /// **'cada {interval} semanas'**
  String scheduledRecurrenceUnitWeeklyInterval(int interval);

  /// No description provided for @scheduledRecurrenceUnitMonthly.
  ///
  /// In es, this message translates to:
  /// **'cada mes'**
  String get scheduledRecurrenceUnitMonthly;

  /// No description provided for @scheduledRecurrenceUnitMonthlyInterval.
  ///
  /// In es, this message translates to:
  /// **'cada {interval} meses'**
  String scheduledRecurrenceUnitMonthlyInterval(int interval);

  /// No description provided for @scheduledRecurrenceUnitYearly.
  ///
  /// In es, this message translates to:
  /// **'cada año'**
  String get scheduledRecurrenceUnitYearly;

  /// No description provided for @scheduledRecurrenceUnitYearlyInterval.
  ///
  /// In es, this message translates to:
  /// **'cada {interval} años'**
  String scheduledRecurrenceUnitYearlyInterval(int interval);

  /// No description provided for @scheduledPaymentDetailModeLabel.
  ///
  /// In es, this message translates to:
  /// **'Modo de registro'**
  String get scheduledPaymentDetailModeLabel;

  /// No description provided for @scheduledPaymentDetailModeAutomatic.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get scheduledPaymentDetailModeAutomatic;

  /// No description provided for @scheduledPaymentDetailModeManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get scheduledPaymentDetailModeManual;

  /// No description provided for @scheduledPaymentDetailAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get scheduledPaymentDetailAccountLabel;

  /// No description provided for @scheduledPaymentDetailStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get scheduledPaymentDetailStatusLabel;

  /// No description provided for @scheduledPaymentDetailStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get scheduledPaymentDetailStatusActive;

  /// No description provided for @scheduledPaymentDetailStatusFinished.
  ///
  /// In es, this message translates to:
  /// **'Terminada'**
  String get scheduledPaymentDetailStatusFinished;

  /// No description provided for @scheduledPaymentDetailHeroLabelExecuted.
  ///
  /// In es, this message translates to:
  /// **'PAGO EJECUTADO'**
  String get scheduledPaymentDetailHeroLabelExecuted;

  /// No description provided for @scheduledPaymentDetailTagsLabel.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas'**
  String get scheduledPaymentDetailTagsLabel;

  /// No description provided for @scheduledPaymentDetailTagsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin etiquetas'**
  String get scheduledPaymentDetailTagsEmpty;

  /// No description provided for @scheduledPaymentBridgeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Es un pago programado?'**
  String get scheduledPaymentBridgeTitle;

  /// No description provided for @scheduledPaymentBridgeMessage.
  ///
  /// In es, this message translates to:
  /// **'Elegiste una fecha futura. Puedes convertir este movimiento en un pago programado para no tener que registrarlo de nuevo.'**
  String get scheduledPaymentBridgeMessage;

  /// No description provided for @scheduledPaymentBridgeAccept.
  ///
  /// In es, this message translates to:
  /// **'Sí, programarlo'**
  String get scheduledPaymentBridgeAccept;

  /// No description provided for @scheduledPaymentBridgeDecline.
  ///
  /// In es, this message translates to:
  /// **'No, guardar como siempre'**
  String get scheduledPaymentBridgeDecline;

  /// No description provided for @scheduledFinishedCount.
  ///
  /// In es, this message translates to:
  /// **'Terminados · {count}'**
  String scheduledFinishedCount(int count);

  /// No description provided for @scheduledFinishedCaption.
  ///
  /// In es, this message translates to:
  /// **'Ya no generan movimientos. Los que crearon siguen en tus cuentas.'**
  String get scheduledFinishedCaption;

  /// No description provided for @scheduledFinishedCardChip.
  ///
  /// In es, this message translates to:
  /// **'Terminada'**
  String get scheduledFinishedCardChip;

  /// No description provided for @scheduledFinishedErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus pagos terminados'**
  String get scheduledFinishedErrorTitle;

  /// No description provided for @scheduledFinishedLastPayment.
  ///
  /// In es, this message translates to:
  /// **'Último pago · {date}'**
  String scheduledFinishedLastPayment(String date);

  /// No description provided for @scheduledPaymentsNoActiveMessage.
  ///
  /// In es, this message translates to:
  /// **'Por ahora no tienes pagos programados activos'**
  String get scheduledPaymentsNoActiveMessage;

  /// No description provided for @scheduledPaymentsNoActiveDescription.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Tu pago terminado sigue disponible en «Terminados».} other{Tus {count} pagos terminados siguen disponibles en «Terminados».}}'**
  String scheduledPaymentsNoActiveDescription(int count);

  /// No description provided for @scheduledPendingCardOverflow.
  ///
  /// In es, this message translates to:
  /// **'Ver los otros {count} pendientes'**
  String scheduledPendingCardOverflow(int count);

  /// No description provided for @scheduledPendingCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Por confirmar {count}'**
  String scheduledPendingCardTitle(int count);

  /// No description provided for @scheduledPendingCardCaption.
  ///
  /// In es, this message translates to:
  /// **'Aún no afectan tu saldo'**
  String get scheduledPendingCardCaption;

  /// No description provided for @scheduledPaymentsEmptyCta.
  ///
  /// In es, this message translates to:
  /// **'Programar un pago'**
  String get scheduledPaymentsEmptyCta;

  /// No description provided for @scheduledManualNotifyChip.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos'**
  String get scheduledManualNotifyChip;

  /// No description provided for @scheduledDueToday.
  ///
  /// In es, this message translates to:
  /// **'Vence hoy'**
  String get scheduledDueToday;

  /// No description provided for @scheduledDueOneDayAgo.
  ///
  /// In es, this message translates to:
  /// **'hace 1 día'**
  String get scheduledDueOneDayAgo;

  /// No description provided for @scheduledDueDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {count} días'**
  String scheduledDueDaysAgo(int count);

  /// No description provided for @scheduledDueInDays.
  ///
  /// In es, this message translates to:
  /// **'en {count} días'**
  String scheduledDueInDays(int count);

  /// No description provided for @scheduledDueInOneDay.
  ///
  /// In es, this message translates to:
  /// **'en 1 día'**
  String get scheduledDueInOneDay;

  /// No description provided for @scheduledConfirmationSheetScopeNote.
  ///
  /// In es, this message translates to:
  /// **'Lo que edites aplica solo a este pago. La plantilla sigue igual y el próximo mes vuelve a proponer {amount}.'**
  String scheduledConfirmationSheetScopeNote(String amount);

  /// No description provided for @scheduledConfirmationSheetAccumulatedTitle.
  ///
  /// In es, this message translates to:
  /// **'Tienes {count} pagos de {template} sin confirmar'**
  String scheduledConfirmationSheetAccumulatedTitle(int count, String template);

  /// No description provided for @scheduledConfirmationSheetAccumulatedSub.
  ///
  /// In es, this message translates to:
  /// **'Ahora confirmas la más antigua, del {date}. {others, plural, =1{La otra sigue en tu lista.} other{Las otras {others} siguen en tu lista.}}'**
  String scheduledConfirmationSheetAccumulatedSub(String date, int others);

  /// No description provided for @scheduledConfirmationSheetAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto a registrar'**
  String get scheduledConfirmationSheetAmountLabel;

  /// No description provided for @scheduledConfirmationSheetTransferAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto a transferir'**
  String get scheduledConfirmationSheetTransferAmountLabel;

  /// No description provided for @scheduledConfirmationSheetSourceAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta origen'**
  String get scheduledConfirmationSheetSourceAccountLabel;

  /// No description provided for @scheduledConfirmationSheetTargetAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta destino'**
  String get scheduledConfirmationSheetTargetAccountLabel;

  /// No description provided for @scheduledDetailActionsSheetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Acciones del pago programado'**
  String get scheduledDetailActionsSheetSubtitle;

  /// No description provided for @scheduledDetailActionsSnooze.
  ///
  /// In es, this message translates to:
  /// **'Posponer este pago'**
  String get scheduledDetailActionsSnooze;

  /// No description provided for @scheduledDetailActionsDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar pago programado'**
  String get scheduledDetailActionsDelete;

  /// No description provided for @scheduledSnoozeSheetSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige la nueva fecha'**
  String get scheduledSnoozeSheetSectionTitle;

  /// No description provided for @scheduledConfirmationSheetEditTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar plantilla'**
  String get scheduledConfirmationSheetEditTooltip;

  /// No description provided for @scheduledGuidedReviewExit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get scheduledGuidedReviewExit;

  /// No description provided for @scheduledGuidedReviewConfirmNext.
  ///
  /// In es, this message translates to:
  /// **'Confirmar y siguiente'**
  String get scheduledGuidedReviewConfirmNext;

  /// No description provided for @scheduledSnoozeContextLine.
  ///
  /// In es, this message translates to:
  /// **'Vencía el {date} · muévelo hacia adelante'**
  String scheduledSnoozeContextLine(String date);

  /// No description provided for @budgetAdjustSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustar monto — solo el próximo período'**
  String get budgetAdjustSheetTitle;

  /// No description provided for @budgetAdjustSheetHint.
  ///
  /// In es, this message translates to:
  /// **'El resto de tus períodos sigue igual, sin que tengas que hacer nada después.'**
  String get budgetAdjustSheetHint;

  /// No description provided for @budgetAdjustCurrentAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto actual ({range})'**
  String budgetAdjustCurrentAmountLabel(String range);

  /// No description provided for @budgetAdjustNewAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Nuevo monto para el próximo período ({range})'**
  String budgetAdjustNewAmountLabel(String range);

  /// No description provided for @budgetAdjustExplainer.
  ///
  /// In es, this message translates to:
  /// **'A partir del {effectiveDate} tu presupuesto será de {newAmount}. Desde {resumeDate} vuelve automáticamente a {originalAmount} — no tienes que hacer nada.'**
  String budgetAdjustExplainer(String effectiveDate, String newAmount,
      String resumeDate, String originalAmount);

  /// No description provided for @budgetAdjustApplyCta.
  ///
  /// In es, this message translates to:
  /// **'Aplicar cambios'**
  String get budgetAdjustApplyCta;

  /// No description provided for @budgetAdjustRemoveCta.
  ///
  /// In es, this message translates to:
  /// **'Quitar ajuste'**
  String get budgetAdjustRemoveCta;

  /// No description provided for @budgetAdjustBannerLabel.
  ///
  /// In es, this message translates to:
  /// **'Ajuste de monto próximo'**
  String get budgetAdjustBannerLabel;

  /// No description provided for @budgetAdjustBannerSub.
  ///
  /// In es, this message translates to:
  /// **'{amount} el próximo período'**
  String budgetAdjustBannerSub(String amount);

  /// No description provided for @budgetAdjustScheduledSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Ajuste programado para tu próximo período.'**
  String get budgetAdjustScheduledSnackbar;

  /// No description provided for @budgetAdjustUpdatedSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Ajuste actualizado.'**
  String get budgetAdjustUpdatedSnackbar;

  /// No description provided for @budgetAdjustCancelledSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Ajuste cancelado — tu próximo período vuelve al monto habitual.'**
  String get budgetAdjustCancelledSnackbar;
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
