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

  /// Etiqueta compartida del botón 'Ver más' que revela más filas de una lista paginada en el sitio (presupuestos, deudas, metas, pagos programados).
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get commonLoadMore;

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

  /// No description provided for @commonClear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get commonClear;

  /// No description provided for @commonClearAll.
  ///
  /// In es, this message translates to:
  /// **'Limpiar todo'**
  String get commonClearAll;

  /// No description provided for @commonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get commonDone;

  /// No description provided for @commonRecommended.
  ///
  /// In es, this message translates to:
  /// **'Recomendado'**
  String get commonRecommended;

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

  /// Botón secundario de la hoja puente 'necesitas una cuenta' (15-gate-cuenta.md).
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get accountGateNotNow;

  /// No description provided for @accountGateCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get accountGateCreateAccount;

  /// No description provided for @accountGateMovementTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera cuenta'**
  String get accountGateMovementTitle;

  /// No description provided for @accountGateMovementMessage.
  ///
  /// In es, this message translates to:
  /// **'Para registrar movimientos necesitas una cuenta activa. Créala ahora y seguimos justo con tu movimiento.'**
  String get accountGateMovementMessage;

  /// No description provided for @accountGateTransferZeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitas dos cuentas para transferir'**
  String get accountGateTransferZeroTitle;

  /// No description provided for @accountGateTransferZeroMessage.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes ninguna. Crea la primera para empezar (luego te pedimos la segunda).'**
  String get accountGateTransferZeroMessage;

  /// No description provided for @accountGateTransferOneTitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitas una segunda cuenta'**
  String get accountGateTransferOneTitle;

  /// No description provided for @accountGateTransferOneMessage.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes una cuenta activa. Crea otra para completar la transferencia entre ellas.'**
  String get accountGateTransferOneMessage;

  /// No description provided for @accountGateScheduledPaymentTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea una cuenta para tu pago programado'**
  String get accountGateScheduledPaymentTitle;

  /// No description provided for @accountGateScheduledPaymentMessage.
  ///
  /// In es, this message translates to:
  /// **'Los pagos programados salen de una cuenta. Créala ahora y seguimos armando el tuyo.'**
  String get accountGateScheduledPaymentMessage;

  /// No description provided for @accountGateDebtCashTitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitas una cuenta para este movimiento'**
  String get accountGateDebtCashTitle;

  /// No description provided for @accountGateDebtCashMessage.
  ///
  /// In es, this message translates to:
  /// **'Este abono o desembolso mueve dinero real, así que hace falta una cuenta. Créala y seguimos con tu deuda.'**
  String get accountGateDebtCashMessage;

  /// No description provided for @accountGateGoalMovementTitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitas una cuenta para este aporte'**
  String get accountGateGoalMovementTitle;

  /// No description provided for @accountGateGoalMovementMessage.
  ///
  /// In es, this message translates to:
  /// **'Mover dinero real hacia o desde tu meta requiere una cuenta. Créala y seguimos.'**
  String get accountGateGoalMovementMessage;

  /// No description provided for @accountGateLinkMovementTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay movimientos para enlazar'**
  String get accountGateLinkMovementTitle;

  /// No description provided for @accountGateLinkMovementMessage.
  ///
  /// In es, this message translates to:
  /// **'Enlazar requiere elegir entre tus movimientos, y esos nacen de una cuenta. Crea la primera y seguimos.'**
  String get accountGateLinkMovementMessage;

  /// No description provided for @accountGateBudgetTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea una cuenta para tu presupuesto'**
  String get accountGateBudgetTitle;

  /// No description provided for @accountGateBudgetMessage.
  ///
  /// In es, this message translates to:
  /// **'Los presupuestos se arman sobre tus cuentas reales. Crea la primera y seguimos armando el tuyo.'**
  String get accountGateBudgetMessage;

  /// No description provided for @accountGateGoalLinkedAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Vincula una cuenta a tu meta'**
  String get accountGateGoalLinkedAccountTitle;

  /// No description provided for @accountGateGoalLinkedAccountMessage.
  ///
  /// In es, this message translates to:
  /// **'Es opcional: puedes crear tu meta sin cuenta vinculada. Si quieres asociarla a una cuenta real, créala aquí.'**
  String get accountGateGoalLinkedAccountMessage;

  /// No description provided for @accountTypeCash.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In es, this message translates to:
  /// **'Cuenta corriente'**
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
  /// **'Cuenta general'**
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

  /// No description provided for @accountBalanceAdjustTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustar saldo'**
  String get accountBalanceAdjustTitle;

  /// No description provided for @accountBalanceAdjustCurrent.
  ///
  /// In es, this message translates to:
  /// **'Saldo actual: {amount}'**
  String accountBalanceAdjustCurrent(String amount);

  /// No description provided for @accountBalanceAdjustCurrentDebt.
  ///
  /// In es, this message translates to:
  /// **'Deuda actual: {amount}'**
  String accountBalanceAdjustCurrentDebt(String amount);

  /// No description provided for @accountBalanceAdjustNewLabel.
  ///
  /// In es, this message translates to:
  /// **'Nuevo saldo deseado'**
  String get accountBalanceAdjustNewLabel;

  /// No description provided for @accountBalanceAdjustNewDebtLabel.
  ///
  /// In es, this message translates to:
  /// **'Nueva deuda'**
  String get accountBalanceAdjustNewDebtLabel;

  /// No description provided for @accountBalanceAdjustHowLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo quieres aplicarlo?'**
  String get accountBalanceAdjustHowLabel;

  /// No description provided for @accountBalanceAdjustRegisterTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar ajuste'**
  String get accountBalanceAdjustRegisterTitle;

  /// No description provided for @accountBalanceAdjustRegisterBody.
  ///
  /// In es, this message translates to:
  /// **'Creamos un movimiento con fecha de hoy por la diferencia ({diff}). Suma a tus reportes y presupuestos.'**
  String accountBalanceAdjustRegisterBody(String diff);

  /// No description provided for @accountBalanceAdjustCorrectTitle.
  ///
  /// In es, this message translates to:
  /// **'Corregir saldo inicial'**
  String get accountBalanceAdjustCorrectTitle;

  /// No description provided for @accountBalanceAdjustCorrectBody.
  ///
  /// In es, this message translates to:
  /// **'Ajustamos tu saldo de arranque para que cuadre. No crea ningún movimiento.'**
  String get accountBalanceAdjustCorrectBody;

  /// No description provided for @accountBalanceAdjustApplyCta.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get accountBalanceAdjustApplyCta;

  /// No description provided for @accountBalanceAdjustError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos ajustar el saldo. Intenta de nuevo.'**
  String get accountBalanceAdjustError;

  /// No description provided for @accountBalanceAdjustNote.
  ///
  /// In es, this message translates to:
  /// **'Ajuste de saldo'**
  String get accountBalanceAdjustNote;

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
  /// **'Últimos 4 dígitos de la cuenta'**
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

  /// No description provided for @accountErrorNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un nombre para la cuenta.'**
  String get accountErrorNameRequired;

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

  /// No description provided for @categoryErrorNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un nombre para la categoría.'**
  String get categoryErrorNameRequired;

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
  /// **'Buscar por nota'**
  String get transactionsSearchHint;

  /// No description provided for @transactionsPeriodTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total del período'**
  String get transactionsPeriodTotalLabel;

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

  /// No description provided for @transactionsFilterBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get transactionsFilterBudget;

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

  /// Etiqueta del chip de categoría cuando hay una o más categorías activas como filtro.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 categoría} other{{count} categorías}}'**
  String transactionsFilterCategoriesSelected(int count);

  /// Etiqueta del chip de tipo cuando hay uno o más tipos activos como filtro.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 tipo} other{{count} tipos}}'**
  String transactionsFilterTypeSelected(int count);

  /// Etiqueta del chip de etiqueta cuando hay una o más etiquetas activas como filtro.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 etiqueta} other{{count} etiquetas}}'**
  String transactionsFilterTagSelected(int count);

  /// Etiqueta del saldo agregado en la barra compacta del carrusel de saldo colapsado (Mejora #2).
  ///
  /// In es, this message translates to:
  /// **'Saldo total'**
  String get transactionsBalanceTotalLabel;

  /// Texto para lectores de pantalla del saldo agregado en la barra compacta del carrusel de saldo colapsado.
  ///
  /// In es, this message translates to:
  /// **'{label}: {amount}'**
  String transactionsBalanceTotalSemantics(String label, String amount);

  /// Etiqueta del bloque de saldo en la card de cuenta normal del carrusel de saldo de Movimientos (Mejora #2), que espeja las figuras Deuda/Cupo de la variante de tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Saldo'**
  String get transactionsBalanceCardBalanceLabel;

  /// Semántica del control que colapsa el carrusel de saldo en Movimientos (Mejora #2).
  ///
  /// In es, this message translates to:
  /// **'Ocultar saldos'**
  String get transactionsBalanceCarouselCollapse;

  /// Semántica de la barra compacta que reexpande el carrusel de saldo en Movimientos (Mejora #2).
  ///
  /// In es, this message translates to:
  /// **'Mostrar saldos'**
  String get transactionsBalanceCarouselExpand;

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

  /// No description provided for @transactionErrorAmount.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto mayor a cero.'**
  String get transactionErrorAmount;

  /// No description provided for @transactionErrorTransferAccount.
  ///
  /// In es, this message translates to:
  /// **'Elige la cuenta de destino.'**
  String get transactionErrorTransferAccount;

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

  /// No description provided for @transactionFormCountsInBudgetLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Incluir en tu presupuesto?'**
  String get transactionFormCountsInBudgetLabel;

  /// No description provided for @transactionFormCountsInBudgetHintOff.
  ///
  /// In es, this message translates to:
  /// **'Actívala para que se sume a tus presupuestos y reportes.'**
  String get transactionFormCountsInBudgetHintOff;

  /// No description provided for @transactionFormCountsInBudgetHintOn.
  ///
  /// In es, this message translates to:
  /// **'Se suma a tus presupuestos y reportes.'**
  String get transactionFormCountsInBudgetHintOn;

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

  /// Tooltip/semántica del label 'mes año' del calendario, que abre la vista de selección de año.
  ///
  /// In es, this message translates to:
  /// **'Elegir año'**
  String get datePickerSelectYear;

  /// Tooltip del botón que retrocede el bloque de años visible en la vista de selección de año.
  ///
  /// In es, this message translates to:
  /// **'Años anteriores'**
  String get datePickerPreviousYears;

  /// Tooltip del botón que avanza el bloque de años visible en la vista de selección de año.
  ///
  /// In es, this message translates to:
  /// **'Años siguientes'**
  String get datePickerNextYears;

  /// Tooltip/semántica del rango de años en la vista de selección de año, que cierra esa vista sin elegir uno.
  ///
  /// In es, this message translates to:
  /// **'Volver a los meses'**
  String get datePickerBackToMonths;

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

  /// No description provided for @transactionFormKeypadConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get transactionFormKeypadConfirm;

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

  /// No description provided for @transactionDetailDebtLinkedLabel.
  ///
  /// In es, this message translates to:
  /// **'Enlazada a deuda: {debtName}'**
  String transactionDetailDebtLinkedLabel(String debtName);

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

  /// No description provided for @budgetPeriodFilterSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por presupuesto'**
  String get budgetPeriodFilterSheetTitle;

  /// No description provided for @budgetPeriodFilterEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'No tienes presupuestos activos'**
  String get budgetPeriodFilterEmptyMessage;

  /// No description provided for @transactionsUnifiedFiltersTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get transactionsUnifiedFiltersTitle;

  /// No description provided for @transactionsFiltersButtonLabel.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get transactionsFiltersButtonLabel;

  /// No description provided for @transactionsChipDateDefaultLabel.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get transactionsChipDateDefaultLabel;

  /// No description provided for @transactionsPeriodNavPreviousLabel.
  ///
  /// In es, this message translates to:
  /// **'Periodo anterior'**
  String get transactionsPeriodNavPreviousLabel;

  /// No description provided for @transactionsPeriodNavNextLabel.
  ///
  /// In es, this message translates to:
  /// **'Periodo siguiente'**
  String get transactionsPeriodNavNextLabel;

  /// No description provided for @transactionsFilterSectionBudget.
  ///
  /// In es, this message translates to:
  /// **'PRESUPUESTO'**
  String get transactionsFilterSectionBudget;

  /// No description provided for @transactionsFilterBudgetNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get transactionsFilterBudgetNone;

  /// No description provided for @transactionsFilterSectionDate.
  ///
  /// In es, this message translates to:
  /// **'FECHA'**
  String get transactionsFilterSectionDate;

  /// No description provided for @transactionsFilterDateLockedByBudget.
  ///
  /// In es, this message translates to:
  /// **'No puedes filtrar por fecha con un presupuesto activo'**
  String get transactionsFilterDateLockedByBudget;

  /// No description provided for @transactionsFilterSectionType.
  ///
  /// In es, this message translates to:
  /// **'TIPO'**
  String get transactionsFilterSectionType;

  /// No description provided for @transactionsFilterSectionCategory.
  ///
  /// In es, this message translates to:
  /// **'CATEGORÍA'**
  String get transactionsFilterSectionCategory;

  /// No description provided for @transactionsFilterSectionTag.
  ///
  /// In es, this message translates to:
  /// **'ETIQUETA'**
  String get transactionsFilterSectionTag;

  /// No description provided for @transactionsFilterTagEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes etiquetas'**
  String get transactionsFilterTagEmpty;

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

  /// Etiqueta corta de la pestaña de Pagos programados en la barra inferior.
  ///
  /// In es, this message translates to:
  /// **'Pagos'**
  String get navScheduledPayments;

  /// No description provided for @navMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get navMore;

  /// Saludo genérico del header cuando no hay cuenta ni nombre local.
  ///
  /// In es, this message translates to:
  /// **'Hola de nuevo 👋'**
  String get homeGreeting;

  /// Saludo del header cuando hay sesión, con el nombre del usuario.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name} 👋'**
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

  /// No description provided for @homeSyncSheetSyncedTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo a salvo'**
  String get homeSyncSheetSyncedTitle;

  /// No description provided for @homeSyncSheetSyncedMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu información está a salvo y sincronizada.'**
  String get homeSyncSheetSyncedMessage;

  /// No description provided for @homeSyncSheetSyncingTitle.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando…'**
  String get homeSyncSheetSyncingTitle;

  /// No description provided for @homeSyncSheetSyncingMessage.
  ///
  /// In es, this message translates to:
  /// **'Estamos guardando tus cambios en la nube. Puedes seguir usando la app.'**
  String get homeSyncSheetSyncingMessage;

  /// No description provided for @homeSyncSheetOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get homeSyncSheetOfflineTitle;

  /// No description provided for @homeSyncSheetOfflineMessage.
  ///
  /// In es, this message translates to:
  /// **'Tus datos están guardados en este teléfono. Se sincronizarán en cuanto vuelva la conexión.'**
  String get homeSyncSheetOfflineMessage;

  /// No description provided for @homeSyncSheetDismiss.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get homeSyncSheetDismiss;

  /// Etiqueta del hero con el mes visible.
  ///
  /// In es, this message translates to:
  /// **'Gastado en {month}'**
  String homeSpentInMonth(String month);

  /// Rótulo corto sobre el monto grande del hero cuando hay un presupuesto destacado (HU-05, xBv3N): aclara que el número es lo gastado, no un saldo.
  ///
  /// In es, this message translates to:
  /// **'Gastado'**
  String get homeHeroSpentKicker;

  /// Rótulo sobre el monto grande del hero cuando hay un presupuesto destacado (HU-05, xBv3N `zoZcf`): reemplaza el kicker corto 'Gastado' con el nombre del presupuesto, para que el usuario sepa qué presupuesto alimenta el hero sin tocar nada (discoverability, pages/presupuestos.md).
  ///
  /// In es, this message translates to:
  /// **'Gastado en {budgetName}'**
  String homeHeroSpentInFeaturedBudget(String budgetName);

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

  /// Tooltip and accessible name of the gear button that closes the Home quick-access strip; opens Ajustes > Orden del acceso rápido.
  ///
  /// In es, this message translates to:
  /// **'Ordenar el acceso rápido'**
  String get homeQuickAccessCustomize;

  /// Label del chip de acceso rápido a Pagos programados; mismo texto que moreScheduledPayments en el hub Más.
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

  /// Encabezado de la tira de saldos por cuenta en Inicio.
  ///
  /// In es, this message translates to:
  /// **'Mis cuentas'**
  String get homeBalancesTitle;

  /// Enlace de la tira de saldos que abre la lista de Cuentas.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get homeBalancesSeeAll;

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

  /// Tooltip/semántica del chip de mes del hero cuando no hay presupuesto destacado; abre la hoja de selección de mes.
  ///
  /// In es, this message translates to:
  /// **'Cambiar mes'**
  String get homeMonthChipTooltip;

  /// Tooltip del botón que retrocede un año en la hoja de selección de mes del hero.
  ///
  /// In es, this message translates to:
  /// **'Año anterior'**
  String get homeMonthPickerPreviousYear;

  /// Tooltip del botón que avanza un año en la hoja de selección de mes del hero.
  ///
  /// In es, this message translates to:
  /// **'Año siguiente'**
  String get homeMonthPickerNextYear;

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

  /// Etiqueta de accesibilidad del badge del avatar cuando no hay sesión (design-system/billetudo/pages/inicio.md).
  ///
  /// In es, this message translates to:
  /// **'Sin respaldo en la nube'**
  String get homeAccountAvatarNoAccount;

  /// Tooltip del botón wallet del header que abre la hoja de saldos.
  ///
  /// In es, this message translates to:
  /// **'Tu dinero'**
  String get homeWalletTooltip;

  /// Kicker del hero en el estado de sobregasto real (xRSdl).
  ///
  /// In es, this message translates to:
  /// **'Excedido por'**
  String get homeHeroOverspentKicker;

  /// Kicker fijo del hero en todo estado con saldo restante (ancla fija, xRSdl).
  ///
  /// In es, this message translates to:
  /// **'Te quedan'**
  String get homeHeroRemainingKicker;

  /// Meta Days del hero con presupuesto (xRSdl): días restantes del periodo vigente.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Último día} one{Resta {count} día} other{Restan {count} días}}'**
  String homeHeroMetaDaysLeft(int count);

  /// Hero Note del estado de riesgo de sobregiro proyectado (xRSdl KSaru).
  ///
  /// In es, this message translates to:
  /// **'Podría exceder por {amount}'**
  String homeHeroRiskNote(String amount);

  /// Nota del hero cuando el usuario nunca creó un presupuesto.
  ///
  /// In es, this message translates to:
  /// **'Sin presupuesto activo este mes'**
  String get homeHeroNoBudgetEverCreatedNote;

  /// Nota del hero cuando el usuario tiene presupuestos pero ninguno está destacado.
  ///
  /// In es, this message translates to:
  /// **'Ningún presupuesto destacado este mes'**
  String get homeHeroNoBudgetFeaturedNote;

  /// No description provided for @homeAiCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Pregúntale a Billetudo'**
  String get homeAiCardTitle;

  /// No description provided for @homeAiCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Entiende tu plata en segundos'**
  String get homeAiCardSubtitle;

  /// No description provided for @homeAiChipMonthProgress.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo voy este mes?'**
  String get homeAiChipMonthProgress;

  /// No description provided for @homeAiChipGoalsSaved.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto llevo ahorrado en mis metas?'**
  String get homeAiChipGoalsSaved;

  /// No description provided for @homeAiChipBiggestSpend.
  ///
  /// In es, this message translates to:
  /// **'¿En qué se me fue más la plata?'**
  String get homeAiChipBiggestSpend;

  /// Chip/CTA que navega directo a crear presupuesto (nunca abre el chat).
  ///
  /// In es, this message translates to:
  /// **'Ayúdame a presupuestar'**
  String get homeAiChipBudgetHelp;

  /// No description provided for @homeAiInsightCreateBudgetKicker.
  ///
  /// In es, this message translates to:
  /// **'Nuevo en Billetudo'**
  String get homeAiInsightCreateBudgetKicker;

  /// No description provided for @homeAiInsightCreateBudgetTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuesta y no gastes de más'**
  String get homeAiInsightCreateBudgetTitle;

  /// No description provided for @homeAiInsightCreateBudgetMeta.
  ///
  /// In es, this message translates to:
  /// **'Verás cuánto te queda del mes'**
  String get homeAiInsightCreateBudgetMeta;

  /// No description provided for @homeAiInsightProjectionKicker.
  ///
  /// In es, this message translates to:
  /// **'Proyección de presupuesto'**
  String get homeAiInsightProjectionKicker;

  /// No description provided for @homeAiInsightProjectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Podrías exceder tu presupuesto este mes'**
  String get homeAiInsightProjectionTitle;

  /// No description provided for @homeAiInsightProjectionMeta.
  ///
  /// In es, this message translates to:
  /// **'Con tus pagos programados podrías exceder por {amount}'**
  String homeAiInsightProjectionMeta(String amount);

  /// No description provided for @homeAiInsightAverageKicker.
  ///
  /// In es, this message translates to:
  /// **'Comparado con tu promedio'**
  String get homeAiInsightAverageKicker;

  /// No description provided for @homeAiInsightAverageTitleUp.
  ///
  /// In es, this message translates to:
  /// **'Vas {percent}% arriba de tu promedio este mes'**
  String homeAiInsightAverageTitleUp(int percent);

  /// No description provided for @homeAiInsightAverageTitleDown.
  ///
  /// In es, this message translates to:
  /// **'Vas {percent}% abajo de tu promedio este mes'**
  String homeAiInsightAverageTitleDown(int percent);

  /// No description provided for @homeAiInsightAverageMeta.
  ///
  /// In es, this message translates to:
  /// **'Comparado con los últimos 3 meses'**
  String get homeAiInsightAverageMeta;

  /// Contador de cola de la card de IA, visible solo con 2 o más insights.
  ///
  /// In es, this message translates to:
  /// **'{position} de {total}'**
  String homeAiInsightQueueCounter(int position, int total);

  /// No description provided for @homeAiInsightContinueChip.
  ///
  /// In es, this message translates to:
  /// **'Continuar la conversación'**
  String get homeAiInsightContinueChip;

  /// No description provided for @homeAiInsightProjectionChip.
  ///
  /// In es, this message translates to:
  /// **'Ajustar mi presupuesto'**
  String get homeAiInsightProjectionChip;

  /// No description provided for @homeAiInsightProjectionQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo evito pasarme del presupuesto que tengo proyectado este mes?'**
  String get homeAiInsightProjectionQuestion;

  /// No description provided for @homeAiInsightAverageUpChip.
  ///
  /// In es, this message translates to:
  /// **'Entender este aumento'**
  String get homeAiInsightAverageUpChip;

  /// No description provided for @homeAiInsightAverageUpQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué gasté más este mes que en mi promedio de los últimos meses?'**
  String get homeAiInsightAverageUpQuestion;

  /// No description provided for @homeAiInsightAverageDownChip.
  ///
  /// In es, this message translates to:
  /// **'Ver este ahorro'**
  String get homeAiInsightAverageDownChip;

  /// No description provided for @homeAiInsightAverageDownQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hice diferente este mes para gastar menos que mi promedio?'**
  String get homeAiInsightAverageDownQuestion;

  /// No description provided for @homeAiInsightDismiss.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get homeAiInsightDismiss;

  /// No description provided for @homeAiBetaSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Conversación en beta'**
  String get homeAiBetaSheetTitle;

  /// No description provided for @homeAiBetaSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes acceso a la conversación con Billetudo. Sigue explorando la app mientras se abre para más personas.'**
  String get homeAiBetaSheetMessage;

  /// No description provided for @homeBalancesSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu dinero'**
  String get homeBalancesSheetTitle;

  /// No description provided for @homeBalancesSheetTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'TU DINERO'**
  String get homeBalancesSheetTotalLabel;

  /// No description provided for @homeBalancesSheetExcludesNote.
  ///
  /// In es, this message translates to:
  /// **'No incluye tarjetas de crédito ni inversiones'**
  String get homeBalancesSheetExcludesNote;

  /// No description provided for @homeBalancesSheetCurrencyCount.
  ///
  /// In es, this message translates to:
  /// **'{currency} · {count, plural, =1{1 cuenta} other{{count} cuentas}}'**
  String homeBalancesSheetCurrencyCount(String currency, int count);

  /// No description provided for @homeAccountSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta'**
  String get homeAccountSheetTitle;

  /// No description provided for @homeAccountSheetSyncedTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo está sincronizado'**
  String get homeAccountSheetSyncedTitle;

  /// No description provided for @homeAccountSheetSyncedKicker.
  ///
  /// In es, this message translates to:
  /// **'Todo bien'**
  String get homeAccountSheetSyncedKicker;

  /// No description provided for @homeAccountSheetSyncedBody.
  ///
  /// In es, this message translates to:
  /// **'Tus datos están respaldados y al día en la nube.'**
  String get homeAccountSheetSyncedBody;

  /// No description provided for @homeAccountSheetOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get homeAccountSheetOfflineTitle;

  /// No description provided for @homeAccountSheetOfflineKicker.
  ///
  /// In es, this message translates to:
  /// **'Algo merece tu atención'**
  String get homeAccountSheetOfflineKicker;

  /// No description provided for @homeAccountSheetOfflineBody.
  ///
  /// In es, this message translates to:
  /// **'Sincronizaremos solos en cuanto haya conexión.'**
  String get homeAccountSheetOfflineBody;

  /// No description provided for @homeAccountSheetNoAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Respalda tu información'**
  String get homeAccountSheetNoAccountTitle;

  /// No description provided for @homeAccountSheetNoAccountBody.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para no perder tus datos si cambias de teléfono.'**
  String get homeAccountSheetNoAccountBody;

  /// No description provided for @homeAccountSheetActivateBackup.
  ///
  /// In es, this message translates to:
  /// **'Activar respaldo'**
  String get homeAccountSheetActivateBackup;

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

  /// No description provided for @debtsTitle.
  ///
  /// In es, this message translates to:
  /// **'Deudas'**
  String get debtsTitle;

  /// No description provided for @debtsAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar deuda'**
  String get debtsAdd;

  /// No description provided for @debtsLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando tus deudas'**
  String get debtsLoading;

  /// No description provided for @debtsSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get debtsSummaryTitle;

  /// No description provided for @debtsSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus deudas'**
  String get debtsSectionTitle;

  /// No description provided for @debtsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes deudas registradas'**
  String get debtsEmptyMessage;

  /// No description provided for @debtsEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Registra lo que debes o lo que te deben para seguir tu progreso de pago en un solo lugar.'**
  String get debtsEmptyDescription;

  /// No description provided for @debtsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus deudas'**
  String get debtsErrorTitle;

  /// No description provided for @debtDetailErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar esta deuda'**
  String get debtDetailErrorTitle;

  /// No description provided for @debtDirectionIOwe.
  ///
  /// In es, this message translates to:
  /// **'Yo debo'**
  String get debtDirectionIOwe;

  /// No description provided for @debtDirectionOwedToMe.
  ///
  /// In es, this message translates to:
  /// **'Me deben'**
  String get debtDirectionOwedToMe;

  /// No description provided for @debtProgressPaid.
  ///
  /// In es, this message translates to:
  /// **'{pct}% pagado'**
  String debtProgressPaid(int pct);

  /// No description provided for @debtProgressCollected.
  ///
  /// In es, this message translates to:
  /// **'{pct}% cobrado'**
  String debtProgressCollected(int pct);

  /// Monto original de la deuda bajo el saldo pendiente. El monto llega ya formateado.
  ///
  /// In es, this message translates to:
  /// **'de {amount}'**
  String debtAmountOf(String amount);

  /// No description provided for @debtDueOn.
  ///
  /// In es, this message translates to:
  /// **'Vence {date}'**
  String debtDueOn(String date);

  /// No description provided for @debtPercentValue.
  ///
  /// In es, this message translates to:
  /// **'{pct}%'**
  String debtPercentValue(int pct);

  /// No description provided for @debtDetailBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo pendiente'**
  String get debtDetailBalanceLabel;

  /// No description provided for @debtDetailPaidLabel.
  ///
  /// In es, this message translates to:
  /// **'pagado'**
  String get debtDetailPaidLabel;

  /// No description provided for @debtDetailCollectedLabel.
  ///
  /// In es, this message translates to:
  /// **'cobrado'**
  String get debtDetailCollectedLabel;

  /// Subtitulo del % cuando la deuda tiene interes acumulado: el avance mide solo el capital, no capital+interes.
  ///
  /// In es, this message translates to:
  /// **'pagado del capital'**
  String get debtDetailPaidOfCapitalLabel;

  /// Igual a debtDetailPaidOfCapitalLabel pero para deudas 'Me deben'.
  ///
  /// In es, this message translates to:
  /// **'cobrado del capital'**
  String get debtDetailCollectedOfCapitalLabel;

  /// Nota bajo la barra de avance del detalle de deuda: cuanto del saldo pendiente es interes, mostrada solo si hay interes acumulado. El monto llega ya formateado.
  ///
  /// In es, this message translates to:
  /// **'+{amount} de interés acumulado'**
  String debtInterestAccruedNote(String amount);

  /// Interés diario estimado de la deuda. El monto llega ya formateado.
  ///
  /// In es, this message translates to:
  /// **'Crece ~{amount}/día'**
  String debtDetailGrowth(String amount);

  /// No description provided for @debtDetailEstimated.
  ///
  /// In es, this message translates to:
  /// **'estimado'**
  String get debtDetailEstimated;

  /// No description provided for @debtDetailUpdateBalance.
  ///
  /// In es, this message translates to:
  /// **'Actualizar saldo'**
  String get debtDetailUpdateBalance;

  /// No description provided for @debtDetailMovementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get debtDetailMovementsTitle;

  /// No description provided for @debtDetailRegisterPayment.
  ///
  /// In es, this message translates to:
  /// **'Registrar abono'**
  String get debtDetailRegisterPayment;

  /// No description provided for @debtDetailCompleteDebt.
  ///
  /// In es, this message translates to:
  /// **'Completar deuda'**
  String get debtDetailCompleteDebt;

  /// No description provided for @debtInstallmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Próxima cuota'**
  String get debtInstallmentTitle;

  /// No description provided for @debtInstallmentBadge.
  ///
  /// In es, this message translates to:
  /// **'Cuota · {date}'**
  String debtInstallmentBadge(String date);

  /// No description provided for @debtInstallmentScheduledBadge.
  ///
  /// In es, this message translates to:
  /// **'Pago programado'**
  String get debtInstallmentScheduledBadge;

  /// No description provided for @debtConfigureInstallmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Configurar cuota'**
  String get debtConfigureInstallmentTitle;

  /// No description provided for @debtConfigureInstallmentSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Programa la cuota de esta deuda'**
  String get debtConfigureInstallmentSubtitle;

  /// No description provided for @debtLedgerOpening.
  ///
  /// In es, this message translates to:
  /// **'Saldo de apertura'**
  String get debtLedgerOpening;

  /// No description provided for @debtLedgerDisbursement.
  ///
  /// In es, this message translates to:
  /// **'Desembolso'**
  String get debtLedgerDisbursement;

  /// No description provided for @debtLedgerPaymentOwe.
  ///
  /// In es, this message translates to:
  /// **'Abono a la deuda'**
  String get debtLedgerPaymentOwe;

  /// No description provided for @debtLedgerPaymentOwed.
  ///
  /// In es, this message translates to:
  /// **'Pago recibido'**
  String get debtLedgerPaymentOwed;

  /// No description provided for @debtLedgerInterest.
  ///
  /// In es, this message translates to:
  /// **'Interés'**
  String get debtLedgerInterest;

  /// No description provided for @debtLedgerAdjustment.
  ///
  /// In es, this message translates to:
  /// **'Saldo actualizado'**
  String get debtLedgerAdjustment;

  /// Saldo corrido de la deuda tras un asiento. El monto llega ya formateado.
  ///
  /// In es, this message translates to:
  /// **'Saldo {amount}'**
  String debtLedgerRunning(String amount);

  /// No description provided for @debtLedgerTagEstimated.
  ///
  /// In es, this message translates to:
  /// **'Estimado'**
  String get debtLedgerTagEstimated;

  /// No description provided for @debtLedgerTagNoAccount.
  ///
  /// In es, this message translates to:
  /// **'No afecta cuentas'**
  String get debtLedgerTagNoAccount;

  /// No description provided for @debtEditTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar deuda'**
  String get debtEditTooltip;

  /// No description provided for @debtDetailTitleFallback.
  ///
  /// In es, this message translates to:
  /// **'Deuda'**
  String get debtDetailTitleFallback;

  /// No description provided for @debtFormNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva deuda'**
  String get debtFormNewTitle;

  /// No description provided for @debtFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar deuda'**
  String get debtFormEditTitle;

  /// No description provided for @debtFormDirectionLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Debes o te deben?'**
  String get debtFormDirectionLabel;

  /// No description provided for @debtFormOpeningBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo de apertura'**
  String get debtFormOpeningBalanceLabel;

  /// No description provided for @debtFormErrorAmountZero.
  ///
  /// In es, this message translates to:
  /// **'El saldo de apertura debe ser mayor a 0'**
  String get debtFormErrorAmountZero;

  /// No description provided for @debtFormNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la deuda'**
  String get debtFormNameLabel;

  /// No description provided for @debtFormNameHint.
  ///
  /// In es, this message translates to:
  /// **'Crédito vehicular, préstamo a Andrés…'**
  String get debtFormNameHint;

  /// No description provided for @debtFormNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ponle un nombre a la deuda'**
  String get debtFormNameRequired;

  /// No description provided for @debtFormCounterpartyLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraparte'**
  String get debtFormCounterpartyLabel;

  /// No description provided for @debtFormCounterpartyLabelIOwe.
  ///
  /// In es, this message translates to:
  /// **'Le debo a'**
  String get debtFormCounterpartyLabelIOwe;

  /// No description provided for @debtFormCounterpartyLabelOwedToMe.
  ///
  /// In es, this message translates to:
  /// **'Me debe'**
  String get debtFormCounterpartyLabelOwedToMe;

  /// No description provided for @debtFormCounterpartyHint.
  ///
  /// In es, this message translates to:
  /// **'Banco, persona…'**
  String get debtFormCounterpartyHint;

  /// No description provided for @debtFormStartDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get debtFormStartDateLabel;

  /// No description provided for @debtFormDueDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de vencimiento'**
  String get debtFormDueDateLabel;

  /// No description provided for @debtFormDueDateHint.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha'**
  String get debtFormDueDateHint;

  /// No description provided for @debtFormErrorDueBeforeStart.
  ///
  /// In es, this message translates to:
  /// **'La fecha de vencimiento debe ser posterior a la fecha de inicio'**
  String get debtFormErrorDueBeforeStart;

  /// No description provided for @debtFormInterestLabel.
  ///
  /// In es, this message translates to:
  /// **'Interés anual (opcional)'**
  String get debtFormInterestLabel;

  /// No description provided for @debtFormInterestHint.
  ///
  /// In es, this message translates to:
  /// **'0'**
  String get debtFormInterestHint;

  /// No description provided for @debtFormInterestError.
  ///
  /// In es, this message translates to:
  /// **'Revisa la tasa de interés'**
  String get debtFormInterestError;

  /// No description provided for @debtFormAccrualModeLabel.
  ///
  /// In es, this message translates to:
  /// **'Modo de interés'**
  String get debtFormAccrualModeLabel;

  /// No description provided for @debtFormAccrualManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get debtFormAccrualManual;

  /// No description provided for @debtFormAccrualAuto.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get debtFormAccrualAuto;

  /// No description provided for @debtFormAccrualHint.
  ///
  /// In es, this message translates to:
  /// **'Manual: tú pones la cifra del banco. Automático estima el crecimiento diario (estimado).'**
  String get debtFormAccrualHint;

  /// No description provided for @debtFormCreateCta.
  ///
  /// In es, this message translates to:
  /// **'Crear deuda'**
  String get debtFormCreateCta;

  /// No description provided for @debtFormSaveCta.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get debtFormSaveCta;

  /// No description provided for @debtFormDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar deuda'**
  String get debtFormDelete;

  /// No description provided for @debtCurrencySheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get debtCurrencySheetTitle;

  /// No description provided for @debtCurrencyPill.
  ///
  /// In es, this message translates to:
  /// **'{code} · {name}'**
  String debtCurrencyPill(String code, String name);

  /// No description provided for @debtDeleteSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta deuda?'**
  String get debtDeleteSheetTitle;

  /// No description provided for @debtDeleteSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Podrás recuperarla desde la papelera.'**
  String get debtDeleteSheetMessage;

  /// Subtítulo de contexto: nombre de la deuda y su dirección.
  ///
  /// In es, this message translates to:
  /// **'{name} · {direction}'**
  String debtContext(String name, String direction);

  /// No description provided for @debtDateToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy, {date}'**
  String debtDateToday(String date);

  /// No description provided for @debtPaymentTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar abono'**
  String get debtPaymentTitle;

  /// No description provided for @debtPaymentAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Abono'**
  String get debtPaymentAmountLabel;

  /// No description provided for @debtPaymentAddToAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Agregar a una cuenta?'**
  String get debtPaymentAddToAccountLabel;

  /// No description provided for @debtPaymentAddToAccountHintYes.
  ///
  /// In es, this message translates to:
  /// **'Moverá el saldo y contará en tus estadísticas'**
  String get debtPaymentAddToAccountHintYes;

  /// No description provided for @debtPaymentAddToAccountHintNo.
  ///
  /// In es, this message translates to:
  /// **'Este abono baja el saldo de la deuda pero no moverá ninguna cuenta.'**
  String get debtPaymentAddToAccountHintNo;

  /// No description provided for @debtPaymentLinkExisting.
  ///
  /// In es, this message translates to:
  /// **'¿Ya lo registraste? Enlaza un movimiento'**
  String get debtPaymentLinkExisting;

  /// No description provided for @debtPaymentDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get debtPaymentDateLabel;

  /// No description provided for @debtPaymentNoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get debtPaymentNoteLabel;

  /// No description provided for @debtPaymentNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Agregar una nota'**
  String get debtPaymentNoteHint;

  /// No description provided for @debtPaymentCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get debtPaymentCategoryLabel;

  /// No description provided for @debtPaymentCategoryNone.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría'**
  String get debtPaymentCategoryNone;

  /// No description provided for @debtPaymentSelectAccount.
  ///
  /// In es, this message translates to:
  /// **'Elige una cuenta'**
  String get debtPaymentSelectAccount;

  /// No description provided for @debtPaymentAccountPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige una cuenta'**
  String get debtPaymentAccountPickerTitle;

  /// Nota autogenerada del movimiento de apertura de una deuda, cuando el usuario elige registrarlo en una cuenta. No editable por widgets: se resuelve sin BuildContext (AppLocale.resolveLanguageCode) porque se escribe desde data/.
  ///
  /// In es, this message translates to:
  /// **'Deuda: {debtName}'**
  String debtOpeningMovementNote(String debtName);

  /// No description provided for @debtPaymentCta.
  ///
  /// In es, this message translates to:
  /// **'Registrar abono'**
  String get debtPaymentCta;

  /// No description provided for @debtPaymentError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos registrar el abono. Intenta de nuevo.'**
  String get debtPaymentError;

  /// No description provided for @debtUpdateBalanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualizar saldo'**
  String get debtUpdateBalanceTitle;

  /// No description provided for @debtUpdateBalanceNewLabel.
  ///
  /// In es, this message translates to:
  /// **'Nuevo saldo'**
  String get debtUpdateBalanceNewLabel;

  /// No description provided for @debtUpdateBalanceEstimatedLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo estimado hoy'**
  String get debtUpdateBalanceEstimatedLabel;

  /// No description provided for @debtUpdateBalanceAdjustLabel.
  ///
  /// In es, this message translates to:
  /// **'Ajuste que se registra'**
  String get debtUpdateBalanceAdjustLabel;

  /// No description provided for @debtUpdateBalanceHint.
  ///
  /// In es, this message translates to:
  /// **'Registra un ajuste en la deuda para igualar la cifra del banco. No mueve ninguna cuenta.'**
  String get debtUpdateBalanceHint;

  /// No description provided for @debtUpdateBalanceDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha del ajuste'**
  String get debtUpdateBalanceDateLabel;

  /// No description provided for @debtUpdateBalanceCta.
  ///
  /// In es, this message translates to:
  /// **'Guardar saldo'**
  String get debtUpdateBalanceCta;

  /// No description provided for @debtUpdateBalanceError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos actualizar el saldo. Intenta de nuevo.'**
  String get debtUpdateBalanceError;

  /// No description provided for @debtLinkBannerTitle.
  ///
  /// In es, this message translates to:
  /// **'Enlazar a {debt}'**
  String debtLinkBannerTitle(String debt);

  /// No description provided for @debtLinkBannerBody.
  ///
  /// In es, this message translates to:
  /// **'Elige un movimiento que ya registraste; lo atribuimos a esta deuda, no creamos uno nuevo.'**
  String get debtLinkBannerBody;

  /// No description provided for @debtLinkError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enlazar el movimiento. Intenta de nuevo.'**
  String get debtLinkError;

  /// No description provided for @debtInitialRegistroTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres crear un registro inicial para esta deuda?'**
  String get debtInitialRegistroTitle;

  /// No description provided for @debtInitialRegistroMessage.
  ///
  /// In es, this message translates to:
  /// **'Si lo creas, cambiará el saldo de la cuenta que elijas.'**
  String get debtInitialRegistroMessage;

  /// No description provided for @debtInitialRegistroSoloDeuda.
  ///
  /// In es, this message translates to:
  /// **'No, solo la deuda'**
  String get debtInitialRegistroSoloDeuda;

  /// No description provided for @debtInitialRegistroChooseAccount.
  ///
  /// In es, this message translates to:
  /// **'Sí, elegir cuenta'**
  String get debtInitialRegistroChooseAccount;

  /// No description provided for @debtUpdateRegistroTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Actualizar también el registro?'**
  String get debtUpdateRegistroTitle;

  /// No description provided for @debtUpdateRegistroMessage.
  ///
  /// In es, this message translates to:
  /// **'Cambiar el saldo de apertura actualizará el registro inicial de {from} a {to}.'**
  String debtUpdateRegistroMessage(String from, String to);

  /// No description provided for @debtUpdateRegistroConfirm.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get debtUpdateRegistroConfirm;

  /// No description provided for @debtOpeningLinkSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Saldo inicial · sin cuenta enlazada'**
  String get debtOpeningLinkSnackbar;

  /// No description provided for @debtEntryDeleteSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este movimiento?'**
  String get debtEntryDeleteSheetTitle;

  /// No description provided for @debtEntryDeleteSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Podrás recuperarlo más adelante.'**
  String get debtEntryDeleteSheetMessage;

  /// No description provided for @debtEntryEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar movimiento'**
  String get debtEntryEditTitle;

  /// No description provided for @debtEntryEditDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get debtEntryEditDateLabel;

  /// No description provided for @debtEntryEditNoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get debtEntryEditNoteLabel;

  /// No description provided for @debtEntryEditNoteReadLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get debtEntryEditNoteReadLabel;

  /// No description provided for @debtEntryEditBalanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo después'**
  String get debtEntryEditBalanceLabel;

  /// No description provided for @debtEntryEditCta.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get debtEntryEditCta;

  /// No description provided for @debtEntryEditDeleteLink.
  ///
  /// In es, this message translates to:
  /// **'Eliminar movimiento'**
  String get debtEntryEditDeleteLink;

  /// No description provided for @debtEntryEditError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar los cambios. Intenta de nuevo.'**
  String get debtEntryEditError;

  /// No description provided for @debtMenuTooltip.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get debtMenuTooltip;

  /// No description provided for @debtActionClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar deuda'**
  String get debtActionClose;

  /// No description provided for @debtActionComplete.
  ///
  /// In es, this message translates to:
  /// **'Completar deuda'**
  String get debtActionComplete;

  /// No description provided for @debtFormErrorDirectionLocked.
  ///
  /// In es, this message translates to:
  /// **'No puedes cambiar la dirección de esta deuda porque ya tiene movimientos registrados además de la apertura.'**
  String get debtFormErrorDirectionLocked;

  /// No description provided for @debtActionError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la acción. Intenta de nuevo.'**
  String get debtActionError;

  /// No description provided for @debtActionCloseSuccess.
  ///
  /// In es, this message translates to:
  /// **'Deuda completada'**
  String get debtActionCloseSuccess;

  /// No description provided for @debtCloseSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar esta deuda?'**
  String get debtCloseSheetTitle;

  /// No description provided for @debtCloseSheetMessageIOwe.
  ///
  /// In es, this message translates to:
  /// **'Le debes {amount} a {counterparty}. Al cerrarla, dejará de aparecer en tus deudas activas y no te seguirá recordando pagarla.'**
  String debtCloseSheetMessageIOwe(String amount, String counterparty);

  /// No description provided for @debtCloseSheetMessageIOweNoCounterparty.
  ///
  /// In es, this message translates to:
  /// **'Debes {amount}. Al cerrarla, dejará de aparecer en tus deudas activas y no te seguirá recordando pagarla.'**
  String debtCloseSheetMessageIOweNoCounterparty(String amount);

  /// No description provided for @debtCloseSheetMessageOwedToMe.
  ///
  /// In es, this message translates to:
  /// **'{counterparty} te debe {amount}. Al cerrarla, dejará de aparecer en tus deudas activas y no te seguirá recordando cobrarla.'**
  String debtCloseSheetMessageOwedToMe(String counterparty, String amount);

  /// No description provided for @debtCloseSheetMessageOwedToMeNoCounterparty.
  ///
  /// In es, this message translates to:
  /// **'Te deben {amount}. Al cerrarla, dejará de aparecer en tus deudas activas y no te seguirá recordando cobrarla.'**
  String debtCloseSheetMessageOwedToMeNoCounterparty(String amount);

  /// No description provided for @debtCloseInfoLabel.
  ///
  /// In es, this message translates to:
  /// **'Saldo pendiente al cerrar'**
  String get debtCloseInfoLabel;

  /// No description provided for @debtCloseCta.
  ///
  /// In es, this message translates to:
  /// **'Cerrar deuda'**
  String get debtCloseCta;

  /// No description provided for @debtCelebrationTitleIOwe.
  ///
  /// In es, this message translates to:
  /// **'¡Felicidades! Ya no debes nada'**
  String get debtCelebrationTitleIOwe;

  /// No description provided for @debtCelebrationTitleOwedToMe.
  ///
  /// In es, this message translates to:
  /// **'¡Felicidades! Ya no te deben nada'**
  String get debtCelebrationTitleOwedToMe;

  /// No description provided for @debtCelebrationMessageIOwe.
  ///
  /// In es, this message translates to:
  /// **'Terminaste de pagar {name}. En total pagaste {amount} en {duration}.'**
  String debtCelebrationMessageIOwe(
      String name, String amount, String duration);

  /// No description provided for @debtCelebrationMessageOwedToMe.
  ///
  /// In es, this message translates to:
  /// **'Terminaste de cobrar {name}. En total cobraste {amount} en {duration}.'**
  String debtCelebrationMessageOwedToMe(
      String name, String amount, String duration);

  /// No description provided for @debtCelebrationStatTotalPaidIOwe.
  ///
  /// In es, this message translates to:
  /// **'Total pagado'**
  String get debtCelebrationStatTotalPaidIOwe;

  /// No description provided for @debtCelebrationStatTotalPaidOwedToMe.
  ///
  /// In es, this message translates to:
  /// **'Total cobrado'**
  String get debtCelebrationStatTotalPaidOwedToMe;

  /// No description provided for @debtCelebrationStatDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get debtCelebrationStatDuration;

  /// No description provided for @debtCelebrationDismiss.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get debtCelebrationDismiss;

  /// No description provided for @debtCelebrationComplete.
  ///
  /// In es, this message translates to:
  /// **'Completar'**
  String get debtCelebrationComplete;

  /// No description provided for @debtDurationMonths.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 mes} other{{count} meses}}'**
  String debtDurationMonths(int count);

  /// No description provided for @debtDurationDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String debtDurationDays(int count);

  /// No description provided for @debtDirectionIOwePast.
  ///
  /// In es, this message translates to:
  /// **'Debía'**
  String get debtDirectionIOwePast;

  /// No description provided for @debtDirectionOwedToMePast.
  ///
  /// In es, this message translates to:
  /// **'Me debían'**
  String get debtDirectionOwedToMePast;

  /// No description provided for @debtCardStatusPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagada · {date}'**
  String debtCardStatusPaid(String date);

  /// No description provided for @debtCardStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada · {date}'**
  String debtCardStatusClosed(String date);

  /// No description provided for @debtsTabActive.
  ///
  /// In es, this message translates to:
  /// **'Activas'**
  String get debtsTabActive;

  /// No description provided for @debtsTabClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerradas'**
  String get debtsTabClosed;

  /// No description provided for @debtsClosedPaidLabel.
  ///
  /// In es, this message translates to:
  /// **'Pagué'**
  String get debtsClosedPaidLabel;

  /// No description provided for @debtsClosedCollectedLabel.
  ///
  /// In es, this message translates to:
  /// **'Me pagaron'**
  String get debtsClosedCollectedLabel;

  /// No description provided for @debtsClosedEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Aún no has cerrado ninguna deuda'**
  String get debtsClosedEmptyMessage;

  /// No description provided for @debtsActiveEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'No tienes deudas activas'**
  String get debtsActiveEmptyMessage;

  /// No description provided for @moreScheduledPayments.
  ///
  /// In es, this message translates to:
  /// **'Pagos programados'**
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

  /// No description provided for @moreGoalsDescription.
  ///
  /// In es, this message translates to:
  /// **'Ahorra para tus metas y objetivos'**
  String get moreGoalsDescription;

  /// No description provided for @moreImportExport.
  ///
  /// In es, this message translates to:
  /// **'Importar y exportar'**
  String get moreImportExport;

  /// No description provided for @moreImportExportDescription.
  ///
  /// In es, this message translates to:
  /// **'Guarda una copia o trae tus datos'**
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

  /// HU-02/03: título de la hoja bloqueante cuando el dispositivo ya tiene datos locales asociados a una cuenta distinta a la que acaba de iniciar sesión. Nunca nombra ni da pistas de cuál es esa cuenta.
  ///
  /// In es, this message translates to:
  /// **'Hay datos de otra cuenta en este dispositivo'**
  String get authAccountConflictTitle;

  /// HU-02/03: mensaje genérico, sin identificar la cuenta dueña de los datos en conflicto.
  ///
  /// In es, this message translates to:
  /// **'Para continuar con esta cuenta, primero hay que borrar los datos de otra cuenta guardados en este dispositivo. Los cambios que no se hayan subido a la nube se perderán.'**
  String get authAccountConflictMessage;

  /// HU-02/03: confirma la hoja — borra los datos locales existentes y completa el inicio de sesión.
  ///
  /// In es, this message translates to:
  /// **'Borrar y continuar'**
  String get authAccountConflictConfirmCta;

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

  /// HU-07 paso 1: aviso cuando el dispositivo cerró sesión pero antes tuvo una cuenta en la nube (everSignedIn=true). Se muestra antes de continuar para que la elección de borrar solo lo local sea informada.
  ///
  /// In es, this message translates to:
  /// **'No hay una sesión iniciada'**
  String get authDeleteStep1SignedOutWarningTitle;

  /// HU-07 paso 1: cuerpo del aviso de sesión cerrada con cuenta previa en la nube.
  ///
  /// In es, this message translates to:
  /// **'Si también quieres eliminar tu cuenta en la nube, inicia sesión primero. Si continúas sin iniciar sesión, solo eliminaremos la información guardada en este dispositivo.'**
  String get authDeleteStep1SignedOutWarningBody;

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

  /// HU-07 paso 2: variante del subtítulo cuando el dispositivo cerró sesión con una cuenta previa en la nube (no se llamó al servidor).
  ///
  /// In es, this message translates to:
  /// **'No iniciaste sesión, así que solo vamos a borrar lo guardado en este dispositivo — tu cuenta en la nube no se vio afectada. Elige qué pasa con la información local.'**
  String get authDeleteStep2LocalOnlySubtitle;

  /// HU-07 paso 2: variante del subtítulo cuando el dispositivo nunca inició sesión, así que no existe (ni existió) una cuenta en la nube.
  ///
  /// In es, this message translates to:
  /// **'Nunca iniciaste sesión en este dispositivo, así que no hay una cuenta en la nube. Elige qué pasa con la información guardada aquí.'**
  String get authDeleteStep2NeverSignedInSubtitle;

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

  /// HU-07 paso 3: título cuando solo se borró lo local (dispositivo sin sesión, con una cuenta previa en la nube que no se tocó).
  ///
  /// In es, this message translates to:
  /// **'Listo, borramos tus datos de este dispositivo'**
  String get authDeleteStep3LocalOnlyTitle;

  /// HU-07 paso 3: subtítulo cuando solo se borró lo local; deja claro que la cuenta en la nube no fue tocada.
  ///
  /// In es, this message translates to:
  /// **'Como no iniciaste sesión, tu cuenta en la nube sigue existiendo. Si también quieres eliminarla, inicia sesión y repite este proceso.'**
  String get authDeleteStep3LocalOnlySubtitle;

  /// HU-07 paso 3: título cuando el dispositivo nunca inició sesión, así que no existe (ni existió) una cuenta en la nube que mencionar.
  ///
  /// In es, this message translates to:
  /// **'Listo, borramos tus datos de este dispositivo'**
  String get authDeleteStep3NeverSignedInTitle;

  /// HU-07 paso 3: subtítulo cuando el dispositivo nunca inició sesión; no menciona la nube porque nunca existió una cuenta ahí.
  ///
  /// In es, this message translates to:
  /// **'Borramos la información guardada en este dispositivo. Puedes seguir usando billetudo cuando quieras, con o sin cuenta.'**
  String get authDeleteStep3NeverSignedInSubtitle;

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

  /// No description provided for @settingsAppearanceSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsAppearanceSystem;

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

  /// No description provided for @settingsQuickAccessOrder.
  ///
  /// In es, this message translates to:
  /// **'Orden del acceso rápido'**
  String get settingsQuickAccessOrder;

  /// No description provided for @settingsQuickAccessOrderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige el orden de los accesos rápidos en Inicio'**
  String get settingsQuickAccessOrderSubtitle;

  /// No description provided for @settingsQuickAccessOrderTitle.
  ///
  /// In es, this message translates to:
  /// **'Acceso rápido'**
  String get settingsQuickAccessOrderTitle;

  /// No description provided for @settingsQuickAccessOrderHint.
  ///
  /// In es, this message translates to:
  /// **'Mantén presionado y arrastra para reordenar'**
  String get settingsQuickAccessOrderHint;

  /// No description provided for @settingsWidgetTitle.
  ///
  /// In es, this message translates to:
  /// **'Widget de captura rápida'**
  String get settingsWidgetTitle;

  /// No description provided for @settingsWidgetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Añádelo a tu pantalla de inicio para registrar un gasto o ingreso en un toque, sin abrir la app. Mantén presionada la pantalla de inicio, toca Widgets y busca Billetudo.'**
  String get settingsWidgetSubtitle;

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

  /// No description provided for @budgetActivityNettedTransferTitle.
  ///
  /// In es, this message translates to:
  /// **'Transferencia interna'**
  String get budgetActivityNettedTransferTitle;

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

  /// Sublínea del hero del detalle de presupuesto: cuánto quedaría libre tras aprobar los pagos programados del período. Solo cuando el margen es no negativo.
  ///
  /// In es, this message translates to:
  /// **'{amount} quedarían libres si apruebas los programados'**
  String budgetScheduledFreeCaption(String amount);

  /// No description provided for @budgetScheduledSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Pagos programados del período'**
  String get budgetScheduledSheetTitle;

  /// Enlace al pie del sheet de pagos programados del presupuesto que abre la lista global de Pagos programados.
  ///
  /// In es, this message translates to:
  /// **'Ver todos los pagos programados'**
  String get budgetScheduledSheetSeeAll;

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
  /// **'Ajustar monto — este período'**
  String get budgetActionAdjustAmount;

  /// No description provided for @budgetDetailActionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Acciones del presupuesto'**
  String get budgetDetailActionsSubtitle;

  /// No description provided for @budgetActionUseAsFeatured.
  ///
  /// In es, this message translates to:
  /// **'Usar como destacado en Inicio'**
  String get budgetActionUseAsFeatured;

  /// No description provided for @budgetActionUseAsFeaturedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reemplaza al presupuesto que tengas destacado, si hay uno.'**
  String get budgetActionUseAsFeaturedSubtitle;

  /// No description provided for @budgetActionRemoveFeatured.
  ///
  /// In es, this message translates to:
  /// **'Quitar de Inicio'**
  String get budgetActionRemoveFeatured;

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

  /// No description provided for @budgetErrorName.
  ///
  /// In es, this message translates to:
  /// **'Escribe un nombre para el presupuesto.'**
  String get budgetErrorName;

  /// No description provided for @budgetErrorAmount.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto mayor a cero.'**
  String get budgetErrorAmount;

  /// No description provided for @budgetErrorEndDate.
  ///
  /// In es, this message translates to:
  /// **'Elige una fecha de fin posterior al inicio.'**
  String get budgetErrorEndDate;

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

  /// Título de la pantalla de bloqueo por falta de red en el primerísimo arranque (decisión #12, docs/requirements/fase-1/05-auth-sync.md). Copy deliberadamente agnóstico: no menciona categorías ni sincronización.
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

  /// El wordmark de la marca (lib/core/widgets/brand_wordmark.dart), texto plano y con B mayúscula. Igual en todos los locales a propósito — es el nombre de marca, no una traducción real.
  ///
  /// In es, this message translates to:
  /// **'Billetudo'**
  String get brandWordmark;

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

  /// No description provided for @scheduledPaymentUntitled.
  ///
  /// In es, this message translates to:
  /// **'Pago programado'**
  String get scheduledPaymentUntitled;

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

  /// No description provided for @scheduledDeleteSheetTitleInstallment.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta cuota?'**
  String get scheduledDeleteSheetTitleInstallment;

  /// No description provided for @scheduledDeleteSheetMessageInstallment.
  ///
  /// In es, this message translates to:
  /// **'Se deja de agendar la cuota. La deuda y los abonos que ya registró se conservan en tu historial.'**
  String get scheduledDeleteSheetMessageInstallment;

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

  /// No description provided for @scheduledPaymentErrorAccount.
  ///
  /// In es, this message translates to:
  /// **'Elige una cuenta.'**
  String get scheduledPaymentErrorAccount;

  /// No description provided for @scheduledPaymentErrorAmount.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto mayor a cero.'**
  String get scheduledPaymentErrorAmount;

  /// No description provided for @scheduledPaymentErrorTransferAccount.
  ///
  /// In es, this message translates to:
  /// **'Elige la cuenta de destino.'**
  String get scheduledPaymentErrorTransferAccount;

  /// No description provided for @scheduledPaymentErrorCategory.
  ///
  /// In es, this message translates to:
  /// **'Elige una categoría.'**
  String get scheduledPaymentErrorCategory;

  /// No description provided for @scheduledPaymentInstallmentAmountExceedsError.
  ///
  /// In es, this message translates to:
  /// **'La cuota no puede superar el saldo de la deuda.'**
  String get scheduledPaymentInstallmentAmountExceedsError;

  /// No description provided for @scheduledPaymentFormNotFoundError.
  ///
  /// In es, this message translates to:
  /// **'Este pago programado ya no existe. Es posible que lo hayas eliminado.'**
  String get scheduledPaymentFormNotFoundError;

  /// No description provided for @scheduledPaymentFormSaveError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar los cambios. Intenta de nuevo.'**
  String get scheduledPaymentFormSaveError;

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

  /// TEMPORAL (2026-07-21): aún no existen notificaciones/recordatorios. Revertir a un texto que prometa un aviso automático (ej. 'Te avisamos para que confirmes antes de afectar tu saldo') cuando se implemente el sistema de notificaciones.
  ///
  /// In es, this message translates to:
  /// **'Por ahora deberás confirmarlo tú mismo'**
  String get scheduledPaymentFormModeManualSubtitle;

  /// No description provided for @scheduledPaymentFormDeleteAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar pago programado'**
  String get scheduledPaymentFormDeleteAction;

  /// No description provided for @scheduledPaymentInstallmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Configurar cuota'**
  String get scheduledPaymentInstallmentTitle;

  /// No description provided for @scheduledPaymentInstallmentEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar cuota'**
  String get scheduledPaymentInstallmentEditTitle;

  /// No description provided for @scheduledPaymentInstallmentDeleteAction.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuota'**
  String get scheduledPaymentInstallmentDeleteAction;

  /// No description provided for @scheduledPaymentInstallmentBanner.
  ///
  /// In es, this message translates to:
  /// **'Se crea un pago programado enlazado a esta deuda. Confírmalo o pospónlo en Pagos programados.'**
  String get scheduledPaymentInstallmentBanner;

  /// No description provided for @scheduledPaymentDetailLinkedDebtLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuota de'**
  String get scheduledPaymentDetailLinkedDebtLabel;

  /// No description provided for @scheduledPaymentDetailLinkedGoalEyebrow.
  ///
  /// In es, this message translates to:
  /// **'META ENLAZADA'**
  String get scheduledPaymentDetailLinkedGoalEyebrow;

  /// No description provided for @scheduledPaymentDetailLinkedGoalLabel.
  ///
  /// In es, this message translates to:
  /// **'Aporte a'**
  String get scheduledPaymentDetailLinkedGoalLabel;

  /// No description provided for @scheduledDebtChipLabel.
  ///
  /// In es, this message translates to:
  /// **'Deuda'**
  String get scheduledDebtChipLabel;

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
  /// **'Historial'**
  String get scheduledPaymentDetailHistoryTitle;

  /// No description provided for @scheduledPaymentDetailHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no se ha generado ningún movimiento de este pago programado.'**
  String get scheduledPaymentDetailHistoryEmpty;

  /// No description provided for @scheduledSkippedBadge.
  ///
  /// In es, this message translates to:
  /// **'Omitido'**
  String get scheduledSkippedBadge;

  /// No description provided for @scheduledRecoverAction.
  ///
  /// In es, this message translates to:
  /// **'Recuperar'**
  String get scheduledRecoverAction;

  /// No description provided for @scheduledRecoverMessage.
  ///
  /// In es, this message translates to:
  /// **'Pago recuperado'**
  String get scheduledRecoverMessage;

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

  /// No description provided for @scheduledPaymentDetailConfirmNowCta.
  ///
  /// In es, this message translates to:
  /// **'Confirmar ahora'**
  String get scheduledPaymentDetailConfirmNowCta;

  /// No description provided for @scheduledPaymentDetailConfirmNowError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar este pago ahora. Intenta de nuevo.'**
  String get scheduledPaymentDetailConfirmNowError;

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
  /// **'Elegiste una fecha futura. Un movimiento con fecha futura se registra como pago programado; así se aplica solo cuando llegue el día.'**
  String get scheduledPaymentBridgeMessage;

  /// No description provided for @scheduledPaymentBridgeAccept.
  ///
  /// In es, this message translates to:
  /// **'Sí, programarlo'**
  String get scheduledPaymentBridgeAccept;

  /// No description provided for @scheduledPaymentBridgeDecline.
  ///
  /// In es, this message translates to:
  /// **'Cambiar la fecha'**
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

  /// No description provided for @scheduledDetailActionsDeleteInstallment.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuota'**
  String get scheduledDetailActionsDeleteInstallment;

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
  /// **'Ajustar monto'**
  String get budgetAdjustSheetTitle;

  /// No description provided for @budgetAdjustCurrentAmountInline.
  ///
  /// In es, this message translates to:
  /// **'Actual {amount}'**
  String budgetAdjustCurrentAmountInline(String amount);

  /// No description provided for @budgetAdjustNewAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Nuevo monto · {range}'**
  String budgetAdjustNewAmountLabel(String range);

  /// No description provided for @budgetAdjustExplainer.
  ///
  /// In es, this message translates to:
  /// **'El {resumeDate} vuelve a {originalAmount} automáticamente.'**
  String budgetAdjustExplainer(String resumeDate, String originalAmount);

  /// No description provided for @budgetAdjustApplyCta.
  ///
  /// In es, this message translates to:
  /// **'Aplicar cambios'**
  String get budgetAdjustApplyCta;

  /// No description provided for @budgetAdjustRemoveCta.
  ///
  /// In es, this message translates to:
  /// **'Revertir ajuste'**
  String get budgetAdjustRemoveCta;

  /// No description provided for @budgetAdjustBannerLabel.
  ///
  /// In es, this message translates to:
  /// **'Ajuste de monto'**
  String get budgetAdjustBannerLabel;

  /// No description provided for @budgetAdjustBannerSub.
  ///
  /// In es, this message translates to:
  /// **'{amount} · {range}'**
  String budgetAdjustBannerSub(String amount, String range);

  /// No description provided for @budgetAdjustScheduledSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Ajuste programado para el período seleccionado.'**
  String get budgetAdjustScheduledSnackbar;

  /// No description provided for @budgetAdjustUpdatedSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Ajuste actualizado.'**
  String get budgetAdjustUpdatedSnackbar;

  /// No description provided for @budgetAdjustCancelledSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Ajuste revertido — el período vuelve al monto habitual.'**
  String get budgetAdjustCancelledSnackbar;

  /// No description provided for @goalsTitle.
  ///
  /// In es, this message translates to:
  /// **'Metas'**
  String get goalsTitle;

  /// No description provided for @goalsAdd.
  ///
  /// In es, this message translates to:
  /// **'Nueva meta'**
  String get goalsAdd;

  /// No description provided for @goalsErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus metas'**
  String get goalsErrorTitle;

  /// No description provided for @goalsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Elige algo por lo que ahorrar'**
  String get goalsEmptyMessage;

  /// No description provided for @goalsEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Dale un propósito a tu dinero. Empieza con una idea o crea la tuya.'**
  String get goalsEmptyDescription;

  /// No description provided for @goalsEmptyTemplatesTitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza con una plantilla'**
  String get goalsEmptyTemplatesTitle;

  /// No description provided for @goalsEmptyCustomCta.
  ///
  /// In es, this message translates to:
  /// **'Crear meta personalizada'**
  String get goalsEmptyCustomCta;

  /// No description provided for @goalsArchivedCta.
  ///
  /// In es, this message translates to:
  /// **'Metas archivadas'**
  String get goalsArchivedCta;

  /// No description provided for @goalsArchivedTitle.
  ///
  /// In es, this message translates to:
  /// **'Metas archivadas'**
  String get goalsArchivedTitle;

  /// No description provided for @goalsArchivedEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Aún no has archivado ninguna meta'**
  String get goalsArchivedEmptyMessage;

  /// No description provided for @goalsArchivedEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Cuando termines o pauses una meta, archívala: conserva su progreso y su historial, y sale de tu lista principal.'**
  String get goalsArchivedEmptyDescription;

  /// No description provided for @goalCoherenceMessage.
  ///
  /// In es, this message translates to:
  /// **'Tus metas superan el saldo real de la cuenta por {amount}'**
  String goalCoherenceMessage(String amount);

  /// No description provided for @goalMomentumStreak.
  ///
  /// In es, this message translates to:
  /// **'{weeks, plural, =1{1 semana seguida} other{{weeks} semanas seguidas}}'**
  String goalMomentumStreak(int weeks);

  /// No description provided for @goalMomentumStreakSub.
  ///
  /// In es, this message translates to:
  /// **'Tu mejor racha aportando. ¡Sigue así!'**
  String get goalMomentumStreakSub;

  /// No description provided for @goalMomentumBrokenTitle.
  ///
  /// In es, this message translates to:
  /// **'Retoma tu racha de ahorro'**
  String get goalMomentumBrokenTitle;

  /// No description provided for @goalMomentumBrokenSub.
  ///
  /// In es, this message translates to:
  /// **'{weeks, plural, =1{Hace 1 semana sin aportar · vuelve cuando quieras} other{Hace {weeks} semanas sin aportar · vuelve cuando quieras}}'**
  String goalMomentumBrokenSub(int weeks);

  /// No description provided for @goalMomentumMilestone.
  ///
  /// In es, this message translates to:
  /// **'Próximo hito: {pct}% en {goalName} · faltan {amount}'**
  String goalMomentumMilestone(int pct, String goalName, String amount);

  /// No description provided for @goalCardRemaining.
  ///
  /// In es, this message translates to:
  /// **'Te faltan {amount}'**
  String goalCardRemaining(String amount);

  /// No description provided for @goalCardCompleted.
  ///
  /// In es, this message translates to:
  /// **'Ahorraste {amount}'**
  String goalCardCompleted(String amount);

  /// No description provided for @goalCardMeta.
  ///
  /// In es, this message translates to:
  /// **'{pct}% completado'**
  String goalCardMeta(int pct);

  /// No description provided for @goalCardChapterClosed.
  ///
  /// In es, this message translates to:
  /// **'Cumplida · capítulo cerrado'**
  String get goalCardChapterClosed;

  /// No description provided for @goalDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Meta'**
  String get goalDetailTitle;

  /// No description provided for @goalDetailRemaining.
  ///
  /// In es, this message translates to:
  /// **'Te faltan {amount}'**
  String goalDetailRemaining(String amount);

  /// No description provided for @goalDetailAchieved.
  ///
  /// In es, this message translates to:
  /// **'Ahorraste {amount}'**
  String goalDetailAchieved(String amount);

  /// No description provided for @goalDetailSavedOfTarget.
  ///
  /// In es, this message translates to:
  /// **'{saved} ahorrado de {target}'**
  String goalDetailSavedOfTarget(String saved, String target);

  /// No description provided for @goalActionsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Más acciones'**
  String get goalActionsTooltip;

  /// No description provided for @goalEditTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar meta'**
  String get goalEditTooltip;

  /// No description provided for @goalActionEditSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Nombre, objetivo, fecha o cuenta'**
  String get goalActionEditSubtitle;

  /// No description provided for @goalActionArchive.
  ///
  /// In es, this message translates to:
  /// **'Archivar meta'**
  String get goalActionArchive;

  /// No description provided for @goalActionArchiveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sale de la lista y conserva su historial'**
  String get goalActionArchiveSubtitle;

  /// No description provided for @goalActionUnarchive.
  ///
  /// In es, this message translates to:
  /// **'Desarchivar meta'**
  String get goalActionUnarchive;

  /// No description provided for @goalActionUnarchiveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a tu lista principal'**
  String get goalActionUnarchiveSubtitle;

  /// No description provided for @goalActionDeleteLabel.
  ///
  /// In es, this message translates to:
  /// **'Eliminar meta'**
  String get goalActionDeleteLabel;

  /// No description provided for @goalActionDeleteSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Va a la papelera; puedes deshacerlo'**
  String get goalActionDeleteSubtitle;

  /// No description provided for @goalRowUnarchive.
  ///
  /// In es, this message translates to:
  /// **'Desarchivar'**
  String get goalRowUnarchive;

  /// No description provided for @goalRowCompletedBadge.
  ///
  /// In es, this message translates to:
  /// **'Cumplida'**
  String get goalRowCompletedBadge;

  /// No description provided for @goalRowArchivedOn.
  ///
  /// In es, this message translates to:
  /// **'{account} · archivada el {date}'**
  String goalRowArchivedOn(String account, String date);

  /// No description provided for @goalRowArchivedOnNoAccount.
  ///
  /// In es, this message translates to:
  /// **'Archivada el {date}'**
  String goalRowArchivedOnNoAccount(String date);

  /// No description provided for @goalRowTargetOf.
  ///
  /// In es, this message translates to:
  /// **'de {amount}'**
  String goalRowTargetOf(String amount);

  /// No description provided for @goalArchiveSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Archivar esta meta?'**
  String get goalArchiveSheetTitle;

  /// No description provided for @goalArchiveSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Se quita de tu lista principal y deja de aceptar nuevos movimientos. Puedes desarchivarla cuando quieras.'**
  String get goalArchiveSheetMessage;

  /// No description provided for @goalArchiveConfirm.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get goalArchiveConfirm;

  /// No description provided for @goalUnarchiveSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Desarchivar esta meta?'**
  String get goalUnarchiveSheetTitle;

  /// No description provided for @goalUnarchiveSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a tu lista principal y podrás aportar y retirar de nuevo.'**
  String get goalUnarchiveSheetMessage;

  /// No description provided for @goalUnarchiveConfirm.
  ///
  /// In es, this message translates to:
  /// **'Desarchivar'**
  String get goalUnarchiveConfirm;

  /// No description provided for @goalDeleteSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta meta?'**
  String get goalDeleteSheetTitle;

  /// No description provided for @goalDeleteSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Se mueve a la papelera. Puedes recuperarla mientras no la elimines definitivamente.'**
  String get goalDeleteSheetMessage;

  /// No description provided for @goalMovementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos ({count})'**
  String goalMovementsTitle(int count);

  /// No description provided for @goalMovementsSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Movimientos'**
  String get goalMovementsSectionTitle;

  /// No description provided for @goalMovementsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no registras movimientos en esta meta.'**
  String get goalMovementsEmpty;

  /// No description provided for @goalMovementContribution.
  ///
  /// In es, this message translates to:
  /// **'Aporte'**
  String get goalMovementContribution;

  /// No description provided for @goalMovementWithdrawal.
  ///
  /// In es, this message translates to:
  /// **'Retiro'**
  String get goalMovementWithdrawal;

  /// No description provided for @goalMovementDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get goalMovementDateLabel;

  /// No description provided for @goalMovementNoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota (opcional)'**
  String get goalMovementNoteLabel;

  /// No description provided for @goalMovementNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Agregar una nota'**
  String get goalMovementNoteHint;

  /// No description provided for @goalMovementError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el movimiento. Intenta de nuevo.'**
  String get goalMovementError;

  /// No description provided for @goalDateToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy, {date}'**
  String goalDateToday(String date);

  /// No description provided for @goalContributeTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar aporte'**
  String get goalContributeTitle;

  /// No description provided for @goalContributeTitleWithName.
  ///
  /// In es, this message translates to:
  /// **'Aportar a {name}'**
  String goalContributeTitleWithName(String name);

  /// No description provided for @goalContributeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Suma a tu progreso de la meta.'**
  String get goalContributeSubtitle;

  /// No description provided for @goalContributeAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Aporte'**
  String get goalContributeAmountLabel;

  /// No description provided for @goalContributeCta.
  ///
  /// In es, this message translates to:
  /// **'Aportar'**
  String get goalContributeCta;

  /// No description provided for @goalWithdrawTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar retiro'**
  String get goalWithdrawTitle;

  /// No description provided for @goalWithdrawTitleWithName.
  ///
  /// In es, this message translates to:
  /// **'Retirar de {name}'**
  String goalWithdrawTitleWithName(String name);

  /// No description provided for @goalWithdrawSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sacar dinero de una meta es normal.'**
  String get goalWithdrawSubtitle;

  /// No description provided for @goalWithdrawAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Retiro'**
  String get goalWithdrawAmountLabel;

  /// No description provided for @goalMoveFundsToggleLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Mover dinero de una cuenta?'**
  String get goalMoveFundsToggleLabel;

  /// No description provided for @goalMoveFundsToggleHintContribute.
  ///
  /// In es, this message translates to:
  /// **'Solo registra el avance de tu meta; no mueve ninguna cuenta.'**
  String get goalMoveFundsToggleHintContribute;

  /// No description provided for @goalMoveFundsToggleHintWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Solo registra el retiro; no toca ninguna cuenta.'**
  String get goalMoveFundsToggleHintWithdraw;

  /// No description provided for @goalMoveFundsToggleHintContributeOn.
  ///
  /// In es, this message translates to:
  /// **'Se crea una transferencia: el saldo de la cuenta de origen baja y el de la meta sube.'**
  String get goalMoveFundsToggleHintContributeOn;

  /// No description provided for @goalMoveFundsToggleHintContributeOnBudget.
  ///
  /// In es, this message translates to:
  /// **'Se crea una transferencia hacia la cuenta de tu meta.'**
  String get goalMoveFundsToggleHintContributeOnBudget;

  /// No description provided for @goalMoveFundsToggleHintWithdrawOn.
  ///
  /// In es, this message translates to:
  /// **'Se crea una transferencia: sale de tu meta y entra a la cuenta de destino.'**
  String get goalMoveFundsToggleHintWithdrawOn;

  /// No description provided for @goalContributeSourceAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de origen'**
  String get goalContributeSourceAccountLabel;

  /// No description provided for @goalWithdrawDestinationAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de destino'**
  String get goalWithdrawDestinationAccountLabel;

  /// No description provided for @goalAccountFieldPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Elige una cuenta'**
  String get goalAccountFieldPlaceholder;

  /// No description provided for @goalBudgetToggleLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Incluir en tu presupuesto?'**
  String get goalBudgetToggleLabel;

  /// No description provided for @goalBudgetToggleHintOff.
  ///
  /// In es, this message translates to:
  /// **'No entra en tus presupuestos ni reportes.'**
  String get goalBudgetToggleHintOff;

  /// No description provided for @goalBudgetToggleHintOnContribute.
  ///
  /// In es, this message translates to:
  /// **'Cuenta como egreso en la cuenta de origen y como ingreso en la de tu meta.'**
  String get goalBudgetToggleHintOnContribute;

  /// No description provided for @goalBudgetToggleHintOnWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Cuenta como ingreso en la cuenta de destino, según tus presupuestos.'**
  String get goalBudgetToggleHintOnWithdraw;

  /// No description provided for @goalLinkTransactionCta.
  ///
  /// In es, this message translates to:
  /// **'Enlazar un movimiento'**
  String get goalLinkTransactionCta;

  /// No description provided for @goalLinkBannerTitle.
  ///
  /// In es, this message translates to:
  /// **'Enlazar a {name}'**
  String goalLinkBannerTitle(String name);

  /// No description provided for @goalLinkBannerBody.
  ///
  /// In es, this message translates to:
  /// **'Elige un movimiento que ya registraste; lo atribuimos a esta meta, no creamos uno nuevo.'**
  String get goalLinkBannerBody;

  /// No description provided for @goalLinkError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enlazar el movimiento. Intenta de nuevo.'**
  String get goalLinkError;

  /// No description provided for @goalRecurringContributionEntryTitle.
  ///
  /// In es, this message translates to:
  /// **'Configura un aporte recurrente'**
  String get goalRecurringContributionEntryTitle;

  /// No description provided for @goalRecurringContributionEntrySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Automatiza tus aportes con un pago programado'**
  String get goalRecurringContributionEntrySubtitle;

  /// No description provided for @goalRecurringContributionDecisionTitle.
  ///
  /// In es, this message translates to:
  /// **'Aporte recurrente a {name}'**
  String goalRecurringContributionDecisionTitle(String name);

  /// No description provided for @goalRecurringContributionDecisionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Quedará enlazado a la meta: cada pago programado suma a tu progreso automáticamente.'**
  String get goalRecurringContributionDecisionSubtitle;

  /// No description provided for @goalRecurringContributionCreateNewCta.
  ///
  /// In es, this message translates to:
  /// **'Crear uno nuevo'**
  String get goalRecurringContributionCreateNewCta;

  /// No description provided for @goalRecurringContributionLinkExistingCta.
  ///
  /// In es, this message translates to:
  /// **'Enlazar un pago programado existente'**
  String get goalRecurringContributionLinkExistingCta;

  /// No description provided for @goalRecurringContributionFormTitle.
  ///
  /// In es, this message translates to:
  /// **'Aporte recurrente'**
  String get goalRecurringContributionFormTitle;

  /// No description provided for @goalRecurringContributionAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto del aporte'**
  String get goalRecurringContributionAmountLabel;

  /// No description provided for @goalRecurringContributionSourceAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de origen'**
  String get goalRecurringContributionSourceAccountLabel;

  /// No description provided for @goalRecurringContributionFrequencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get goalRecurringContributionFrequencyLabel;

  /// No description provided for @goalRecurringContributionSubmitCta.
  ///
  /// In es, this message translates to:
  /// **'Crear aporte recurrente'**
  String get goalRecurringContributionSubmitCta;

  /// No description provided for @goalRecurringContributionSaveError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos crear el aporte recurrente. Intenta de nuevo.'**
  String get goalRecurringContributionSaveError;

  /// No description provided for @goalRecurringContributionBanner.
  ///
  /// In es, this message translates to:
  /// **'Se crea un pago programado enlazado a esta meta. Confírmalo o pospónlo en Pagos programados.'**
  String get goalRecurringContributionBanner;

  /// No description provided for @goalRecurringContributionPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Enlazar un pago programado'**
  String get goalRecurringContributionPickerTitle;

  /// No description provided for @goalRecurringContributionPickerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige uno de tus pagos programados; lo atribuimos a esta meta, no creamos uno nuevo.'**
  String get goalRecurringContributionPickerSubtitle;

  /// No description provided for @goalRecurringContributionPickerEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes pagos programados disponibles para enlazar.'**
  String get goalRecurringContributionPickerEmpty;

  /// No description provided for @goalRecurringContributionLinkError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enlazar el pago programado. Intenta de nuevo.'**
  String get goalRecurringContributionLinkError;

  /// No description provided for @goalWithdrawCta.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get goalWithdrawCta;

  /// No description provided for @goalAdjustDateCta.
  ///
  /// In es, this message translates to:
  /// **'Ajustar la fecha'**
  String get goalAdjustDateCta;

  /// No description provided for @goalWithdrawAvailableLabel.
  ///
  /// In es, this message translates to:
  /// **'Disponible en la meta: {amount}'**
  String goalWithdrawAvailableLabel(String amount);

  /// No description provided for @goalWithdrawUseMaxCta.
  ///
  /// In es, this message translates to:
  /// **'Usar todo'**
  String get goalWithdrawUseMaxCta;

  /// No description provided for @goalWithdrawErrorExceedsSaved.
  ///
  /// In es, this message translates to:
  /// **'No puedes retirar más de lo que has ahorrado en esta meta.'**
  String get goalWithdrawErrorExceedsSaved;

  /// No description provided for @goalQuickAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'APORTE RÁPIDO'**
  String get goalQuickAmountLabel;

  /// No description provided for @goalQuickAmountAddCta.
  ///
  /// In es, this message translates to:
  /// **'Nueva'**
  String get goalQuickAmountAddCta;

  /// No description provided for @goalQuickAmountFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get goalQuickAmountFieldLabel;

  /// No description provided for @goalQuickAmountDeletedMessage.
  ///
  /// In es, this message translates to:
  /// **'Aporte rápido eliminado'**
  String get goalQuickAmountDeletedMessage;

  /// No description provided for @goalQuickAmountUndoAction.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get goalQuickAmountUndoAction;

  /// No description provided for @goalNewQuickAmountTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo aporte rápido'**
  String get goalNewQuickAmountTitle;

  /// No description provided for @goalNewQuickAmountSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda un monto para aportarlo con un toque la próxima vez.'**
  String get goalNewQuickAmountSubtitle;

  /// No description provided for @goalNewQuickAmountCta.
  ///
  /// In es, this message translates to:
  /// **'Crear chip'**
  String get goalNewQuickAmountCta;

  /// No description provided for @goalProjectionNoTargetDate.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha objetivo definida'**
  String get goalProjectionNoTargetDate;

  /// No description provided for @goalProjectionOverdue.
  ///
  /// In es, this message translates to:
  /// **'La fecha que elegiste ya pasó y tu meta sigue en pie. Ponle una fecha nueva y volvemos a proyectarte la llegada.'**
  String get goalProjectionOverdue;

  /// No description provided for @goalProjectionInsufficientHistory.
  ///
  /// In es, this message translates to:
  /// **'Aporta un poco más para ver tu ritmo de ahorro'**
  String get goalProjectionInsufficientHistory;

  /// No description provided for @goalProjectionMonthlyNeeded.
  ///
  /// In es, this message translates to:
  /// **'Necesitas aportar {amount} al mes para llegar a tu fecha'**
  String goalProjectionMonthlyNeeded(String amount);

  /// No description provided for @goalProjectionOnPace.
  ///
  /// In es, this message translates to:
  /// **'A tu ritmo, llegas en {month}'**
  String goalProjectionOnPace(String month);

  /// No description provided for @goalMilestoneTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Llegaste al {pct}%!'**
  String goalMilestoneTitle(int pct);

  /// No description provided for @goalMilestonePercent.
  ///
  /// In es, this message translates to:
  /// **'{pct}%'**
  String goalMilestonePercent(int pct);

  /// No description provided for @goalMilestoneMessage.
  ///
  /// In es, this message translates to:
  /// **'Sigue así con {name}. Cada aporte te acerca más.'**
  String goalMilestoneMessage(String name);

  /// No description provided for @goalMilestoneCta.
  ///
  /// In es, this message translates to:
  /// **'Seguir ahorrando'**
  String get goalMilestoneCta;

  /// No description provided for @goalCompletedBadge.
  ///
  /// In es, this message translates to:
  /// **'Meta cumplida'**
  String get goalCompletedBadge;

  /// No description provided for @goalCompletedTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Cumpliste {name}!'**
  String goalCompletedTitle(String name);

  /// No description provided for @goalCompletedMessage.
  ///
  /// In es, this message translates to:
  /// **'Ahorraste {amount} en total. Este logro queda contigo.'**
  String goalCompletedMessage(String amount);

  /// No description provided for @goalCompletedCreateNext.
  ///
  /// In es, this message translates to:
  /// **'Crear la próxima meta'**
  String get goalCompletedCreateNext;

  /// No description provided for @goalCompletedArchive.
  ///
  /// In es, this message translates to:
  /// **'Archivar meta'**
  String get goalCompletedArchive;

  /// No description provided for @goalFormNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva meta'**
  String get goalFormNewTitle;

  /// No description provided for @goalFormEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar meta'**
  String get goalFormEditTitle;

  /// No description provided for @goalFormTargetLabel.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get goalFormTargetLabel;

  /// No description provided for @goalFormErrorTargetZero.
  ///
  /// In es, this message translates to:
  /// **'El objetivo debe ser mayor a cero'**
  String get goalFormErrorTargetZero;

  /// No description provided for @goalFormNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get goalFormNameLabel;

  /// No description provided for @goalFormNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Viaje a Cartagena'**
  String get goalFormNameHint;

  /// No description provided for @goalFormNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es obligatorio'**
  String get goalFormNameRequired;

  /// No description provided for @goalFormAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta vinculada (recomendado)'**
  String get goalFormAccountLabel;

  /// No description provided for @goalFormAccountHint.
  ///
  /// In es, this message translates to:
  /// **'Elige una cuenta'**
  String get goalFormAccountHint;

  /// No description provided for @goalFormAccountPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige una cuenta'**
  String get goalFormAccountPickerTitle;

  /// No description provided for @goalFormTargetDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha objetivo (opcional)'**
  String get goalFormTargetDateLabel;

  /// No description provided for @goalFormTargetDateHint.
  ///
  /// In es, this message translates to:
  /// **'Elegir una fecha posterior a hoy'**
  String get goalFormTargetDateHint;

  /// No description provided for @goalFormErrorTargetDatePast.
  ///
  /// In es, this message translates to:
  /// **'La fecha debe ser posterior a hoy'**
  String get goalFormErrorTargetDatePast;

  /// No description provided for @goalFormInitialSavedLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes algo ahorrado? (opcional)'**
  String get goalFormInitialSavedLabel;

  /// No description provided for @goalFormCreateCta.
  ///
  /// In es, this message translates to:
  /// **'Crear meta'**
  String get goalFormCreateCta;

  /// No description provided for @goalFormSaveCta.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get goalFormSaveCta;

  /// No description provided for @goalCurrencySheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige la moneda'**
  String get goalCurrencySheetTitle;

  /// No description provided for @goalIconSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegir ícono'**
  String get goalIconSheetTitle;

  /// No description provided for @goalIconSheetHint.
  ///
  /// In es, this message translates to:
  /// **'El ícono se muestra en un fondo neutro — sin color por meta.'**
  String get goalIconSheetHint;

  /// No description provided for @goalFormIconAndNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Ícono y nombre'**
  String get goalFormIconAndNameLabel;

  /// No description provided for @goalFormCurrencyHintLocked.
  ///
  /// In es, this message translates to:
  /// **'La moneda la define la cuenta vinculada ({account}, {currency}). Cambia la cuenta si necesitas otra moneda.'**
  String goalFormCurrencyHintLocked(String account, String currency);

  /// No description provided for @goalFormCurrencyHintUnlocked.
  ///
  /// In es, this message translates to:
  /// **'Elige la moneda de tu meta. Si vinculas una cuenta, la moneda se fija a la de esa cuenta.'**
  String get goalFormCurrencyHintUnlocked;

  /// No description provided for @goalFormInitialSavedHint.
  ///
  /// In es, this message translates to:
  /// **'Lo guardamos como el primer movimiento del historial, para que tu meta arranque completa.'**
  String get goalFormInitialSavedHint;

  /// No description provided for @goalAccountFilterLabel.
  ///
  /// In es, this message translates to:
  /// **'Metas en {accountName}'**
  String goalAccountFilterLabel(String accountName);

  /// No description provided for @goalAccountFilterClearTooltip.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtro'**
  String get goalAccountFilterClearTooltip;

  /// No description provided for @goalCoherenceLink.
  ///
  /// In es, this message translates to:
  /// **'Ver las metas de esta cuenta'**
  String get goalCoherenceLink;

  /// No description provided for @goalDetailSavedOfTargetNoAccount.
  ///
  /// In es, this message translates to:
  /// **'{saved} de {target} · sin cuenta vinculada'**
  String goalDetailSavedOfTargetNoAccount(String saved, String target);

  /// No description provided for @goalDetailAccountUnavailableMessage.
  ///
  /// In es, this message translates to:
  /// **'La cuenta que tenías vinculada ya no está disponible. Tu historial sigue completo y esta meta pasa a avance manual.'**
  String get goalDetailAccountUnavailableMessage;

  /// No description provided for @goalDetailAccountUnavailableLink.
  ///
  /// In es, this message translates to:
  /// **'Vincular otra cuenta'**
  String get goalDetailAccountUnavailableLink;

  /// No description provided for @goalMovementDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle del movimiento'**
  String get goalMovementDetailTitle;

  /// No description provided for @goalMovementDetailHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes corregirlo o eliminarlo. Si el movimiento tiene una transferencia detrás, se actualiza junto con él.'**
  String get goalMovementDetailHint;

  /// No description provided for @goalMovementDetailDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get goalMovementDetailDateLabel;

  /// No description provided for @goalMovementDetailOriginAccountLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de origen'**
  String get goalMovementDetailOriginAccountLabel;

  /// No description provided for @goalMovementDetailTransferLabel.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get goalMovementDetailTransferLabel;

  /// No description provided for @goalMovementDetailTransferValue.
  ///
  /// In es, this message translates to:
  /// **'{origin} → {destination}'**
  String goalMovementDetailTransferValue(String origin, String destination);

  /// No description provided for @goalMovementDetailNoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get goalMovementDetailNoteLabel;

  /// No description provided for @goalMovementEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar movimiento'**
  String get goalMovementEditTitle;

  /// No description provided for @goalMovementEditHint.
  ///
  /// In es, this message translates to:
  /// **'Corrige el monto, la fecha o la nota de este movimiento. No crea ni elimina movimientos.'**
  String get goalMovementEditHint;

  /// No description provided for @goalMovementAmountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get goalMovementAmountLabel;

  /// No description provided for @goalMovementKindContributionLower.
  ///
  /// In es, this message translates to:
  /// **'aporte'**
  String get goalMovementKindContributionLower;

  /// No description provided for @goalMovementKindWithdrawalLower.
  ///
  /// In es, this message translates to:
  /// **'retiro'**
  String get goalMovementKindWithdrawalLower;

  /// No description provided for @goalDeleteMovementTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este {kind} de {amount}?'**
  String goalDeleteMovementTitle(String kind, String amount);

  /// No description provided for @goalDeleteMovementMessageTransfer.
  ///
  /// In es, this message translates to:
  /// **'El avance de la meta se recalcula sin él. Como este movimiento tiene una transferencia detrás, esa transferencia también se elimina y los saldos de {origin} y {destination} vuelven a como estaban.'**
  String goalDeleteMovementMessageTransfer(String origin, String destination);

  /// No description provided for @goalDeleteMovementMessageManual.
  ///
  /// In es, this message translates to:
  /// **'El avance de la meta se recalcula sin él. Este {kind} fue un registro manual, así que ninguna de tus cuentas cambia de saldo.'**
  String goalDeleteMovementMessageManual(String kind);

  /// No description provided for @goalDeleteMovementMessageCompletedTransfer.
  ///
  /// In es, this message translates to:
  /// **'Este {kind} hace parte de lo que completó {goalName}: al eliminarlo, la meta vuelve a estar en curso hasta que la completes de nuevo. La transferencia detrás también se elimina y los saldos de {origin} y {destination} vuelven a como estaban.'**
  String goalDeleteMovementMessageCompletedTransfer(
      String kind, String goalName, String origin, String destination);

  /// No description provided for @goalDeleteMovementMessageCompletedManual.
  ///
  /// In es, this message translates to:
  /// **'Este {kind} hace parte de lo que completó {goalName}: al eliminarlo, la meta vuelve a estar en curso hasta que la completes de nuevo. Fue un registro manual, así que ninguna de tus cuentas cambia de saldo.'**
  String goalDeleteMovementMessageCompletedManual(String kind, String goalName);

  /// No description provided for @syncStatusTitle.
  ///
  /// In es, this message translates to:
  /// **'Estado de sincronización'**
  String get syncStatusTitle;

  /// No description provided for @syncHeroAttentionTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cambio está solo en este teléfono} other{{count} cambios están solo en este teléfono}}'**
  String syncHeroAttentionTitle(num count);

  /// No description provided for @syncHeroAttentionKicker.
  ///
  /// In es, this message translates to:
  /// **'Sin subir a la nube desde {since}'**
  String syncHeroAttentionKicker(String since);

  /// No description provided for @syncHeroAttentionKickerNever.
  ///
  /// In es, this message translates to:
  /// **'Todavía sin subir a la nube'**
  String get syncHeroAttentionKickerNever;

  /// No description provided for @syncHeroAttentionBody.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Lo tenemos completo aquí. Mientras no suba, la nube no tiene copia de él: si cambias de teléfono o reinstalas la app, ese cambio no volvería.} other{Los tenemos completos aquí. Mientras no suban, la nube no tiene copia de ellos: si cambias de teléfono o reinstalas la app, esos {count} cambios no volverían.}}'**
  String syncHeroAttentionBody(num count);

  /// No description provided for @syncHeroStaleTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin contacto con la nube'**
  String get syncHeroStaleTitle;

  /// No description provided for @syncHeroStaleBody.
  ///
  /// In es, this message translates to:
  /// **'No hay cambios esperando: lo que registraste ya está a salvo en la nube. Pero mientras no haya contacto, lo que registres de ahora en adelante se queda solo en este teléfono.'**
  String get syncHeroStaleBody;

  /// No description provided for @syncHeroSyncedTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo está sincronizado'**
  String get syncHeroSyncedTitle;

  /// No description provided for @syncHeroSyncedKicker.
  ///
  /// In es, this message translates to:
  /// **'Nada esperando para subir'**
  String get syncHeroSyncedKicker;

  /// No description provided for @syncHeroSyncedBody.
  ///
  /// In es, this message translates to:
  /// **'Tus datos están completos en este teléfono y también hay copia en la nube. Si cambias de teléfono, los recuperas al iniciar sesión.'**
  String get syncHeroSyncedBody;

  /// No description provided for @syncHeroNeverTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no se ha sincronizado'**
  String get syncHeroNeverTitle;

  /// No description provided for @syncHeroNeverKicker.
  ///
  /// In es, this message translates to:
  /// **'Acabas de iniciar sesión'**
  String get syncHeroNeverKicker;

  /// No description provided for @syncHeroNeverBody.
  ///
  /// In es, this message translates to:
  /// **'Tus datos están completos en este teléfono. En cuanto haya conexión suben solos a la nube; no tienes que hacer nada.'**
  String get syncHeroNeverBody;

  /// No description provided for @syncHeroOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get syncHeroOfflineTitle;

  /// No description provided for @syncHeroOfflineKicker.
  ///
  /// In es, this message translates to:
  /// **'Se reanuda sola al volver la señal'**
  String get syncHeroOfflineKicker;

  /// No description provided for @syncHeroOfflineBody.
  ///
  /// In es, this message translates to:
  /// **'Tus datos están guardados en este teléfono y no se pierde nada mientras tanto. Lo que falte por subir se sincroniza solo en cuanto vuelva la conexión.'**
  String get syncHeroOfflineBody;

  /// No description provided for @syncHeroOfflineCaption.
  ///
  /// In es, this message translates to:
  /// **'Se reintentará solo en cuanto haya conexión.'**
  String get syncHeroOfflineCaption;

  /// No description provided for @syncHeroSignedOutTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay sesión iniciada'**
  String get syncHeroSignedOutTitle;

  /// No description provided for @syncHeroSignedOutKicker.
  ///
  /// In es, this message translates to:
  /// **'Tus datos viven solo en este teléfono'**
  String get syncHeroSignedOutKicker;

  /// No description provided for @syncHeroSignedOutBody.
  ///
  /// In es, this message translates to:
  /// **'Todo está completo aquí y la app funciona igual sin cuenta. Lo único que falta es la copia en la nube: sin ella, un cambio de teléfono o una reinstalación no tendrían de dónde recuperar tus datos.'**
  String get syncHeroSignedOutBody;

  /// No description provided for @syncSignInCta.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get syncSignInCta;

  /// No description provided for @syncRetryNowCta.
  ///
  /// In es, this message translates to:
  /// **'Reintentar ahora'**
  String get syncRetryNowCta;

  /// No description provided for @syncSyncNowCta.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar ahora'**
  String get syncSyncNowCta;

  /// No description provided for @syncSyncingCta.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando…'**
  String get syncSyncingCta;

  /// No description provided for @syncLastSyncLabel.
  ///
  /// In es, this message translates to:
  /// **'Última sincronización: {relative}'**
  String syncLastSyncLabel(String relative);

  /// No description provided for @syncLastSuccessfulSyncLabel.
  ///
  /// In es, this message translates to:
  /// **'Última sincronización exitosa: {relative}'**
  String syncLastSuccessfulSyncLabel(String relative);

  /// No description provided for @syncNeverSyncedLabel.
  ///
  /// In es, this message translates to:
  /// **'Aún no se ha sincronizado'**
  String get syncNeverSyncedLabel;

  /// No description provided for @syncNoActiveSyncLabel.
  ///
  /// In es, this message translates to:
  /// **'Sin sincronización activa'**
  String get syncNoActiveSyncLabel;

  /// No description provided for @syncTimeAgo.
  ///
  /// In es, this message translates to:
  /// **'hace {duration}'**
  String syncTimeAgo(String duration);

  /// No description provided for @syncDurationMoment.
  ///
  /// In es, this message translates to:
  /// **'un momento'**
  String get syncDurationMoment;

  /// No description provided for @syncDurationMinutes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 minuto} other{{count} minutos}}'**
  String syncDurationMinutes(num count);

  /// No description provided for @syncDurationHours.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 hora} other{{count} horas}}'**
  String syncDurationHours(num count);

  /// No description provided for @syncDurationDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String syncDurationDays(num count);

  /// No description provided for @syncSectionPending.
  ///
  /// In es, this message translates to:
  /// **'Qué está esperando'**
  String get syncSectionPending;

  /// No description provided for @syncSectionPendingLink.
  ///
  /// In es, this message translates to:
  /// **'Ver los {count}'**
  String syncSectionPendingLink(num count);

  /// No description provided for @syncSectionDiagnostics.
  ///
  /// In es, this message translates to:
  /// **'Diagnóstico'**
  String get syncSectionDiagnostics;

  /// No description provided for @syncSectionBackupAndDiagnostics.
  ///
  /// In es, this message translates to:
  /// **'Copia y diagnóstico'**
  String get syncSectionBackupAndDiagnostics;

  /// No description provided for @syncSectionMeanwhile.
  ///
  /// In es, this message translates to:
  /// **'Mientras tanto'**
  String get syncSectionMeanwhile;

  /// No description provided for @syncSaveCopyTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardar una copia'**
  String get syncSaveCopyTitle;

  /// No description provided for @syncSaveCopyDescription.
  ///
  /// In es, this message translates to:
  /// **'Un archivo con todo lo tuyo, listo para volver a cargarlo.'**
  String get syncSaveCopyDescription;

  /// No description provided for @syncSaveCopyDescriptionAttention.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Ese cambio vive solo aquí. Una copia lo pone a salvo.} other{Esos {count} cambios viven solo aquí. Una copia los pone a salvo.}}'**
  String syncSaveCopyDescriptionAttention(num count);

  /// No description provided for @syncSaveCopyDescriptionStale.
  ///
  /// In es, this message translates to:
  /// **'Lo que registres desde ahora se queda aquí hasta que vuelva el contacto. Una copia lo pone a salvo.'**
  String get syncSaveCopyDescriptionStale;

  /// No description provided for @syncSaveCopyDescriptionSignedOut.
  ///
  /// In es, this message translates to:
  /// **'Sin cuenta, un archivo de copia es la única forma de no depender de este teléfono.'**
  String get syncSaveCopyDescriptionSignedOut;

  /// No description provided for @syncSaveCopyChip.
  ///
  /// In es, this message translates to:
  /// **'Restaurable en la app'**
  String get syncSaveCopyChip;

  /// No description provided for @syncTechnicalLogTitle.
  ///
  /// In es, this message translates to:
  /// **'Registro técnico'**
  String get syncTechnicalLogTitle;

  /// No description provided for @syncTechnicalLogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Para enviarlo a soporte si hace falta'**
  String get syncTechnicalLogSubtitle;

  /// No description provided for @syncExportExcelTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar a Excel'**
  String get syncExportExcelTitle;

  /// No description provided for @syncExportExcelSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Para verlos en una hoja de cálculo'**
  String get syncExportExcelSubtitle;

  /// No description provided for @syncPendingListTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambios sin subir'**
  String get syncPendingListTitle;

  /// No description provided for @syncPendingListSummary.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cambio esperando · desde {since}} other{{count} cambios esperando · el más antiguo, desde {since}}}'**
  String syncPendingListSummary(num count, String since);

  /// No description provided for @syncPendingRowTitle.
  ///
  /// In es, this message translates to:
  /// **'{kind} · {label}'**
  String syncPendingRowTitle(String kind, String label);

  /// No description provided for @syncPendingRowMeta.
  ///
  /// In es, this message translates to:
  /// **'{attempts, plural, =1{Pendiente desde el {date} · 1 intento} other{Pendiente desde el {date} · {attempts} intentos}}'**
  String syncPendingRowMeta(num attempts, String date);

  /// No description provided for @syncEntityTransaction.
  ///
  /// In es, this message translates to:
  /// **'Movimiento'**
  String get syncEntityTransaction;

  /// No description provided for @syncEntityAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get syncEntityAccount;

  /// No description provided for @syncEntityBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get syncEntityBudget;

  /// No description provided for @syncEntityGoal.
  ///
  /// In es, this message translates to:
  /// **'Meta'**
  String get syncEntityGoal;

  /// No description provided for @syncEntityGoalContribution.
  ///
  /// In es, this message translates to:
  /// **'Aporte a meta'**
  String get syncEntityGoalContribution;

  /// No description provided for @syncEntityDebt.
  ///
  /// In es, this message translates to:
  /// **'Deuda'**
  String get syncEntityDebt;

  /// No description provided for @syncEntityDebtEntry.
  ///
  /// In es, this message translates to:
  /// **'Pago de deuda'**
  String get syncEntityDebtEntry;

  /// No description provided for @syncEntityScheduledPayment.
  ///
  /// In es, this message translates to:
  /// **'Pago programado'**
  String get syncEntityScheduledPayment;

  /// No description provided for @syncEntityCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get syncEntityCategory;

  /// No description provided for @syncEntityTag.
  ///
  /// In es, this message translates to:
  /// **'Etiqueta'**
  String get syncEntityTag;

  /// No description provided for @syncEntitySettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get syncEntitySettings;

  /// No description provided for @syncEntityOther.
  ///
  /// In es, this message translates to:
  /// **'Cambio'**
  String get syncEntityOther;

  /// No description provided for @syncDetailWaiting.
  ///
  /// In es, this message translates to:
  /// **'Lleva {duration} esperando'**
  String syncDetailWaiting(String duration);

  /// No description provided for @syncDetailAttempts.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 intento de subida} other{{count} intentos de subida}}'**
  String syncDetailAttempts(num count);

  /// No description provided for @syncDetailRisk.
  ///
  /// In es, this message translates to:
  /// **'La nube todavía no tiene copia de este cambio: si reinstalas la app o cambias de teléfono, no volvería.'**
  String get syncDetailRisk;

  /// No description provided for @syncDetailRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get syncDetailRetry;

  /// No description provided for @syncDetailDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get syncDetailDiscard;

  /// No description provided for @syncDiscardConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar este cambio?'**
  String get syncDiscardConfirmTitle;

  /// No description provided for @syncDiscardConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer. Solo se borra el dato local de este cambio — el resto de tu información en este teléfono no se toca.'**
  String get syncDiscardConfirmMessage;

  /// No description provided for @syncPendingEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Nada esperando para subir'**
  String get syncPendingEmptyMessage;

  /// No description provided for @syncPendingEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'Todo lo que registraste ya llegó a la nube.'**
  String get syncPendingEmptyDescription;

  /// No description provided for @syncDiscardAllLinkLabel.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Descartar todo (1)} other{Descartar todo ({count})}}'**
  String syncDiscardAllLinkLabel(num count);

  /// No description provided for @syncDiscardAllConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{¿Descartar el cambio pendiente?} other{¿Descartar los {count} cambios pendientes?}}'**
  String syncDiscardAllConfirmTitle(num count);

  /// No description provided for @syncDiscardAllConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se va a descartar 1 cambio pendiente. Esta acción no se puede deshacer. Solo se borra el dato local de esa operación específica — el resto de tu información en este teléfono no se toca.} other{Se van a descartar {count} cambios pendientes. Esta acción no se puede deshacer. Solo se borra el dato local de esas operaciones específicas — el resto de tu información en este teléfono no se toca.}}'**
  String syncDiscardAllConfirmMessage(num count);

  /// No description provided for @syncDiscardAllConfirmButton.
  ///
  /// In es, this message translates to:
  /// **'Descartar todo'**
  String get syncDiscardAllConfirmButton;

  /// No description provided for @syncLogSheetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Aún no hay líneas · nada que reportar} =1{Última línea · útil para soporte} other{Últimas {count} líneas · útil para soporte}}'**
  String syncLogSheetSubtitle(num count);

  /// No description provided for @syncLogPrivacyNote.
  ///
  /// In es, this message translates to:
  /// **'El registro no incluye montos ni los nombres de tus movimientos: solo fechas, códigos y reintentos.'**
  String get syncLogPrivacyNote;

  /// No description provided for @syncLogEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay nada registrado.'**
  String get syncLogEmpty;

  /// No description provided for @syncLogCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get syncLogCopy;

  /// No description provided for @syncLogShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get syncLogShare;

  /// No description provided for @syncLogShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Registro de sincronización de Billetudo'**
  String get syncLogShareSubject;

  /// No description provided for @syncLogCopied.
  ///
  /// In es, this message translates to:
  /// **'Registro copiado'**
  String get syncLogCopied;

  /// No description provided for @syncRetrySuccess.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Todo al día · 1 cambio subido} other{Todo al día · {count} cambios subidos}}'**
  String syncRetrySuccess(num count);

  /// No description provided for @syncRetryPartial.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir todo. Sigue guardado en este teléfono.'**
  String get syncRetryPartial;

  /// No description provided for @syncRetryPartialAction.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle'**
  String get syncRetryPartialAction;

  /// No description provided for @homeSyncAttention.
  ///
  /// In es, this message translates to:
  /// **'Cambios sin subir'**
  String get homeSyncAttention;

  /// No description provided for @homeSyncSheetStalledTitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cambio está solo en este teléfono} other{{count} cambios están solo en este teléfono}}'**
  String homeSyncSheetStalledTitle(num count);

  /// No description provided for @homeSyncSheetStalledMessage.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardarlos en la nube. Aquí están completos, pero la nube todavía no tiene copia de ellos.'**
  String get homeSyncSheetStalledMessage;

  /// No description provided for @homeSyncSheetStaleTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin contacto con la nube'**
  String get homeSyncSheetStaleTitle;

  /// No description provided for @homeSyncSheetStaleMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay cambios pendientes: lo que registraste ya está a salvo en la nube. Pero llevamos {duration} sin conectar, así que lo que registres de ahora en adelante se queda solo en este teléfono.'**
  String homeSyncSheetStaleMessage(String duration);

  /// No description provided for @homeSyncSheetTooLongTitle.
  ///
  /// In es, this message translates to:
  /// **'La sincronización está tardando'**
  String get homeSyncSheetTooLongTitle;

  /// No description provided for @homeSyncSheetTooLongMessage.
  ///
  /// In es, this message translates to:
  /// **'Llevamos {duration} intentando subir tus cambios. En este teléfono no falta nada; lo que aún no ocurre es la copia en la nube.'**
  String homeSyncSheetTooLongMessage(String duration);

  /// No description provided for @homeSyncSheetDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver detalles'**
  String get homeSyncSheetDetails;

  /// No description provided for @settingsSyncStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado de sincronización'**
  String get settingsSyncStatus;

  /// No description provided for @importExportHubTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar y exportar'**
  String get importExportHubTitle;

  /// No description provided for @importExportHubErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar esta pantalla'**
  String get importExportHubErrorTitle;

  /// No description provided for @importExportHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardar una copia de tus datos'**
  String get importExportHeroTitle;

  /// No description provided for @importExportHeroKicker.
  ///
  /// In es, this message translates to:
  /// **'Un archivo .billetudo.json'**
  String get importExportHeroKicker;

  /// No description provided for @importExportCloudNote.
  ///
  /// In es, this message translates to:
  /// **'Es distinto al respaldo en la nube: esta copia queda en tu dispositivo y no necesita cuenta.'**
  String get importExportCloudNote;

  /// No description provided for @importExportHeroBody.
  ///
  /// In es, this message translates to:
  /// **'Movimientos, cuentas, presupuestos, metas, deudas y pagos programados en un solo archivo tuyo. Si cambias de teléfono, la app lo vuelve a cargar tal cual.'**
  String get importExportHeroBody;

  /// No description provided for @importExportCopyStatusLastSaved.
  ///
  /// In es, this message translates to:
  /// **'Última copia: {date}'**
  String importExportCopyStatusLastSaved(String date);

  /// No description provided for @importExportCopyStatusNeverSaved.
  ///
  /// In es, this message translates to:
  /// **'Aún no has guardado una copia'**
  String get importExportCopyStatusNeverSaved;

  /// No description provided for @importExportSaveCopyCta.
  ///
  /// In es, this message translates to:
  /// **'Guardar una copia'**
  String get importExportSaveCopyCta;

  /// No description provided for @importExportPrivacyNote.
  ///
  /// In es, this message translates to:
  /// **'La copia se guarda sin cifrar y sin el número de cuenta. Tú eliges dónde la guardas.'**
  String get importExportPrivacyNote;

  /// No description provided for @importExportSectionOtherActions.
  ///
  /// In es, this message translates to:
  /// **'Exportar e importar'**
  String get importExportSectionOtherActions;

  /// No description provided for @importExportExportCsvTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar a CSV'**
  String get importExportExportCsvTitle;

  /// No description provided for @importExportExportPageTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar tus datos'**
  String get importExportExportPageTitle;

  /// No description provided for @importExportExportCsvSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Para Excel o Sheets · no restaura la app'**
  String get importExportExportCsvSubtitle;

  /// No description provided for @importExportImportCsvTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar desde un CSV'**
  String get importExportImportCsvTitle;

  /// No description provided for @importExportImportCsvSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu banco, Wallet, Mint o cualquier archivo'**
  String get importExportImportCsvSubtitle;

  /// No description provided for @importExportRestoreTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar desde una copia'**
  String get importExportRestoreTitle;

  /// No description provided for @importExportRestoreSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a cargar un archivo .billetudo.json'**
  String get importExportRestoreSubtitle;

  /// No description provided for @importExportSectionRecentImports.
  ///
  /// In es, this message translates to:
  /// **'Importaciones recientes'**
  String get importExportSectionRecentImports;

  /// No description provided for @importExportSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get importExportSeeAll;

  /// No description provided for @importExportBatchMeta.
  ///
  /// In es, this message translates to:
  /// **'{count} movimientos · {relative}'**
  String importExportBatchMeta(int count, String relative);

  /// No description provided for @importExportBatchRevertedBadge.
  ///
  /// In es, this message translates to:
  /// **'Revertida'**
  String get importExportBatchRevertedBadge;

  /// No description provided for @importExportRelativeDays.
  ///
  /// In es, this message translates to:
  /// **'hace {n} días'**
  String importExportRelativeDays(int n);

  /// No description provided for @importExportRelativeHours.
  ///
  /// In es, this message translates to:
  /// **'hace {n} horas'**
  String importExportRelativeHours(int n);

  /// No description provided for @importExportRelativeJustNow.
  ///
  /// In es, this message translates to:
  /// **'hace un momento'**
  String get importExportRelativeJustNow;

  /// No description provided for @importExportEmptyHeroTitle.
  ///
  /// In es, this message translates to:
  /// **'Trae tu historial'**
  String get importExportEmptyHeroTitle;

  /// No description provided for @importExportEmptyHeroBody.
  ///
  /// In es, this message translates to:
  /// **'Importa un CSV de Wallet, Mint o tu banco y tú decides qué es cada columna. Si vienes de otro teléfono, restaura tu copia y vuelve todo tal cual.'**
  String get importExportEmptyHeroBody;

  /// No description provided for @importExportEmptyImportCta.
  ///
  /// In es, this message translates to:
  /// **'Importar un CSV'**
  String get importExportEmptyImportCta;

  /// No description provided for @importExportSectionOtherOptions.
  ///
  /// In es, this message translates to:
  /// **'Otras opciones'**
  String get importExportSectionOtherOptions;

  /// No description provided for @importExportEmptyExportRowTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar y guardar copias'**
  String get importExportEmptyExportRowTitle;

  /// No description provided for @importExportEmptyExportRowSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se activan con tu primer movimiento. Ahí podrás sacar un CSV o guardar una copia con todo. Es distinto al respaldo en la nube: la copia queda en tu dispositivo.'**
  String get importExportEmptyExportRowSubtitle;

  /// No description provided for @importExportExportEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes movimientos para exportar'**
  String get importExportExportEmptyTitle;

  /// No description provided for @importExportExportEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'En cuanto registres tu primer movimiento, podrás exportarlo.'**
  String get importExportExportEmptyBody;

  /// No description provided for @importExportScopeTransactions.
  ///
  /// In es, this message translates to:
  /// **'Transacciones'**
  String get importExportScopeTransactions;

  /// No description provided for @importExportScopeTransactionsHint.
  ///
  /// In es, this message translates to:
  /// **'Incluye tus movimientos en el archivo'**
  String get importExportScopeTransactionsHint;

  /// No description provided for @importExportScopeAccounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get importExportScopeAccounts;

  /// No description provided for @importExportScopeAccountsHint.
  ///
  /// In es, this message translates to:
  /// **'Incluye tu estructura de cuentas'**
  String get importExportScopeAccountsHint;

  /// No description provided for @importExportScopeCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get importExportScopeCategories;

  /// No description provided for @importExportScopeCategoriesHint.
  ///
  /// In es, this message translates to:
  /// **'Incluye tu estructura de categorías'**
  String get importExportScopeCategoriesHint;

  /// No description provided for @importExportAllHistory.
  ///
  /// In es, this message translates to:
  /// **'Todo el histórico'**
  String get importExportAllHistory;

  /// No description provided for @importExportAllHistoryHint.
  ///
  /// In es, this message translates to:
  /// **'Ignora el filtro de fechas y exporta todo'**
  String get importExportAllHistoryHint;

  /// No description provided for @importExportPickDateRange.
  ///
  /// In es, this message translates to:
  /// **'Elegir rango de fechas'**
  String get importExportPickDateRange;

  /// No description provided for @importExportZipNotice.
  ///
  /// In es, this message translates to:
  /// **'Al elegir más de uno, se entrega un solo archivo .zip.'**
  String get importExportZipNotice;

  /// No description provided for @importExportExportCta.
  ///
  /// In es, this message translates to:
  /// **'Exportar'**
  String get importExportExportCta;

  /// No description provided for @importExportFiltersTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtros de transacciones'**
  String get importExportFiltersTitle;

  /// No description provided for @importExportFiltersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Solo aplican si exportas Transacciones.'**
  String get importExportFiltersSubtitle;

  /// No description provided for @importExportFilterSearchPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar por texto'**
  String get importExportFilterSearchPlaceholder;

  /// No description provided for @importExportFilterAllAccounts.
  ///
  /// In es, this message translates to:
  /// **'Todas las cuentas'**
  String get importExportFilterAllAccounts;

  /// No description provided for @importExportProgressExportingTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportando tus datos…'**
  String get importExportProgressExportingTitle;

  /// No description provided for @importExportProgressImportingTitle.
  ///
  /// In es, this message translates to:
  /// **'Importando tus movimientos…'**
  String get importExportProgressImportingTitle;

  /// No description provided for @importExportProgressRestoringTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurando tu copia…'**
  String get importExportProgressRestoringTitle;

  /// No description provided for @importExportProgressSavingCopyTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardando tu copia…'**
  String get importExportProgressSavingCopyTitle;

  /// No description provided for @importExportSaveCopyDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu copia está lista'**
  String get importExportSaveCopyDoneTitle;

  /// No description provided for @importExportSaveCopyDoneBody.
  ///
  /// In es, this message translates to:
  /// **'Guárdala en tu dispositivo o compártela por donde prefieras.'**
  String get importExportSaveCopyDoneBody;

  /// No description provided for @importExportSaveCopyActionSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get importExportSaveCopyActionSave;

  /// No description provided for @importExportSaveCopyActionShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get importExportSaveCopyActionShare;

  /// No description provided for @importExportProgressCaption.
  ///
  /// In es, this message translates to:
  /// **'{processed} de {total} filas'**
  String importExportProgressCaption(int processed, int total);

  /// No description provided for @importExportProgressHint.
  ///
  /// In es, this message translates to:
  /// **'No cierres la app mientras esto termina. Puedes cancelar sin perder lo que ya tenías.'**
  String get importExportProgressHint;

  /// No description provided for @importExportIoErrorWriteTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el archivo'**
  String get importExportIoErrorWriteTitle;

  /// No description provided for @importExportIoErrorWriteBody.
  ///
  /// In es, this message translates to:
  /// **'Puede ser falta de espacio o de permiso para escribir en tu dispositivo. Eliminamos el archivo parcial para no dejar nada a medias — tus datos en la app están a salvo.'**
  String get importExportIoErrorWriteBody;

  /// No description provided for @importExportIoErrorUnreadableTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer este archivo'**
  String get importExportIoErrorUnreadableTitle;

  /// No description provided for @importExportIoErrorUnreadableBody.
  ///
  /// In es, this message translates to:
  /// **'No parece un CSV válido, o está vacío. Prueba exportarlo otra vez desde tu banco o la otra app. Tus datos en Billetudo siguen intactos.'**
  String get importExportIoErrorUnreadableBody;

  /// No description provided for @importExportChooseAnotherFile.
  ///
  /// In es, this message translates to:
  /// **'Elegir otro archivo'**
  String get importExportChooseAnotherFile;

  /// No description provided for @importExportSelectFileTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu archivo CSV'**
  String get importExportSelectFileTitle;

  /// No description provided for @importExportSelectFileBody.
  ///
  /// In es, this message translates to:
  /// **'Acepta cualquier CSV: tú decides qué es cada columna en el siguiente paso.'**
  String get importExportSelectFileBody;

  /// No description provided for @importExportSelectFileCta.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo'**
  String get importExportSelectFileCta;

  /// No description provided for @importExportStepMapping.
  ///
  /// In es, this message translates to:
  /// **'Mapeo de columnas'**
  String get importExportStepMapping;

  /// No description provided for @importExportStepDestinations.
  ///
  /// In es, this message translates to:
  /// **'Resolver destinos'**
  String get importExportStepDestinations;

  /// No description provided for @importExportStepPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get importExportStepPreview;

  /// No description provided for @importExportStepSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get importExportStepSummary;

  /// No description provided for @importExportTemplateMatched.
  ///
  /// In es, this message translates to:
  /// **'Reconocimos el formato de \"{name}\" — confirma para continuar'**
  String importExportTemplateMatched(String name);

  /// No description provided for @importExportFieldNotUsed.
  ///
  /// In es, this message translates to:
  /// **'No usar'**
  String get importExportFieldNotUsed;

  /// No description provided for @importExportFieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio'**
  String get importExportFieldRequired;

  /// No description provided for @importExportFieldOptional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get importExportFieldOptional;

  /// No description provided for @importExportFieldPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa: {value}'**
  String importExportFieldPreview(String value);

  /// No description provided for @importExportFormatDetectedTitle.
  ///
  /// In es, this message translates to:
  /// **'Formato detectado'**
  String get importExportFormatDetectedTitle;

  /// No description provided for @importExportFormatDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Formato de fecha'**
  String get importExportFormatDateLabel;

  /// No description provided for @importExportFormatDecimalLabel.
  ///
  /// In es, this message translates to:
  /// **'Convención decimal'**
  String get importExportFormatDecimalLabel;

  /// No description provided for @importExportFormatSignLabel.
  ///
  /// In es, this message translates to:
  /// **'Gasto o ingreso se expresa con'**
  String get importExportFormatSignLabel;

  /// No description provided for @importExportDateOrderYmd.
  ///
  /// In es, this message translates to:
  /// **'AAAA/MM/DD'**
  String get importExportDateOrderYmd;

  /// No description provided for @importExportDateOrderDmy.
  ///
  /// In es, this message translates to:
  /// **'DD/MM/AAAA'**
  String get importExportDateOrderDmy;

  /// No description provided for @importExportDateOrderMdy.
  ///
  /// In es, this message translates to:
  /// **'MM/DD/AAAA'**
  String get importExportDateOrderMdy;

  /// No description provided for @importExportDecimalDot.
  ///
  /// In es, this message translates to:
  /// **'1.234,56 → 1234.56 (punto decimal)'**
  String get importExportDecimalDot;

  /// No description provided for @importExportDecimalComma.
  ///
  /// In es, this message translates to:
  /// **'1.234,56 (coma decimal)'**
  String get importExportDecimalComma;

  /// No description provided for @importExportSignByTypeColumn.
  ///
  /// In es, this message translates to:
  /// **'Columna tipo (ingreso o gasto)'**
  String get importExportSignByTypeColumn;

  /// No description provided for @importExportSignByAmountSign.
  ///
  /// In es, this message translates to:
  /// **'Signo del monto (negativo = gasto)'**
  String get importExportSignByAmountSign;

  /// No description provided for @importExportLivePreviewLabel.
  ///
  /// In es, this message translates to:
  /// **'Así queda tu primera fila real'**
  String get importExportLivePreviewLabel;

  /// No description provided for @importExportFieldsSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Campos'**
  String get importExportFieldsSectionTitle;

  /// No description provided for @importExportFieldPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué campo es esta columna?'**
  String get importExportFieldPickerTitle;

  /// No description provided for @importExportFieldId.
  ///
  /// In es, this message translates to:
  /// **'Id'**
  String get importExportFieldId;

  /// No description provided for @importExportFieldDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get importExportFieldDate;

  /// No description provided for @importExportFieldAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get importExportFieldAmount;

  /// No description provided for @importExportFieldType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get importExportFieldType;

  /// No description provided for @importExportFieldCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get importExportFieldCurrency;

  /// No description provided for @importExportFieldAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get importExportFieldAccount;

  /// No description provided for @importExportFieldTransferAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta destino'**
  String get importExportFieldTransferAccount;

  /// No description provided for @importExportFieldCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get importExportFieldCategory;

  /// No description provided for @importExportFieldSubcategory.
  ///
  /// In es, this message translates to:
  /// **'Subcategoría'**
  String get importExportFieldSubcategory;

  /// No description provided for @importExportFieldNote.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get importExportFieldNote;

  /// No description provided for @importExportFieldTags.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas'**
  String get importExportFieldTags;

  /// No description provided for @importExportDestinationsNoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo coincide con lo que ya tienes'**
  String get importExportDestinationsNoneTitle;

  /// No description provided for @importExportDestinationsAllInvalidTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada por resolver todavía'**
  String get importExportDestinationsAllInvalidTitle;

  /// No description provided for @importExportDestinationsAllInvalidBody.
  ///
  /// In es, this message translates to:
  /// **'Ninguna de las {count} filas se pudo leer con el mapeo actual — revisa el paso anterior antes de seguir.'**
  String importExportDestinationsAllInvalidBody(int count);

  /// No description provided for @importExportDestinationsReviewMappingCta.
  ///
  /// In es, this message translates to:
  /// **'Revisar mapeo'**
  String get importExportDestinationsReviewMappingCta;

  /// No description provided for @importExportMappingModeAutomatic.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get importExportMappingModeAutomatic;

  /// No description provided for @importExportMappingModeManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get importExportMappingModeManual;

  /// No description provided for @importExportMappingModeAutoSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Así vamos a leer tu archivo'**
  String get importExportMappingModeAutoSummaryTitle;

  /// No description provided for @importExportMappingModeAutoConfirmCta.
  ///
  /// In es, this message translates to:
  /// **'Confirmar mapeo'**
  String get importExportMappingModeAutoConfirmCta;

  /// No description provided for @importExportMappingModeAutoIncompleteHint.
  ///
  /// In es, this message translates to:
  /// **'Nos falta identificar fecha, monto o cuenta — cambia a Manual para mapearlos.'**
  String get importExportMappingModeAutoIncompleteHint;

  /// No description provided for @importExportDateFormatOptionIso.
  ///
  /// In es, this message translates to:
  /// **'AAAA-MM-DD'**
  String get importExportDateFormatOptionIso;

  /// No description provided for @importExportDateFormatOptionDmySlash.
  ///
  /// In es, this message translates to:
  /// **'DD/MM/AAAA'**
  String get importExportDateFormatOptionDmySlash;

  /// No description provided for @importExportDateFormatOptionDmyDash.
  ///
  /// In es, this message translates to:
  /// **'DD-MM-AAAA'**
  String get importExportDateFormatOptionDmyDash;

  /// No description provided for @importExportDateFormatOptionDmyDot.
  ///
  /// In es, this message translates to:
  /// **'DD.MM.AAAA'**
  String get importExportDateFormatOptionDmyDot;

  /// No description provided for @importExportDateFormatOptionMdySlash.
  ///
  /// In es, this message translates to:
  /// **'MM/DD/AAAA'**
  String get importExportDateFormatOptionMdySlash;

  /// No description provided for @importExportDateFormatOptionMdyDash.
  ///
  /// In es, this message translates to:
  /// **'MM-DD-AAAA'**
  String get importExportDateFormatOptionMdyDash;

  /// No description provided for @importExportDateFormatOptionMdyDot.
  ///
  /// In es, this message translates to:
  /// **'MM.DD.AAAA'**
  String get importExportDateFormatOptionMdyDot;

  /// No description provided for @importExportDateFormatPreviewUnreadable.
  ///
  /// In es, this message translates to:
  /// **'\"{value}\" no se pudo leer con este formato'**
  String importExportDateFormatPreviewUnreadable(String value);

  /// No description provided for @importExportTypeValuesResultIncome.
  ///
  /// In es, this message translates to:
  /// **'Esta fila se leería como ingreso'**
  String get importExportTypeValuesResultIncome;

  /// No description provided for @importExportTypeValuesResultExpense.
  ///
  /// In es, this message translates to:
  /// **'Esta fila se leería como gasto'**
  String get importExportTypeValuesResultExpense;

  /// No description provided for @importExportTypeValuesResultTransfer.
  ///
  /// In es, this message translates to:
  /// **'Esta fila se leería como transferencia'**
  String get importExportTypeValuesResultTransfer;

  /// No description provided for @importExportTypeValuesResultNoMatch.
  ///
  /// In es, this message translates to:
  /// **'No pudimos clasificar tu primera fila con estos valores'**
  String get importExportTypeValuesResultNoMatch;

  /// No description provided for @importExportTypeValuesIncomeLabel.
  ///
  /// In es, this message translates to:
  /// **'Valor que significa \"ingreso\"'**
  String get importExportTypeValuesIncomeLabel;

  /// No description provided for @importExportTypeValuesExpenseLabel.
  ///
  /// In es, this message translates to:
  /// **'Valor que significa \"gasto\"'**
  String get importExportTypeValuesExpenseLabel;

  /// No description provided for @importExportTypeValuesTransferLabel.
  ///
  /// In es, this message translates to:
  /// **'Valor que significa \"transferencia\"'**
  String get importExportTypeValuesTransferLabel;

  /// No description provided for @importExportDestinationNotFound.
  ///
  /// In es, this message translates to:
  /// **'No existe todavía en tu app'**
  String get importExportDestinationNotFound;

  /// No description provided for @importExportDestinationCreateNew.
  ///
  /// In es, this message translates to:
  /// **'Crear nueva'**
  String get importExportDestinationCreateNew;

  /// No description provided for @importExportDestinationMapExisting.
  ///
  /// In es, this message translates to:
  /// **'Mapear a existente'**
  String get importExportDestinationMapExisting;

  /// No description provided for @importExportDestinationsPickerEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes ninguna'**
  String get importExportDestinationsPickerEmpty;

  /// No description provided for @importExportDestinationsSectionAccounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get importExportDestinationsSectionAccounts;

  /// No description provided for @importExportDestinationsSectionCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get importExportDestinationsSectionCategories;

  /// No description provided for @importExportDestinationsSectionTags.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas'**
  String get importExportDestinationsSectionTags;

  /// No description provided for @importExportDestinationsNewAccountsNote.
  ///
  /// In es, this message translates to:
  /// **'Las cuentas que crees aquí empiezan en \$0 y tipo Otra — su saldo real se reconstruye con las transacciones que importes.'**
  String get importExportDestinationsNewAccountsNote;

  /// No description provided for @importExportStatRead.
  ///
  /// In es, this message translates to:
  /// **'leídas'**
  String get importExportStatRead;

  /// No description provided for @importExportStatWillImport.
  ///
  /// In es, this message translates to:
  /// **'a importar'**
  String get importExportStatWillImport;

  /// No description provided for @importExportStatDuplicates.
  ///
  /// In es, this message translates to:
  /// **'repetidos'**
  String get importExportStatDuplicates;

  /// No description provided for @importExportStatErrors.
  ///
  /// In es, this message translates to:
  /// **'inválidas'**
  String get importExportStatErrors;

  /// No description provided for @importExportOmitAllDuplicates.
  ///
  /// In es, this message translates to:
  /// **'Omitir todos'**
  String get importExportOmitAllDuplicates;

  /// No description provided for @importExportIncludeAllDuplicates.
  ///
  /// In es, this message translates to:
  /// **'Importar todos'**
  String get importExportIncludeAllDuplicates;

  /// No description provided for @importExportDuplicateExact.
  ///
  /// In es, this message translates to:
  /// **'Ya está importada'**
  String get importExportDuplicateExact;

  /// No description provided for @importExportDuplicateProbable.
  ///
  /// In es, this message translates to:
  /// **'Posible duplicado: mismo monto y fecha'**
  String get importExportDuplicateProbable;

  /// No description provided for @importExportInvalidRowsCount.
  ///
  /// In es, this message translates to:
  /// **'Ver {n} filas con error'**
  String importExportInvalidRowsCount(int n);

  /// No description provided for @importExportRowNumber.
  ///
  /// In es, this message translates to:
  /// **'Fila {n}'**
  String importExportRowNumber(int n);

  /// No description provided for @importExportIssueMissingAccount.
  ///
  /// In es, this message translates to:
  /// **'Falta la cuenta'**
  String get importExportIssueMissingAccount;

  /// No description provided for @importExportIssueMissingDate.
  ///
  /// In es, this message translates to:
  /// **'Falta la fecha'**
  String get importExportIssueMissingDate;

  /// No description provided for @importExportIssueInvalidDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha no reconocida'**
  String get importExportIssueInvalidDate;

  /// No description provided for @importExportIssueMissingAmount.
  ///
  /// In es, this message translates to:
  /// **'Falta el monto'**
  String get importExportIssueMissingAmount;

  /// No description provided for @importExportIssueInvalidAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto no reconocido'**
  String get importExportIssueInvalidAmount;

  /// No description provided for @importExportIssueInvalidType.
  ///
  /// In es, this message translates to:
  /// **'Tipo no reconocido'**
  String get importExportIssueInvalidType;

  /// No description provided for @importExportConfirmImportCta.
  ///
  /// In es, this message translates to:
  /// **'Confirmar importación'**
  String get importExportConfirmImportCta;

  /// No description provided for @importExportImportRowsCta.
  ///
  /// In es, this message translates to:
  /// **'Importar {count} movimientos'**
  String importExportImportRowsCta(int count);

  /// No description provided for @importExportDuplicatesSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Posibles duplicados ({count})'**
  String importExportDuplicatesSectionTitle(int count);

  /// No description provided for @importExportSaveTemplateToggleLabel.
  ///
  /// In es, this message translates to:
  /// **'Guardar esta plantilla de mapeo'**
  String get importExportSaveTemplateToggleLabel;

  /// No description provided for @importExportSaveTemplateToggleHint.
  ///
  /// In es, this message translates to:
  /// **'La usarás con un toque la próxima vez que importes de este mismo origen.'**
  String get importExportSaveTemplateToggleHint;

  /// No description provided for @importExportSaveTemplateNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la plantilla'**
  String get importExportSaveTemplateNameLabel;

  /// No description provided for @importExportSaveTemplateNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Bancolombia CSV'**
  String get importExportSaveTemplateNameHint;

  /// No description provided for @importExportSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Importación completa'**
  String get importExportSummaryTitle;

  /// No description provided for @importExportSummarySubtitle.
  ///
  /// In es, this message translates to:
  /// **'{fileName} se procesó y ya está disponible en tus movimientos.'**
  String importExportSummarySubtitle(String fileName);

  /// No description provided for @importExportSummaryImported.
  ///
  /// In es, this message translates to:
  /// **'Importadas'**
  String get importExportSummaryImported;

  /// No description provided for @importExportSummarySkippedDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Omitidas por duplicado'**
  String get importExportSummarySkippedDuplicate;

  /// No description provided for @importExportSummarySkippedError.
  ///
  /// In es, this message translates to:
  /// **'Omitidas por error'**
  String get importExportSummarySkippedError;

  /// No description provided for @importExportSummaryAccountsCreated.
  ///
  /// In es, this message translates to:
  /// **'Cuentas creadas'**
  String get importExportSummaryAccountsCreated;

  /// No description provided for @importExportSummaryCategoriesCreated.
  ///
  /// In es, this message translates to:
  /// **'Categorías creadas'**
  String get importExportSummaryCategoriesCreated;

  /// No description provided for @importExportSummaryTagsCreated.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas creadas'**
  String get importExportSummaryTagsCreated;

  /// No description provided for @importExportSummarySeeSkipped.
  ///
  /// In es, this message translates to:
  /// **'Ver omitidas'**
  String get importExportSummarySeeSkipped;

  /// No description provided for @importExportSummarySeeSkippedWithCount.
  ///
  /// In es, this message translates to:
  /// **'Ver {count} omitidas y por qué'**
  String importExportSummarySeeSkippedWithCount(int count);

  /// No description provided for @importExportSkippedSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Lo que no se importó'**
  String get importExportSkippedSheetTitle;

  /// No description provided for @importExportSkippedDuplicateReason.
  ///
  /// In es, this message translates to:
  /// **'{count} por posible duplicado: mismo id, o mismo monto y fecha, que un movimiento que ya tenías.'**
  String importExportSkippedDuplicateReason(int count);

  /// No description provided for @importExportSkippedErrorReason.
  ///
  /// In es, this message translates to:
  /// **'{count} por un dato que no pudimos leer: fecha, monto o cuenta incompletos o inválidos en el archivo.'**
  String importExportSkippedErrorReason(int count);

  /// No description provided for @importExportBatchesTitle.
  ///
  /// In es, this message translates to:
  /// **'Importaciones'**
  String get importExportBatchesTitle;

  /// No description provided for @importExportBatchesErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus importaciones'**
  String get importExportBatchesErrorTitle;

  /// No description provided for @importExportBatchesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no has importado nada'**
  String get importExportBatchesEmptyTitle;

  /// No description provided for @importExportBatchesEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Cuando importes un archivo, aparecerá aquí.'**
  String get importExportBatchesEmptyBody;

  /// No description provided for @importExportUndoConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Deshacer esta importación?'**
  String get importExportUndoConfirmTitle;

  /// No description provided for @importExportUndoConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Se quitarán las {count} filas que trajo \"{file}\". Lo que sigas usando fuera de esta importación se conserva.'**
  String importExportUndoConfirmBody(String file, int count);

  /// No description provided for @importExportUndoConfirmCta.
  ///
  /// In es, this message translates to:
  /// **'Deshacer importación'**
  String get importExportUndoConfirmCta;

  /// No description provided for @importExportUndoConfirmKeepNote.
  ///
  /// In es, this message translates to:
  /// **'Las cuentas y categorías que creó esta importación se conservan al deshacerla — solo se eliminan las transacciones que trajo.'**
  String get importExportUndoConfirmKeepNote;

  /// No description provided for @importExportRestorePickFileBody.
  ///
  /// In es, this message translates to:
  /// **'Elige un archivo .billetudo.json para ver qué trae antes de restaurar nada.'**
  String get importExportRestorePickFileBody;

  /// No description provided for @importExportRestorePickFileCta.
  ///
  /// In es, this message translates to:
  /// **'Elegir archivo'**
  String get importExportRestorePickFileCta;

  /// No description provided for @importExportRestoreSummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Copia del {date}'**
  String importExportRestoreSummaryTitle(String date);

  /// No description provided for @importExportRestoreSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar copia'**
  String get importExportRestoreSheetTitle;

  /// No description provided for @importExportRestoreSheetSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Copia del {date} · versión {version} · creada con Billetudo {appVersion}'**
  String importExportRestoreSheetSubtitle(
      String date, int version, String appVersion);

  /// No description provided for @importExportRestoreRowCounts.
  ///
  /// In es, this message translates to:
  /// **'Trae {n} filas en total'**
  String importExportRestoreRowCounts(int n);

  /// No description provided for @importExportRestoreStatAccounts.
  ///
  /// In es, this message translates to:
  /// **'cuentas'**
  String get importExportRestoreStatAccounts;

  /// No description provided for @importExportRestoreStatCategories.
  ///
  /// In es, this message translates to:
  /// **'categorías'**
  String get importExportRestoreStatCategories;

  /// No description provided for @importExportRestoreStatTransactions.
  ///
  /// In es, this message translates to:
  /// **'movimientos'**
  String get importExportRestoreStatTransactions;

  /// No description provided for @importExportRestoreStatBudgets.
  ///
  /// In es, this message translates to:
  /// **'presupuestos'**
  String get importExportRestoreStatBudgets;

  /// No description provided for @importExportRestoreStatGoals.
  ///
  /// In es, this message translates to:
  /// **'metas'**
  String get importExportRestoreStatGoals;

  /// No description provided for @importExportRestoreStatDebts.
  ///
  /// In es, this message translates to:
  /// **'deudas'**
  String get importExportRestoreStatDebts;

  /// No description provided for @importExportRestoreChoiceLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hacemos con tus datos actuales?'**
  String get importExportRestoreChoiceLabel;

  /// No description provided for @importExportRestoreChoiceHint.
  ///
  /// In es, this message translates to:
  /// **'Fusionar combina por id: lo nuevo se crea, lo existente se actualiza. Reemplazar todo borra tus datos actuales (y los de la nube, si tienes sesión) y deja solo el contenido de la copia.'**
  String get importExportRestoreChoiceHint;

  /// No description provided for @importExportReplaceAllConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer'**
  String get importExportReplaceAllConfirmTitle;

  /// No description provided for @importExportReplaceAllConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Vas a reemplazar TODOS tus datos actuales por los de la copia del {date}. Si tienes sesión iniciada, esto también borra tus datos en la nube.'**
  String importExportReplaceAllConfirmBody(String date);

  /// No description provided for @importExportRestoreModeMerge.
  ///
  /// In es, this message translates to:
  /// **'Fusionar'**
  String get importExportRestoreModeMerge;

  /// No description provided for @importExportRestoreModeMergeHint.
  ///
  /// In es, this message translates to:
  /// **'Combina con lo que ya tienes. No duplica si repites la restauración.'**
  String get importExportRestoreModeMergeHint;

  /// No description provided for @importExportRestoreModeReplace.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar todo'**
  String get importExportRestoreModeReplace;

  /// No description provided for @importExportRestoreCta.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get importExportRestoreCta;

  /// No description provided for @importExportRestoreModeReplaceHint.
  ///
  /// In es, this message translates to:
  /// **'Borra tus datos locales y deja exactamente lo que trae la copia. Irreversible.'**
  String get importExportRestoreModeReplaceHint;

  /// No description provided for @importExportReplaceAllAck.
  ///
  /// In es, this message translates to:
  /// **'Entiendo que esto borra mis datos actuales, incluida la nube si tengo sesión iniciada, y no se puede deshacer.'**
  String get importExportReplaceAllAck;

  /// No description provided for @importExportRestoreConfirmMergeCta.
  ///
  /// In es, this message translates to:
  /// **'Restaurar y fusionar'**
  String get importExportRestoreConfirmMergeCta;

  /// No description provided for @importExportRestoreConfirmReplaceCta.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar todo'**
  String get importExportRestoreConfirmReplaceCta;

  /// No description provided for @importExportRestoreErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos validar este archivo'**
  String get importExportRestoreErrorTitle;

  /// No description provided for @importExportRestoreErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Puede que no sea una copia de Billetudo o que sea de una versión más nueva. Tus datos en la app siguen intactos.'**
  String get importExportRestoreErrorBody;

  /// No description provided for @importExportRestoreExecutionErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la restauración'**
  String get importExportRestoreExecutionErrorTitle;

  /// No description provided for @importExportRestoreExecutionErrorBody.
  ///
  /// In es, this message translates to:
  /// **'El archivo era válido, pero algo falló a mitad de camino. La restauración se cancela por completo cuando eso pasa — tus datos actuales no se modificaron. Intenta de nuevo.'**
  String get importExportRestoreExecutionErrorBody;

  /// No description provided for @importExportRestoreDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Restauración completa'**
  String get importExportRestoreDoneTitle;

  /// No description provided for @importExportRestoreCreated.
  ///
  /// In es, this message translates to:
  /// **'Creadas'**
  String get importExportRestoreCreated;

  /// No description provided for @importExportRestoreUpdated.
  ///
  /// In es, this message translates to:
  /// **'Actualizadas'**
  String get importExportRestoreUpdated;

  /// No description provided for @importExportRestoreSkipped.
  ///
  /// In es, this message translates to:
  /// **'Omitidas'**
  String get importExportRestoreSkipped;

  /// No description provided for @reportsTabSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get reportsTabSummary;

  /// No description provided for @reportsTabCashflow.
  ///
  /// In es, this message translates to:
  /// **'Flujo'**
  String get reportsTabCashflow;

  /// No description provided for @reportsTabNetWorth.
  ///
  /// In es, this message translates to:
  /// **'Patrimonio'**
  String get reportsTabNetWorth;

  /// No description provided for @reportsTabCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get reportsTabCategories;

  /// No description provided for @reportsPeriodLastMonths.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Último mes} other{Últimos {count} meses}}'**
  String reportsPeriodLastMonths(int count);

  /// No description provided for @reportsPeriodDaysWithData.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} día con datos} other{{count} días con datos}}'**
  String reportsPeriodDaysWithData(int count);

  /// No description provided for @reportsPeriodSinceDate.
  ///
  /// In es, this message translates to:
  /// **'Desde el {date}'**
  String reportsPeriodSinceDate(String date);

  /// No description provided for @reportsPeriodSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Filtrar periodo'**
  String get reportsPeriodSheetTitle;

  /// No description provided for @reportsPeriodGranularityMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get reportsPeriodGranularityMonth;

  /// No description provided for @reportsPeriodGranularityYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get reportsPeriodGranularityYear;

  /// No description provided for @reportsPeriodClear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get reportsPeriodClear;

  /// No description provided for @reportsCashflowCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Flujo de caja'**
  String get reportsCashflowCardTitle;

  /// No description provided for @reportsCashflowCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresos vs. gastos, mes a mes'**
  String get reportsCashflowCardSubtitle;

  /// No description provided for @reportsCashflowIncomeLabel.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get reportsCashflowIncomeLabel;

  /// No description provided for @reportsCashflowExpenseLabel.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get reportsCashflowExpenseLabel;

  /// No description provided for @reportsCashflowDebtLegendLabel.
  ///
  /// In es, this message translates to:
  /// **'Movimientos de deuda'**
  String get reportsCashflowDebtLegendLabel;

  /// No description provided for @reportsCashflowPositiveLabel.
  ///
  /// In es, this message translates to:
  /// **'Ahorraste en {periodPhrase}'**
  String reportsCashflowPositiveLabel(String periodPhrase);

  /// No description provided for @reportsCashflowNegativeLabel.
  ///
  /// In es, this message translates to:
  /// **'Balance de {periodPhrase}'**
  String reportsCashflowNegativeLabel(String periodPhrase);

  /// No description provided for @reportsCashflowShortHistoryLabel.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{Balance de tu primer día} other{Balance de tus primeros {count} días}}'**
  String reportsCashflowShortHistoryLabel(int count);

  /// No description provided for @reportsCashflowPeriodPhraseLastMonths.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{el último mes} other{los últimos {count} meses}}'**
  String reportsCashflowPeriodPhraseLastMonths(int count);

  /// No description provided for @reportsCashflowPeriodPhraseGeneric.
  ///
  /// In es, this message translates to:
  /// **'el periodo seleccionado'**
  String get reportsCashflowPeriodPhraseGeneric;

  /// No description provided for @reportsCashflowNegativeExplainer.
  ///
  /// In es, this message translates to:
  /// **'Salió {amount} más de lo que entró en {periodPhrase}. Abajo puedes ver qué meses pesaron más.'**
  String reportsCashflowNegativeExplainer(String amount, String periodPhrase);

  /// No description provided for @reportsCashflowViewCategoriesLink.
  ///
  /// In es, this message translates to:
  /// **'Ver en qué se fue'**
  String get reportsCashflowViewCategoriesLink;

  /// No description provided for @reportsCashflowCurrentMonthNote.
  ///
  /// In es, this message translates to:
  /// **'{month} va en curso: llega hasta el {day}.'**
  String reportsCashflowCurrentMonthNote(String month, int day);

  /// No description provided for @reportsCashflowDebtToggleLabel.
  ///
  /// In es, this message translates to:
  /// **'Separar movimientos de deuda'**
  String get reportsCashflowDebtToggleLabel;

  /// No description provided for @reportsCashflowDebtToggleHint.
  ///
  /// In es, this message translates to:
  /// **'Se muestran como una serie aparte, nunca se ocultan.'**
  String get reportsCashflowDebtToggleHint;

  /// No description provided for @reportsCashflowShortHistoryNote.
  ///
  /// In es, this message translates to:
  /// **'Ajustamos la vista a los días que ya registraste. Cuando completes tu primer mes, verás la comparación mes a mes.'**
  String get reportsCashflowShortHistoryNote;

  /// No description provided for @reportsNetWorthCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Patrimonio'**
  String get reportsNetWorthCardTitle;

  /// No description provided for @reportsNetWorthCaption.
  ///
  /// In es, this message translates to:
  /// **'El líquido es lo que puedes usar hoy. El total resta lo que debes y suma lo que te deben.'**
  String get reportsNetWorthCaption;

  /// No description provided for @reportsNetWorthLegendLiquid.
  ///
  /// In es, this message translates to:
  /// **'Patrimonio líquido'**
  String get reportsNetWorthLegendLiquid;

  /// No description provided for @reportsNetWorthLegendTotal.
  ///
  /// In es, this message translates to:
  /// **'Patrimonio total'**
  String get reportsNetWorthLegendTotal;

  /// No description provided for @reportsNetWorthFigureLiquidLabel.
  ///
  /// In es, this message translates to:
  /// **'Líquido'**
  String get reportsNetWorthFigureLiquidLabel;

  /// No description provided for @reportsNetWorthFigureTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get reportsNetWorthFigureTotalLabel;

  /// Texto para lectores de pantalla del Hero Patrimonio: figuras líquido y total.
  ///
  /// In es, this message translates to:
  /// **'{liquidLabel}: {liquidAmount}. {totalLabel}: {totalAmount}.'**
  String reportsNetWorthHeroSemantics(String liquidLabel, String liquidAmount,
      String totalLabel, String totalAmount);

  /// No description provided for @reportsNetWorthInterestNote.
  ///
  /// In es, this message translates to:
  /// **'El interés de una deuda baja tu patrimonio, pero no aparece en Flujo: no es plata que salió de una cuenta.'**
  String get reportsNetWorthInterestNote;

  /// No description provided for @reportsNetWorthArchivedToggleLabel.
  ///
  /// In es, this message translates to:
  /// **'Incluir cuentas archivadas'**
  String get reportsNetWorthArchivedToggleLabel;

  /// No description provided for @reportsNetWorthArchivedToggleHint.
  ///
  /// In es, this message translates to:
  /// **'Hoy quedan fuera de las dos cifras.'**
  String get reportsNetWorthArchivedToggleHint;

  /// No description provided for @reportsNetWorthSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Del cierre de {from} al {to} · {currency}'**
  String reportsNetWorthSubtitle(String from, String to, String currency);

  /// No description provided for @reportsCategoriesCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Estructura de gasto'**
  String get reportsCategoriesCardTitle;

  /// No description provided for @reportsCategoriesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{isSubcategory, select, true{{count, plural, one{{count} subcategoría · {range}} other{{count} subcategorías · {range}}}} other{{count, plural, one{{count} categoría · {range}} other{{count} categorías · {range}}}}}'**
  String reportsCategoriesSubtitle(
      int count, String range, String isSubcategory);

  /// No description provided for @reportsCategoriesTopLabel.
  ///
  /// In es, this message translates to:
  /// **'Mayor gasto: {name} · {pct}%'**
  String reportsCategoriesTopLabel(String name, int pct);

  /// No description provided for @reportsCategoriesUncategorized.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get reportsCategoriesUncategorized;

  /// Texto para lectores de pantalla de una fila del desglose por categoría: nombre, porcentaje y monto.
  ///
  /// In es, this message translates to:
  /// **'{name}, {pct}%, {amount}'**
  String reportsCategoriesRowSemantics(String name, int pct, String amount);

  /// Porcentaje formateado para figuras de Gráficas (desglose de categorías, metas del resumen).
  ///
  /// In es, this message translates to:
  /// **'{pct}%'**
  String reportsPercentValue(int pct);

  /// No description provided for @reportsCategoriesViewSubcategories.
  ///
  /// In es, this message translates to:
  /// **'Profundizar'**
  String get reportsCategoriesViewSubcategories;

  /// No description provided for @reportsCategoriesBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get reportsCategoriesBack;

  /// No description provided for @reportsCategoriesMovementsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} movimiento} other{{count} movimientos}}'**
  String reportsCategoriesMovementsCount(int count);

  /// No description provided for @reportsDashboardBudgetsTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuestos'**
  String get reportsDashboardBudgetsTitle;

  /// No description provided for @reportsDashboardBudgetsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} presupuesto activo · ciclos propios} other{{count} presupuestos activos · ciclos propios}}'**
  String reportsDashboardBudgetsSubtitle(int count);

  /// No description provided for @reportsDashboardGoalsTitle.
  ///
  /// In es, this message translates to:
  /// **'Metas'**
  String get reportsDashboardGoalsTitle;

  /// No description provided for @reportsDashboardGoalsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one{{count} meta en curso} other{{count} metas en curso}}'**
  String reportsDashboardGoalsSubtitle(int count);

  /// No description provided for @reportsGoalSummaryAmountOfTarget.
  ///
  /// In es, this message translates to:
  /// **'{saved} de {target}'**
  String reportsGoalSummaryAmountOfTarget(String saved, String target);

  /// No description provided for @reportsDashboardBudgetsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no has creado ninguno'**
  String get reportsDashboardBudgetsEmptySubtitle;

  /// No description provided for @reportsDashboardBudgetsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuando crees un presupuesto, aquí verás cuánto te queda del ciclo.'**
  String get reportsDashboardBudgetsEmptyMessage;

  /// No description provided for @reportsDashboardGoalsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no has creado ninguna'**
  String get reportsDashboardGoalsEmptySubtitle;

  /// No description provided for @reportsDashboardGoalsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Tus metas de ahorro mostrarán su avance aquí, todas juntas.'**
  String get reportsDashboardGoalsEmptyMessage;

  /// No description provided for @reportsDashboardCrossLinkDebts.
  ///
  /// In es, this message translates to:
  /// **'Ver el avance de tus deudas'**
  String get reportsDashboardCrossLinkDebts;

  /// No description provided for @reportsDashboardHeroBudgetsAvailable.
  ///
  /// In es, this message translates to:
  /// **'{amount} disponibles'**
  String reportsDashboardHeroBudgetsAvailable(String amount);

  /// No description provided for @reportsDashboardHeroGoalsSaved.
  ///
  /// In es, this message translates to:
  /// **'{amount} ahorrados'**
  String reportsDashboardHeroGoalsSaved(String amount);

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay movimientos en este periodo'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Registra un gasto o un ingreso y aquí verás cómo se mueve tu plata mes a mes.'**
  String get reportsEmptyMessage;

  /// No description provided for @reportsSyncNoticeMessage.
  ///
  /// In es, this message translates to:
  /// **'Hay cambios sin sincronizar. Lo que ves aquí está completo y guardado en tu teléfono.'**
  String get reportsSyncNoticeMessage;

  /// No description provided for @reportsExportTooltip.
  ///
  /// In es, this message translates to:
  /// **'Exportar como imagen'**
  String get reportsExportTooltip;

  /// No description provided for @reportsExportError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos exportar la gráfica. Intenta de nuevo.'**
  String get reportsExportError;

  /// No description provided for @reportsExportShareText.
  ///
  /// In es, this message translates to:
  /// **'Gráfica de {title} — billetudo'**
  String reportsExportShareText(String title);

  /// Etiqueta accesible del estado de carga (skeleton) de una gráfica.
  ///
  /// In es, this message translates to:
  /// **'Cargando gráfica'**
  String get reportsChartSkeletonLoadingLabel;

  /// Label del filtro de cuentas de Gráficas cuando no hay selección (todas incluidas).
  ///
  /// In es, this message translates to:
  /// **'Todas las cuentas'**
  String get reportsAccountFilterAll;

  /// Label del filtro de cuentas de Gráficas con una selección parcial.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cuenta} other{{count} cuentas}}'**
  String reportsAccountFilterSelected(int count);

  /// No description provided for @accountTypeSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el tipo de cuenta'**
  String get accountTypeSheetTitle;

  /// No description provided for @onboardingWelcomeHeadline.
  ///
  /// In es, this message translates to:
  /// **'Todo lo esencial. Gratis. Para siempre.'**
  String get onboardingWelcomeHeadline;

  /// No description provided for @onboardingWelcomeSubhead.
  ///
  /// In es, this message translates to:
  /// **'Tus datos viven en tu teléfono. El respaldo en la nube es opcional.'**
  String get onboardingWelcomeSubhead;

  /// No description provided for @onboardingWelcomeCta.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get onboardingWelcomeCta;

  /// No description provided for @onboardingAlreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo cuenta'**
  String get onboardingAlreadyHaveAccount;

  /// No description provided for @onboardingAccountHeadline.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera cuenta'**
  String get onboardingAccountHeadline;

  /// No description provided for @onboardingAccountSubhead.
  ///
  /// In es, this message translates to:
  /// **'Empieza con esta sugerencia o cámbiala a tu gusto.'**
  String get onboardingAccountSubhead;

  /// Nombre pre-llenado de la primera cuenta del onboarding (HU-02).
  ///
  /// In es, this message translates to:
  /// **'Ahorros'**
  String get onboardingAccountDefaultName;

  /// No description provided for @onboardingAccountCta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get onboardingAccountCta;

  /// No description provided for @onboardingAccountSkip.
  ///
  /// In es, this message translates to:
  /// **'Omitir por ahora'**
  String get onboardingAccountSkip;

  /// No description provided for @onboardingBackupHeadline.
  ///
  /// In es, this message translates to:
  /// **'Respalda tus datos, cuando quieras'**
  String get onboardingBackupHeadline;

  /// No description provided for @onboardingBackupBody.
  ///
  /// In es, this message translates to:
  /// **'Hoy tus datos viven solo en este teléfono. El respaldo es gratis y los guarda en la nube, listos para recuperarlos si cambias de equipo o reinstalas — sin él, se quedan únicamente aquí.'**
  String get onboardingBackupBody;

  /// No description provided for @onboardingBackupFootnote.
  ///
  /// In es, this message translates to:
  /// **'Actívalo luego en Ajustes → Respaldar.'**
  String get onboardingBackupFootnote;

  /// No description provided for @onboardingBackupCta.
  ///
  /// In es, this message translates to:
  /// **'Activar respaldo'**
  String get onboardingBackupCta;

  /// No description provided for @onboardingBackupSkip.
  ///
  /// In es, this message translates to:
  /// **'Después'**
  String get onboardingBackupSkip;

  /// No description provided for @onboardingClosingHeadline.
  ///
  /// In es, this message translates to:
  /// **'Tu billetera está lista'**
  String get onboardingClosingHeadline;

  /// No description provided for @onboardingClosingSubheadWithAccount.
  ///
  /// In es, this message translates to:
  /// **'Registra tu primer movimiento y empieza a tomar el control de tu dinero.'**
  String get onboardingClosingSubheadWithAccount;

  /// No description provided for @onboardingClosingSubheadNoAccount.
  ///
  /// In es, this message translates to:
  /// **'Para registrar movimientos necesitas una cuenta. Crea la primera en un momento.'**
  String get onboardingClosingSubheadNoAccount;

  /// No description provided for @onboardingClosingCtaTransaction.
  ///
  /// In es, this message translates to:
  /// **'Registra tu primer movimiento'**
  String get onboardingClosingCtaTransaction;

  /// No description provided for @onboardingClosingCtaAccount.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera cuenta'**
  String get onboardingClosingCtaAccount;

  /// No description provided for @onboardingClosingSkip.
  ///
  /// In es, this message translates to:
  /// **'Lo hago después'**
  String get onboardingClosingSkip;

  /// No description provided for @tutorialGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get tutorialGotIt;

  /// No description provided for @tutorialsMenuViewHelp.
  ///
  /// In es, this message translates to:
  /// **'Ver ayuda'**
  String get tutorialsMenuViewHelp;

  /// No description provided for @budgetsMenuViewHelpSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Repasa cómo funcionan los presupuestos'**
  String get budgetsMenuViewHelpSubtitle;

  /// No description provided for @goalsMenuViewHelpSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Repasa cómo funcionan las metas'**
  String get goalsMenuViewHelpSubtitle;

  /// No description provided for @debtsMenuViewHelpSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Repasa cómo funcionan las deudas'**
  String get debtsMenuViewHelpSubtitle;

  /// No description provided for @scheduledPaymentsMenuViewHelpSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Repasa cómo funcionan los pagos programados'**
  String get scheduledPaymentsMenuViewHelpSubtitle;

  /// No description provided for @goalsMenuTooltip.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get goalsMenuTooltip;

  /// No description provided for @goalsMenuOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get goalsMenuOptions;

  /// No description provided for @goalsMenuArchived.
  ///
  /// In es, this message translates to:
  /// **'Ver archivados'**
  String get goalsMenuArchived;

  /// No description provided for @debtsMenuTooltip.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get debtsMenuTooltip;

  /// No description provided for @debtsMenuOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get debtsMenuOptions;

  /// No description provided for @scheduledPaymentsMenuTooltip.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get scheduledPaymentsMenuTooltip;

  /// No description provided for @scheduledPaymentsMenuOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get scheduledPaymentsMenuOptions;

  /// No description provided for @settingsShowHelpOnEntry.
  ///
  /// In es, this message translates to:
  /// **'Mostrar ayuda al entrar a una sección'**
  String get settingsShowHelpOnEntry;

  /// No description provided for @settingsShowHelpOnEntrySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Explica cada sección la primera vez que entras.'**
  String get settingsShowHelpOnEntrySubtitle;

  /// No description provided for @tutorialBudgetsTitle.
  ///
  /// In es, this message translates to:
  /// **'Así funcionan los presupuestos'**
  String get tutorialBudgetsTitle;

  /// No description provided for @tutorialBudgetsPoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Un presupuesto por período'**
  String get tutorialBudgetsPoint1Heading;

  /// No description provided for @tutorialBudgetsPoint1Body.
  ///
  /// In es, this message translates to:
  /// **'Defines un monto para gastar en un período (semanal, quincenal, mensual o solo por esta vez) y ves cuánto te queda mientras avanza.'**
  String get tutorialBudgetsPoint1Body;

  /// No description provided for @tutorialBudgetsPoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'Con el alcance que tú eliges'**
  String get tutorialBudgetsPoint2Heading;

  /// No description provided for @tutorialBudgetsPoint2Body.
  ///
  /// In es, this message translates to:
  /// **'Puede cubrir todo tu gasto, o enfocarse solo en una cuenta o categoría en particular.'**
  String get tutorialBudgetsPoint2Body;

  /// No description provided for @tutorialBudgetsPoint3Heading.
  ///
  /// In es, this message translates to:
  /// **'El modo sobres, para más control'**
  String get tutorialBudgetsPoint3Heading;

  /// No description provided for @tutorialBudgetsPoint3Body.
  ///
  /// In es, this message translates to:
  /// **'Reparte todo tu ingreso entre tus categorías, para que cada peso ya tenga un destino desde el inicio.'**
  String get tutorialBudgetsPoint3Body;

  /// No description provided for @tutorialBudgetsCta.
  ///
  /// In es, this message translates to:
  /// **'Crear mi primer presupuesto'**
  String get tutorialBudgetsCta;

  /// No description provided for @tutorialGoalsTitle.
  ///
  /// In es, this message translates to:
  /// **'Así funcionan las metas'**
  String get tutorialGoalsTitle;

  /// No description provided for @tutorialGoalsPoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Para qué sirve una meta'**
  String get tutorialGoalsPoint1Heading;

  /// No description provided for @tutorialGoalsPoint1Body.
  ///
  /// In es, this message translates to:
  /// **'Úsala para ahorrar para algo puntual, como un viaje, un fondo de emergencia o un regalo, y ver tu avance en cualquier momento.'**
  String get tutorialGoalsPoint1Body;

  /// No description provided for @tutorialGoalsPoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'El avance se arma con tus aportes'**
  String get tutorialGoalsPoint2Heading;

  /// No description provided for @tutorialGoalsPoint2Body.
  ///
  /// In es, this message translates to:
  /// **'Cada vez que registras un aporte, tu progreso sube. No es un número que tú edites: es la suma de lo que has ido aportando.'**
  String get tutorialGoalsPoint2Body;

  /// No description provided for @tutorialGoalsPoint3Heading.
  ///
  /// In es, this message translates to:
  /// **'Un aporte puede mover dinero, o no'**
  String get tutorialGoalsPoint3Heading;

  /// No description provided for @tutorialGoalsPoint3Body.
  ///
  /// In es, this message translates to:
  /// **'Puedes aportar moviendo dinero real de una cuenta, o solo dejarlo anotado sin tocar tu saldo (útil si ya guardaste ese dinero en otro lado).'**
  String get tutorialGoalsPoint3Body;

  /// No description provided for @tutorialGoalsCta.
  ///
  /// In es, this message translates to:
  /// **'Crear mi primera meta'**
  String get tutorialGoalsCta;

  /// No description provided for @tutorialDebtsTitle.
  ///
  /// In es, this message translates to:
  /// **'Así funcionan las deudas'**
  String get tutorialDebtsTitle;

  /// No description provided for @tutorialDebtsPoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Para qué sirve una deuda'**
  String get tutorialDebtsPoint1Heading;

  /// No description provided for @tutorialDebtsPoint1Body.
  ///
  /// In es, this message translates to:
  /// **'Lleva el control del dinero que debes (a un banco, una tarjeta o una persona) o que te deben a ti, sin tener que hacer cuentas a mano.'**
  String get tutorialDebtsPoint1Body;

  /// No description provided for @tutorialDebtsPoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'Tú registras, la app calcula'**
  String get tutorialDebtsPoint2Heading;

  /// No description provided for @tutorialDebtsPoint2Body.
  ///
  /// In es, this message translates to:
  /// **'Anotas lo que pediste prestado, lo que has abonado y los intereses que se suman, y la app calcula sola cuánto falta por pagar.'**
  String get tutorialDebtsPoint2Body;

  /// No description provided for @tutorialDebtsPoint3Heading.
  ///
  /// In es, this message translates to:
  /// **'Un abono puede mover dinero, o no'**
  String get tutorialDebtsPoint3Heading;

  /// No description provided for @tutorialDebtsPoint3Body.
  ///
  /// In es, this message translates to:
  /// **'Puedes descontar un abono de una de tus cuentas, o solo anotarlo sin mover dinero (útil si alguien más pagó por ti, o si fue en efectivo).'**
  String get tutorialDebtsPoint3Body;

  /// No description provided for @tutorialDebtsCta.
  ///
  /// In es, this message translates to:
  /// **'Registrar mi primera deuda'**
  String get tutorialDebtsCta;

  /// No description provided for @tutorialScheduledPaymentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Así funcionan los pagos programados'**
  String get tutorialScheduledPaymentsTitle;

  /// No description provided for @tutorialScheduledPaymentsPoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Para qué sirven'**
  String get tutorialScheduledPaymentsPoint1Heading;

  /// No description provided for @tutorialScheduledPaymentsPoint1Body.
  ///
  /// In es, this message translates to:
  /// **'Sirven para no olvidar pagos que se repiten, como el arriendo, una suscripción o una cuota, y dejar que la app los registre por ti si quieres.'**
  String get tutorialScheduledPaymentsPoint1Body;

  /// No description provided for @tutorialScheduledPaymentsPoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'Automático o manual'**
  String get tutorialScheduledPaymentsPoint2Heading;

  /// No description provided for @tutorialScheduledPaymentsPoint2Body.
  ///
  /// In es, this message translates to:
  /// **'Uno automático se registra solo en su fecha. Uno manual te avisa y tú confirmas antes de que cuente (útil si el monto cambia cada vez).'**
  String get tutorialScheduledPaymentsPoint2Body;

  /// No description provided for @tutorialScheduledPaymentsPoint3Heading.
  ///
  /// In es, this message translates to:
  /// **'La bandeja de vencimientos'**
  String get tutorialScheduledPaymentsPoint3Heading;

  /// No description provided for @tutorialScheduledPaymentsPoint3Body.
  ///
  /// In es, this message translates to:
  /// **'Ahí ves todos tus pagos pendientes en un solo lugar y los confirmas cuando te llegan.'**
  String get tutorialScheduledPaymentsPoint3Body;

  /// No description provided for @tutorialScheduledPaymentsCta.
  ///
  /// In es, this message translates to:
  /// **'Programar mi primer pago'**
  String get tutorialScheduledPaymentsCta;

  /// No description provided for @tutorialDebtLinkMovementTitle.
  ///
  /// In es, this message translates to:
  /// **'Enlazar un movimiento existente'**
  String get tutorialDebtLinkMovementTitle;

  /// No description provided for @tutorialDebtLinkMovementPoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'No crea un movimiento nuevo'**
  String get tutorialDebtLinkMovementPoint1Heading;

  /// No description provided for @tutorialDebtLinkMovementPoint1Body.
  ///
  /// In es, this message translates to:
  /// **'Atribuye uno que ya registraste, para no duplicar.'**
  String get tutorialDebtLinkMovementPoint1Body;

  /// No description provided for @tutorialGoalLinkMovementTitle.
  ///
  /// In es, this message translates to:
  /// **'Enlazar un movimiento existente'**
  String get tutorialGoalLinkMovementTitle;

  /// No description provided for @tutorialGoalLinkMovementPoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'No crea un movimiento nuevo'**
  String get tutorialGoalLinkMovementPoint1Heading;

  /// No description provided for @tutorialGoalLinkMovementPoint1Body.
  ///
  /// In es, this message translates to:
  /// **'Atribuye uno que ya registraste, para no duplicar.'**
  String get tutorialGoalLinkMovementPoint1Body;

  /// No description provided for @tutorialDebtPaymentToggleTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Agregar el abono a una cuenta?'**
  String get tutorialDebtPaymentToggleTitle;

  /// No description provided for @tutorialDebtPaymentTogglePoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Si eliges \"Sí\"'**
  String get tutorialDebtPaymentTogglePoint1Heading;

  /// No description provided for @tutorialDebtPaymentTogglePoint1Body.
  ///
  /// In es, this message translates to:
  /// **'El abono también descuenta el monto de la cuenta que elijas, como una transacción real.'**
  String get tutorialDebtPaymentTogglePoint1Body;

  /// No description provided for @tutorialDebtPaymentTogglePoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'Si eliges \"No\"'**
  String get tutorialDebtPaymentTogglePoint2Heading;

  /// No description provided for @tutorialDebtPaymentTogglePoint2Body.
  ///
  /// In es, this message translates to:
  /// **'La deuda baja igual, pero no se toca ningún saldo (útil si pagaste en efectivo o alguien más pagó por ti).'**
  String get tutorialDebtPaymentTogglePoint2Body;

  /// No description provided for @tutorialGoalContributionToggleTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Mover dinero de una cuenta?'**
  String get tutorialGoalContributionToggleTitle;

  /// No description provided for @tutorialGoalContributionTogglePoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Si eliges \"Sí\"'**
  String get tutorialGoalContributionTogglePoint1Heading;

  /// No description provided for @tutorialGoalContributionTogglePoint1Body.
  ///
  /// In es, this message translates to:
  /// **'El aporte descuenta el monto real de una cuenta, como una transferencia.'**
  String get tutorialGoalContributionTogglePoint1Body;

  /// No description provided for @tutorialGoalContributionTogglePoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'Si eliges \"No\"'**
  String get tutorialGoalContributionTogglePoint2Heading;

  /// No description provided for @tutorialGoalContributionTogglePoint2Body.
  ///
  /// In es, this message translates to:
  /// **'El aporte solo queda anotado en la meta, sin tocar ningún saldo (útil si ya guardaste ese dinero en otro lado).'**
  String get tutorialGoalContributionTogglePoint2Body;

  /// No description provided for @tutorialDebtScheduledInstallmentTitle.
  ///
  /// In es, this message translates to:
  /// **'La cuota vive en Pagos programados'**
  String get tutorialDebtScheduledInstallmentTitle;

  /// No description provided for @tutorialDebtScheduledInstallmentPoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Se configura aquí, se confirma allá'**
  String get tutorialDebtScheduledInstallmentPoint1Heading;

  /// No description provided for @tutorialDebtScheduledInstallmentPoint1Body.
  ///
  /// In es, this message translates to:
  /// **'La configuras desde esta deuda, pero se confirma desde la bandeja de Pagos programados, como cualquier otro pago.'**
  String get tutorialDebtScheduledInstallmentPoint1Body;

  /// No description provided for @tutorialDebtScheduledInstallmentPoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'Un solo movimiento, dos efectos'**
  String get tutorialDebtScheduledInstallmentPoint2Heading;

  /// No description provided for @tutorialDebtScheduledInstallmentPoint2Body.
  ///
  /// In es, this message translates to:
  /// **'Al confirmarla, un solo movimiento baja el saldo de tu cuenta y abona a la deuda al mismo tiempo.'**
  String get tutorialDebtScheduledInstallmentPoint2Body;

  /// No description provided for @tutorialBudgetableTransferTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Contar esta transferencia en tu presupuesto?'**
  String get tutorialBudgetableTransferTitle;

  /// No description provided for @tutorialBudgetableTransferPoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Para qué sirve marcarla'**
  String get tutorialBudgetableTransferPoint1Heading;

  /// No description provided for @tutorialBudgetableTransferPoint1Body.
  ///
  /// In es, this message translates to:
  /// **'Algunas transferencias sí son parte de tu plan de gasto, aunque no sean un gasto real (por ejemplo, mover dinero a la cuenta que usas para gastar en el mes).'**
  String get tutorialBudgetableTransferPoint1Body;

  /// No description provided for @tutorialBudgetableTransferPoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'Qué cambia al marcarla'**
  String get tutorialBudgetableTransferPoint2Heading;

  /// No description provided for @tutorialBudgetableTransferPoint2Body.
  ///
  /// In es, this message translates to:
  /// **'Se resta de tu presupuesto igual que un gasto, aunque el dinero siga siendo tuyo, solo que en otra cuenta.'**
  String get tutorialBudgetableTransferPoint2Body;

  /// No description provided for @tutorialEnvelopeModeTitle.
  ///
  /// In es, this message translates to:
  /// **'Así funciona el modo sobres'**
  String get tutorialEnvelopeModeTitle;

  /// No description provided for @tutorialEnvelopeModePoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Para qué sirve'**
  String get tutorialEnvelopeModePoint1Heading;

  /// No description provided for @tutorialEnvelopeModePoint1Body.
  ///
  /// In es, this message translates to:
  /// **'Reparte todo tu ingreso entre tus categorías, para que cada peso ya tenga un destino desde el inicio.'**
  String get tutorialEnvelopeModePoint1Body;

  /// No description provided for @tutorialEnvelopeModePoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'Qué cambia en la pantalla'**
  String get tutorialEnvelopeModePoint2Heading;

  /// No description provided for @tutorialEnvelopeModePoint2Body.
  ///
  /// In es, this message translates to:
  /// **'En vez de un solo monto libre, ves cuánto le queda a cada categoría por separado.'**
  String get tutorialEnvelopeModePoint2Body;

  /// No description provided for @tutorialBudgetFeaturedChoiceTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige qué presupuesto destacar'**
  String get tutorialBudgetFeaturedChoiceTitle;

  /// No description provided for @tutorialBudgetFeaturedChoicePoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Uno a la vez en Inicio'**
  String get tutorialBudgetFeaturedChoicePoint1Heading;

  /// No description provided for @tutorialBudgetFeaturedChoicePoint1Body.
  ///
  /// In es, this message translates to:
  /// **'El presupuesto destacado es el que ves en la portada de Inicio. Ahora que tienes más de uno, puedes elegir cuál.'**
  String get tutorialBudgetFeaturedChoicePoint1Body;

  /// No description provided for @tutorialBudgetFeaturedChoicePoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'Cámbialo cuando quieras'**
  String get tutorialBudgetFeaturedChoicePoint2Heading;

  /// No description provided for @tutorialBudgetFeaturedChoicePoint2Body.
  ///
  /// In es, this message translates to:
  /// **'Entra a un presupuesto y usa el menú ⋮ para marcarlo como destacado o quitarlo. Es reversible en cualquier momento.'**
  String get tutorialBudgetFeaturedChoicePoint2Body;

  /// No description provided for @aiChatTitle.
  ///
  /// In es, this message translates to:
  /// **'Billetudo'**
  String get aiChatTitle;

  /// No description provided for @aiChatHistoryTooltip.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get aiChatHistoryTooltip;

  /// No description provided for @aiChatNewConversationTooltip.
  ///
  /// In es, this message translates to:
  /// **'Nueva conversación'**
  String get aiChatNewConversationTooltip;

  /// No description provided for @aiChatBetaBadge.
  ///
  /// In es, this message translates to:
  /// **'Beta'**
  String get aiChatBetaBadge;

  /// No description provided for @aiChatDisclaimer.
  ///
  /// In es, this message translates to:
  /// **'Respuestas generadas con IA. No es asesoría financiera.'**
  String get aiChatDisclaimer;

  /// No description provided for @aiChatComposerHint.
  ///
  /// In es, this message translates to:
  /// **'Escríbele a Billetudo…'**
  String get aiChatComposerHint;

  /// No description provided for @aiChatEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Por dónde empezamos?'**
  String get aiChatEmptyTitle;

  /// No description provided for @aiChatEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige una pregunta o escríbeme lo que necesites.'**
  String get aiChatEmptySubtitle;

  /// No description provided for @aiChatSuggestionMonthProgress.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo voy este mes?'**
  String get aiChatSuggestionMonthProgress;

  /// No description provided for @aiChatSuggestionBuildBudget.
  ///
  /// In es, this message translates to:
  /// **'Ayudame a armar un presupuesto'**
  String get aiChatSuggestionBuildBudget;

  /// No description provided for @aiChatSuggestionGoalsSaved.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto llevo ahorrado en mis metas?'**
  String get aiChatSuggestionGoalsSaved;

  /// No description provided for @aiChatSuggestionBiggestSpend.
  ///
  /// In es, this message translates to:
  /// **'¿En qué se me fue más la plata?'**
  String get aiChatSuggestionBiggestSpend;

  /// No description provided for @aiChatErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pude responder'**
  String get aiChatErrorTitle;

  /// No description provided for @aiChatErrorBody.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar tu mensaje. Inténtalo de nuevo.'**
  String get aiChatErrorBody;

  /// No description provided for @aiChatMessageFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar. Inténtalo de nuevo.'**
  String get aiChatMessageFailed;

  /// No description provided for @aiChatCopyMessage.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get aiChatCopyMessage;

  /// No description provided for @aiSignedOutTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistente'**
  String get aiSignedOutTitle;

  /// No description provided for @aiSignedOutHeadline.
  ///
  /// In es, this message translates to:
  /// **'Iniciá sesión para usar el asistente'**
  String get aiSignedOutHeadline;

  /// No description provided for @aiSignedOutBody.
  ///
  /// In es, this message translates to:
  /// **'El asistente necesita tu sesión para conectarse y responderte. Iniciá sesión para empezar a chatear.'**
  String get aiSignedOutBody;

  /// No description provided for @aiConsentTitle.
  ///
  /// In es, this message translates to:
  /// **'Antes de empezar'**
  String get aiConsentTitle;

  /// No description provided for @aiConsentHeadline.
  ///
  /// In es, this message translates to:
  /// **'Billetudo usa un modelo de Google para responderte'**
  String get aiConsentHeadline;

  /// No description provided for @aiConsentBody.
  ///
  /// In es, this message translates to:
  /// **'Tu mensaje y un resumen de tus finanzas (sin notas ni datos de identificación bancaria) se envían a Google para generar la respuesta. Nunca se comparte tu cuenta, ni se ejecuta ninguna acción sin que la confirmes tú.'**
  String get aiConsentBody;

  /// No description provided for @aiConsentAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar y continuar'**
  String get aiConsentAccept;

  /// No description provided for @aiConsentDecline.
  ///
  /// In es, this message translates to:
  /// **'No, gracias'**
  String get aiConsentDecline;

  /// No description provided for @aiConsentViewHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver mis conversaciones anteriores'**
  String get aiConsentViewHistory;

  /// No description provided for @aiConversationReadTitle.
  ///
  /// In es, this message translates to:
  /// **'Conversación guardada'**
  String get aiConversationReadTitle;

  /// No description provided for @aiConversationReadBannerMessage.
  ///
  /// In es, this message translates to:
  /// **'Estás viendo una conversación guardada. Para escribir un mensaje nuevo, reactiva el asistente.'**
  String get aiConversationReadBannerMessage;

  /// No description provided for @aiConversationReadReactivateCta.
  ///
  /// In es, this message translates to:
  /// **'Reactivar asistente'**
  String get aiConversationReadReactivateCta;

  /// No description provided for @aiConversationReadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar esta conversación'**
  String get aiConversationReadErrorTitle;

  /// No description provided for @aiHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get aiHistoryTitle;

  /// No description provided for @aiHistoryDeleteAllTooltip.
  ///
  /// In es, this message translates to:
  /// **'Borrar todo'**
  String get aiHistoryDeleteAllTooltip;

  /// No description provided for @aiHistoryDeleteAllConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todo'**
  String get aiHistoryDeleteAllConfirm;

  /// No description provided for @aiHistoryDeleteOneSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Esta conversación se eliminará de tu historial de forma permanente. Esta acción no se puede deshacer.'**
  String get aiHistoryDeleteOneSheetMessage;

  /// No description provided for @aiHistoryDeleteAllSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán todas tus conversaciones con Billetudo de forma permanente. Esta acción no se puede deshacer.'**
  String get aiHistoryDeleteAllSheetMessage;

  /// No description provided for @aiHistoryEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes conversaciones con Billetudo'**
  String get aiHistoryEmptyMessage;

  /// No description provided for @aiHistoryEmptyCta.
  ///
  /// In es, this message translates to:
  /// **'Nueva conversación'**
  String get aiHistoryEmptyCta;

  /// No description provided for @aiHistoryErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu historial'**
  String get aiHistoryErrorTitle;

  /// No description provided for @aiHistoryRowDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get aiHistoryRowDelete;

  /// No description provided for @aiHistoryRowUntitled.
  ///
  /// In es, this message translates to:
  /// **'Conversación sin título'**
  String get aiHistoryRowUntitled;

  /// No description provided for @aiHistoryRowYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get aiHistoryRowYesterday;

  /// No description provided for @aiProposalKickerPending.
  ///
  /// In es, this message translates to:
  /// **'Propuesta'**
  String get aiProposalKickerPending;

  /// No description provided for @aiProposalKickerConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmado'**
  String get aiProposalKickerConfirmed;

  /// No description provided for @aiProposalKickerDismissed.
  ///
  /// In es, this message translates to:
  /// **'Descartada'**
  String get aiProposalKickerDismissed;

  /// No description provided for @aiProposalKickerFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar'**
  String get aiProposalKickerFailed;

  /// No description provided for @aiProposalFootnotePending.
  ///
  /// In es, this message translates to:
  /// **'Nada se guarda hasta que confirmes.'**
  String get aiProposalFootnotePending;

  /// No description provided for @aiProposalFootnoteConfirmedTransaction.
  ///
  /// In es, this message translates to:
  /// **'Aplicado a tus movimientos.'**
  String get aiProposalFootnoteConfirmedTransaction;

  /// No description provided for @aiProposalFootnoteConfirmedBudget.
  ///
  /// In es, this message translates to:
  /// **'Tu presupuesto ya está creado.'**
  String get aiProposalFootnoteConfirmedBudget;

  /// No description provided for @aiProposalFootnoteConfirmedGoal.
  ///
  /// In es, this message translates to:
  /// **'Tu meta ya está creada.'**
  String get aiProposalFootnoteConfirmedGoal;

  /// No description provided for @aiProposalFootnoteConfirmedCategory.
  ///
  /// In es, this message translates to:
  /// **'Tu categoría ya está creada.'**
  String get aiProposalFootnoteConfirmedCategory;

  /// No description provided for @aiProposalFootnoteDismissed.
  ///
  /// In es, this message translates to:
  /// **'No se guardó ningún cambio.'**
  String get aiProposalFootnoteDismissed;

  /// No description provided for @aiProposalFootnoteFailed.
  ///
  /// In es, this message translates to:
  /// **'Hubo un problema al registrar esto. Tus datos siguen a salvo en tu dispositivo.'**
  String get aiProposalFootnoteFailed;

  /// No description provided for @aiProposalActionDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get aiProposalActionDiscard;

  /// No description provided for @aiProposalActionConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get aiProposalActionConfirm;

  /// No description provided for @aiProposalActionRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get aiProposalActionRetry;

  /// No description provided for @aiProposalConfirmedRowTransaction.
  ///
  /// In es, this message translates to:
  /// **'Ya está en tus movimientos'**
  String get aiProposalConfirmedRowTransaction;

  /// No description provided for @aiProposalConfirmedRowBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto creado'**
  String get aiProposalConfirmedRowBudget;

  /// No description provided for @aiProposalConfirmedRowGoal.
  ///
  /// In es, this message translates to:
  /// **'Meta creada'**
  String get aiProposalConfirmedRowGoal;

  /// No description provided for @aiProposalConfirmedRowCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría creada'**
  String get aiProposalConfirmedRowCategory;

  /// No description provided for @aiProposalUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Esta versión de la app aún no puede aplicar esta propuesta.'**
  String get aiProposalUnsupported;

  /// No description provided for @aiProposalAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get aiProposalAmount;

  /// No description provided for @aiProposalPeriod.
  ///
  /// In es, this message translates to:
  /// **'Periodo'**
  String get aiProposalPeriod;

  /// No description provided for @aiProposalCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get aiProposalCategory;

  /// No description provided for @aiProposalScopeAllCategories.
  ///
  /// In es, this message translates to:
  /// **'Todas las categorías'**
  String get aiProposalScopeAllCategories;

  /// No description provided for @aiProposalScopeSomeCategories.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 categoría} other{{count} categorías}}'**
  String aiProposalScopeSomeCategories(num count);

  /// No description provided for @aiProposalGoalTarget.
  ///
  /// In es, this message translates to:
  /// **'Monto objetivo'**
  String get aiProposalGoalTarget;

  /// No description provided for @aiProposalGoalDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha objetivo'**
  String get aiProposalGoalDate;

  /// No description provided for @aiProposalGoalNoDate.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha límite'**
  String get aiProposalGoalNoDate;

  /// No description provided for @aiProposalCategoryType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get aiProposalCategoryType;

  /// No description provided for @aiProposalCategoryScope.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get aiProposalCategoryScope;

  /// No description provided for @aiProposalCategoryScopeRoot.
  ///
  /// In es, this message translates to:
  /// **'Categoría principal'**
  String get aiProposalCategoryScopeRoot;

  /// No description provided for @aiProposalCategoryScopeSub.
  ///
  /// In es, this message translates to:
  /// **'Subcategoría'**
  String get aiProposalCategoryScopeSub;

  /// No description provided for @aiProposalTransactionType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get aiProposalTransactionType;

  /// No description provided for @aiProposalTransactionDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get aiProposalTransactionDate;

  /// No description provided for @aiProposalTransactionAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get aiProposalTransactionAccount;

  /// No description provided for @aiProposalTransactionAccountUnknown.
  ///
  /// In es, this message translates to:
  /// **'Cuenta seleccionada'**
  String get aiProposalTransactionAccountUnknown;

  /// No description provided for @aiProposalTransactionDebt.
  ///
  /// In es, this message translates to:
  /// **'Deuda'**
  String get aiProposalTransactionDebt;

  /// No description provided for @aiProposalDebtUnknown.
  ///
  /// In es, this message translates to:
  /// **'Deuda seleccionada'**
  String get aiProposalDebtUnknown;

  /// No description provided for @aiProposalDebtLinkExplainer.
  ///
  /// In es, this message translates to:
  /// **'No se crea ningún movimiento nuevo ni se mueve dinero: el movimiento ya afectó tu cuenta. Con esto empieza a contar en el saldo de la deuda.'**
  String get aiProposalDebtLinkExplainer;

  /// No description provided for @aiProposalFootnoteConfirmedDebtLink.
  ///
  /// In es, this message translates to:
  /// **'El movimiento ya cuenta en tu deuda.'**
  String get aiProposalFootnoteConfirmedDebtLink;

  /// No description provided for @aiProposalConfirmedRowDebtLink.
  ///
  /// In es, this message translates to:
  /// **'Atribuido a la deuda'**
  String get aiProposalConfirmedRowDebtLink;

  /// No description provided for @aiMessageActionReport.
  ///
  /// In es, this message translates to:
  /// **'Reportar'**
  String get aiMessageActionReport;

  /// No description provided for @aiReportSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Reportar mensaje'**
  String get aiReportSheetTitle;

  /// No description provided for @aiReportSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué está mal con esta respuesta. Nos ayuda a mejorar Billetudo.'**
  String get aiReportSheetMessage;

  /// No description provided for @aiReportReasonOffensive.
  ///
  /// In es, this message translates to:
  /// **'Ofensivo'**
  String get aiReportReasonOffensive;

  /// No description provided for @aiReportReasonWrong.
  ///
  /// In es, this message translates to:
  /// **'Incorrecto'**
  String get aiReportReasonWrong;

  /// No description provided for @aiReportReasonHarmful.
  ///
  /// In es, this message translates to:
  /// **'Dañino'**
  String get aiReportReasonHarmful;

  /// No description provided for @aiReportReasonPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get aiReportReasonPrivacy;

  /// No description provided for @aiReportReasonOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get aiReportReasonOther;

  /// No description provided for @aiReportCommentLabel.
  ///
  /// In es, this message translates to:
  /// **'Comentario (opcional)'**
  String get aiReportCommentLabel;

  /// No description provided for @aiReportCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos más detalles…'**
  String get aiReportCommentHint;

  /// No description provided for @aiReportPrivacyNote.
  ///
  /// In es, this message translates to:
  /// **'Le enviaremos este mensaje a nuestro equipo para revisarlo. El resto de tu conversación se queda solo en tu dispositivo.'**
  String get aiReportPrivacyNote;

  /// No description provided for @aiReportSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get aiReportSubmit;

  /// No description provided for @aiReportSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'Gracias, revisaremos este mensaje.'**
  String get aiReportSuccessMessage;

  /// No description provided for @aiReportErrorUnauthenticated.
  ///
  /// In es, this message translates to:
  /// **'Necesitas iniciar sesión para reportar un mensaje.'**
  String get aiReportErrorUnauthenticated;

  /// No description provided for @aiReportErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar tu reporte. Inténtalo de nuevo.'**
  String get aiReportErrorGeneric;

  /// No description provided for @settingsAiSection.
  ///
  /// In es, this message translates to:
  /// **'Asistente de IA'**
  String get settingsAiSection;

  /// No description provided for @settingsCloudTranscription.
  ///
  /// In es, this message translates to:
  /// **'Transcribir mi voz en la nube'**
  String get settingsCloudTranscription;

  /// No description provided for @settingsCloudTranscriptionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuando este teléfono no puede convertir la voz en texto por su cuenta, el audio se envía a {vendor} solo para transcribirlo. billetudo no lo guarda ni lo sincroniza.'**
  String settingsCloudTranscriptionSubtitle(String vendor);

  /// No description provided for @settingsAiNotesAccess.
  ///
  /// In es, this message translates to:
  /// **'Dejar que el asistente lea mis notas'**
  String get settingsAiNotesAccess;

  /// No description provided for @settingsAiNotesAccessSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aunque esté apagado, el asistente sigue buscando en tus movimientos: la búsqueda ocurre en tu dispositivo y solo viajan datos ya organizados, nunca el texto de tus notas.'**
  String get settingsAiNotesAccessSubtitle;

  /// No description provided for @settingsAiNotesAccessSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Dejar que el asistente lea tus notas?'**
  String get settingsAiNotesAccessSheetTitle;

  /// No description provided for @settingsAiNotesAccessSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'Tus notas son texto libre: ahí suelen aparecer nombres de personas y detalles de tu vida. Si lo activas, la nota viaja a Google Gemini junto con tu pregunta para que el asistente entienda cómo llamas tú a las cosas: encontrar «lo de la luz» cuando la nota dice «factura de energía». Puedes apagarlo cuando quieras.'**
  String get settingsAiNotesAccessSheetMessage;

  /// No description provided for @settingsAiNotesAccessSheetConfirm.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get settingsAiNotesAccessSheetConfirm;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Qué datos guardamos, qué se comparte y con quién'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsTermsOfUse.
  ///
  /// In es, this message translates to:
  /// **'Términos de uso'**
  String get settingsTermsOfUse;

  /// No description provided for @settingsTermsOfUseSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Las reglas de uso de Billetudo'**
  String get settingsTermsOfUseSubtitle;

  /// No description provided for @settingsLegalLinkError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir el enlace. Inténtalo de nuevo.'**
  String get settingsLegalLinkError;

  /// No description provided for @settingsAiConsentWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Retirar el consentimiento de IA'**
  String get settingsAiConsentWithdraw;

  /// No description provided for @settingsAiConsentWithdrawSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Dejas de compartir datos con el asistente. Puedes volver a activarlo cuando quieras.'**
  String get settingsAiConsentWithdrawSubtitle;

  /// No description provided for @settingsAiConsentWithdrawSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Retirar el consentimiento?'**
  String get settingsAiConsentWithdrawSheetTitle;

  /// No description provided for @settingsAiConsentWithdrawSheetMessage.
  ///
  /// In es, this message translates to:
  /// **'El asistente deja de estar disponible y no se envía nada más a Google Gemini. También se apaga «Dejar que el asistente lea mis notas». Tus movimientos y tus conversaciones guardadas se quedan en tu dispositivo. Puedes volver a activarlo cuando quieras.'**
  String get settingsAiConsentWithdrawSheetMessage;

  /// No description provided for @settingsAiConsentWithdrawSheetConfirm.
  ///
  /// In es, this message translates to:
  /// **'Retirar'**
  String get settingsAiConsentWithdrawSheetConfirm;

  /// No description provided for @captureNoticesTitle.
  ///
  /// In es, this message translates to:
  /// **'Avisos'**
  String get captureNoticesTitle;

  /// No description provided for @captureSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Capturas por confirmar'**
  String get captureSectionTitle;

  /// No description provided for @captureSectionCaption.
  ///
  /// In es, this message translates to:
  /// **'Aún no afectan tu saldo. Se registran solo cuando tú lo confirmas.'**
  String get captureSectionCaption;

  /// No description provided for @captureSectionCaptionCompact.
  ///
  /// In es, this message translates to:
  /// **'Aún no afectan tu saldo hasta que tú confirmes.'**
  String get captureSectionCaptionCompact;

  /// No description provided for @captureOverflowLabel.
  ///
  /// In es, this message translates to:
  /// **'Ver las otras {count} capturas'**
  String captureOverflowLabel(int count);

  /// No description provided for @captureEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo al día'**
  String get captureEmptyTitle;

  /// No description provided for @captureEmptyDescription.
  ///
  /// In es, this message translates to:
  /// **'No tienes nada por revisar. Cuando tu banco te avise de una compra, o se acerque un pago, aparecerá aquí.'**
  String get captureEmptyDescription;

  /// No description provided for @captureNoIssuersTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no escuchamos ninguna app'**
  String get captureNoIssuersTitle;

  /// No description provided for @captureNoIssuersDescription.
  ///
  /// In es, this message translates to:
  /// **'Elige de qué apps de banco quieres que leamos los avisos de compra. Sin eso, aquí no aparece nada.'**
  String get captureNoIssuersDescription;

  /// No description provided for @captureNoIssuersCta.
  ///
  /// In es, this message translates to:
  /// **'Elegir apps'**
  String get captureNoIssuersCta;

  /// No description provided for @captureNotBalancePill.
  ///
  /// In es, this message translates to:
  /// **'No suma a tu saldo'**
  String get captureNotBalancePill;

  /// No description provided for @captureIssuerLabel.
  ///
  /// In es, this message translates to:
  /// **'Aviso de {issuer}'**
  String captureIssuerLabel(String issuer);

  /// No description provided for @captureConfirmAction.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get captureConfirmAction;

  /// No description provided for @captureNoAccount.
  ///
  /// In es, this message translates to:
  /// **'Sin cuenta'**
  String get captureNoAccount;

  /// No description provided for @captureNoMerchant.
  ///
  /// In es, this message translates to:
  /// **'Movimiento sin descripción'**
  String get captureNoMerchant;

  /// No description provided for @captureSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{account} · {when}'**
  String captureSubtitle(String account, String when);

  /// No description provided for @captureDuplicatePill.
  ///
  /// In es, this message translates to:
  /// **'Posible duplicado'**
  String get captureDuplicatePill;

  /// No description provided for @captureDuplicateSameAction.
  ///
  /// In es, this message translates to:
  /// **'Es la misma'**
  String get captureDuplicateSameAction;

  /// No description provided for @captureDuplicateOtherAction.
  ///
  /// In es, this message translates to:
  /// **'Es otra compra'**
  String get captureDuplicateOtherAction;

  /// No description provided for @captureDuplicateExistingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{category} · {account} · {when}'**
  String captureDuplicateExistingSubtitle(
      String category, String account, String when);

  /// No description provided for @captureGhostBlockTitle.
  ///
  /// In es, this message translates to:
  /// **'Pendientes de confirmar'**
  String get captureGhostBlockTitle;

  /// No description provided for @captureGhostBlockCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 propuesta · no suma} other{{count} propuestas · no suman}}'**
  String captureGhostBlockCount(int count);

  /// No description provided for @captureDiscardedMessage.
  ///
  /// In es, this message translates to:
  /// **'Captura descartada'**
  String get captureDiscardedMessage;

  /// No description provided for @captureBellTooltip.
  ///
  /// In es, this message translates to:
  /// **'Avisos'**
  String get captureBellTooltip;

  /// No description provided for @captureAccountCardLast4Label.
  ///
  /// In es, this message translates to:
  /// **'Últimos 4 dígitos de la tarjeta (opcional)'**
  String get captureAccountCardLast4Label;

  /// No description provided for @captureAccountCardLast4Hint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 4321'**
  String get captureAccountCardLast4Hint;

  /// No description provided for @captureAccountCardLast4Helper.
  ///
  /// In es, this message translates to:
  /// **'Cuando tu banco te avise de una compra, usamos estos 4 dígitos para sugerirte esta cuenta.'**
  String get captureAccountCardLast4Helper;

  /// No description provided for @captureAccountCardLast4Error.
  ///
  /// In es, this message translates to:
  /// **'Deben ser exactamente 4 dígitos.'**
  String get captureAccountCardLast4Error;

  /// No description provided for @capturePermissionHeader.
  ///
  /// In es, this message translates to:
  /// **'Avisos de tu banco'**
  String get capturePermissionHeader;

  /// No description provided for @capturePermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Leer los avisos de tu banco'**
  String get capturePermissionTitle;

  /// No description provided for @capturePermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Cuando tu banco te avise de una compra, la app te la propone con el monto y el comercio ya puestos. Tú confirmas y queda registrada.'**
  String get capturePermissionBody;

  /// No description provided for @capturePermissionFactAppsTitle.
  ///
  /// In es, this message translates to:
  /// **'Solo las apps que elijas'**
  String get capturePermissionFactAppsTitle;

  /// No description provided for @capturePermissionFactAppsDescription.
  ///
  /// In es, this message translates to:
  /// **'Tú decides qué apps de banco se leen. Chats, correos y todo lo demás queda fuera.'**
  String get capturePermissionFactAppsDescription;

  /// No description provided for @capturePermissionFactDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Solo monto, comercio y fecha'**
  String get capturePermissionFactDataTitle;

  /// No description provided for @capturePermissionFactDataDescription.
  ///
  /// In es, this message translates to:
  /// **'El texto de la notificación no se guarda en ninguna parte, tampoco en tu teléfono.'**
  String get capturePermissionFactDataDescription;

  /// No description provided for @capturePermissionFactConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada se registra sin ti'**
  String get capturePermissionFactConfirmTitle;

  /// No description provided for @capturePermissionFactConfirmDescription.
  ///
  /// In es, this message translates to:
  /// **'Cada compra detectada espera tu confirmación antes de tocar tus saldos.'**
  String get capturePermissionFactConfirmDescription;

  /// No description provided for @capturePermissionFactSyncTitle.
  ///
  /// In es, this message translates to:
  /// **'Se respalda como un movimiento más'**
  String get capturePermissionFactSyncTitle;

  /// No description provided for @capturePermissionFactSyncDescription.
  ///
  /// In es, this message translates to:
  /// **'Esos tres datos viajan a tu cuenta igual que un movimiento que escribes a mano.'**
  String get capturePermissionFactSyncDescription;

  /// No description provided for @capturePermissionSystemWarning.
  ///
  /// In es, this message translates to:
  /// **'Android te va a advertir que la app podrá ver todas tus notificaciones. Es la única forma en que el sistema concede este permiso; la app solo lee las apps que tú actives.'**
  String get capturePermissionSystemWarning;

  /// No description provided for @capturePermissionOpenSettingsCta.
  ///
  /// In es, this message translates to:
  /// **'Ir a Ajustes de Android'**
  String get capturePermissionOpenSettingsCta;

  /// No description provided for @capturePermissionDeclineCta.
  ///
  /// In es, this message translates to:
  /// **'Ahora no, gracias'**
  String get capturePermissionDeclineCta;

  /// No description provided for @captureSeeHowItWorksCta.
  ///
  /// In es, this message translates to:
  /// **'Ver cómo funciona'**
  String get captureSeeHowItWorksCta;

  /// No description provided for @captureDisabledTitle.
  ///
  /// In es, this message translates to:
  /// **'La lectura de avisos está desactivada'**
  String get captureDisabledTitle;

  /// No description provided for @captureDisabledBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes activarla cuando quieras. Mientras tanto todo sigue igual: registras tus movimientos como siempre y tus saldos no cambian.'**
  String get captureDisabledBody;

  /// No description provided for @captureDisabledPendingNote.
  ///
  /// In es, this message translates to:
  /// **'Las capturas que ya tenías siguen en tu bandeja. Puedes revisarlas aunque esto esté apagado.'**
  String get captureDisabledPendingNote;

  /// No description provided for @captureDisabledOpenSettingsCta.
  ///
  /// In es, this message translates to:
  /// **'Activar en Ajustes de Android'**
  String get captureDisabledOpenSettingsCta;

  /// No description provided for @captureIssuersHeader.
  ///
  /// In es, this message translates to:
  /// **'Apps que se leen'**
  String get captureIssuersHeader;

  /// No description provided for @captureIssuersScopeNote.
  ///
  /// In es, this message translates to:
  /// **'Solo se leen los avisos de las apps que enciendas aquí. Las demás no se abren nunca.'**
  String get captureIssuersScopeNote;

  /// No description provided for @captureIssuersNoneActive.
  ///
  /// In es, this message translates to:
  /// **'Ninguna activa todavía'**
  String get captureIssuersNoneActive;

  /// No description provided for @captureIssuersTurnOffAll.
  ///
  /// In es, this message translates to:
  /// **'Apagar todas'**
  String get captureIssuersTurnOffAll;

  /// No description provided for @captureIssuersClosedCatalogNote.
  ///
  /// In es, this message translates to:
  /// **'¿No ves tu banco? Por ahora solo leemos avisos de estas apps. El catálogo irá creciendo.'**
  String get captureIssuersClosedCatalogNote;

  /// No description provided for @captureIssuersNoAppsTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes ninguna de estas apps'**
  String get captureIssuersNoAppsTitle;

  /// No description provided for @captureIssuersNoAppsDescription.
  ///
  /// In es, this message translates to:
  /// **'Por ahora leemos avisos de Nu, Nequi y Google Wallet. Cuando instales alguna, aparecerá aquí para que la enciendas.'**
  String get captureIssuersNoAppsDescription;

  /// No description provided for @captureIssuersErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus apps'**
  String get captureIssuersErrorTitle;

  /// No description provided for @captureIssuerNuDescription.
  ///
  /// In es, this message translates to:
  /// **'Compras con tu tarjeta Nu'**
  String get captureIssuerNuDescription;

  /// No description provided for @captureIssuerNequiDescription.
  ///
  /// In es, this message translates to:
  /// **'Compras, envíos y recargas'**
  String get captureIssuerNequiDescription;

  /// No description provided for @captureIssuerGoogleWalletDescription.
  ///
  /// In es, this message translates to:
  /// **'Pagos con el celular (NFC)'**
  String get captureIssuerGoogleWalletDescription;

  /// No description provided for @captureIssuerGenericDescription.
  ///
  /// In es, this message translates to:
  /// **'Avisos de compra de esta app'**
  String get captureIssuerGenericDescription;

  /// No description provided for @captureOfferMessage.
  ///
  /// In es, this message translates to:
  /// **'Cuando tu banco te avise de una compra, te la dejo lista para confirmar: monto, comercio y fecha ya puestos.'**
  String get captureOfferMessage;

  /// No description provided for @captureOfferScopeNote.
  ///
  /// In es, this message translates to:
  /// **'No alcanza para todo: el efectivo no avisa y hay bancos que aún no están en la lista. Esto se suma a registrar a mano, no lo reemplaza.'**
  String get captureOfferScopeNote;

  /// No description provided for @captureOfferDismissCta.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get captureOfferDismissCta;

  /// No description provided for @captureSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Avisos de tu banco'**
  String get captureSettingsTitle;

  /// No description provided for @captureSettingsSubtitleChecking.
  ///
  /// In es, this message translates to:
  /// **'Revisando el estado…'**
  String get captureSettingsSubtitleChecking;

  /// No description provided for @captureSettingsSubtitleOff.
  ///
  /// In es, this message translates to:
  /// **'Desactivado · actívalo cuando quieras'**
  String get captureSettingsSubtitleOff;

  /// No description provided for @captureSettingsSubtitleNoIssuers.
  ///
  /// In es, this message translates to:
  /// **'Activo, pero sin apps elegidas todavía'**
  String get captureSettingsSubtitleNoIssuers;

  /// No description provided for @captureIssuersActiveCount.
  ///
  /// In es, this message translates to:
  /// **'{count} de {total} activas'**
  String captureIssuersActiveCount(int count, int total);

  /// No description provided for @captureSettingsSubtitleListening.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Escuchando 1 app} other{Escuchando {count} apps}}'**
  String captureSettingsSubtitleListening(int count);

  /// No description provided for @captureBlockReviewAction.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Revisar 1 captura} other{Revisar las {count} capturas}}'**
  String captureBlockReviewAction(int count);

  /// No description provided for @captureDuplicateVerdictSameAmount.
  ///
  /// In es, this message translates to:
  /// **'Mismo monto'**
  String get captureDuplicateVerdictSameAmount;

  /// No description provided for @captureDuplicateVerdictMinutesBefore.
  ///
  /// In es, this message translates to:
  /// **'{minutes, plural, =0{Menos de 1 minuto antes} =1{1 minuto antes} other{{minutes} minutos antes}}'**
  String captureDuplicateVerdictMinutesBefore(int minutes);

  /// No description provided for @captureDuplicateVerdictMinutesAfter.
  ///
  /// In es, this message translates to:
  /// **'{minutes, plural, =0{Menos de 1 minuto después} =1{1 minuto después} other{{minutes} minutos después}}'**
  String captureDuplicateVerdictMinutesAfter(int minutes);

  /// No description provided for @captureDuplicateVerdictSameAccount.
  ///
  /// In es, this message translates to:
  /// **'misma cuenta'**
  String get captureDuplicateVerdictSameAccount;

  /// No description provided for @captureDuplicateExistingKicker.
  ///
  /// In es, this message translates to:
  /// **'Ya registrado'**
  String get captureDuplicateExistingKicker;

  /// No description provided for @captureDuplicateNoCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get captureDuplicateNoCategory;

  /// No description provided for @captureDuplicateConsequenceCaption.
  ///
  /// In es, this message translates to:
  /// **'Si descartas, puedes deshacerlo · Revisar no guarda nada'**
  String get captureDuplicateConsequenceCaption;

  /// No description provided for @captureGroupedSourceLabel.
  ///
  /// In es, this message translates to:
  /// **'Un solo pago · {wallet} + {bank}'**
  String captureGroupedSourceLabel(String wallet, String bank);

  /// No description provided for @captureIssuerUnknown.
  ///
  /// In es, this message translates to:
  /// **'otra app'**
  String get captureIssuerUnknown;

  /// No description provided for @captureSuggestedCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Sugerida: {category}'**
  String captureSuggestedCategoryLabel(String category);

  /// No description provided for @captureVoiceListening.
  ///
  /// In es, this message translates to:
  /// **'Escuchando…'**
  String get captureVoiceListening;

  /// No description provided for @captureVoicePreparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando el micrófono…'**
  String get captureVoicePreparing;

  /// No description provided for @captureVoiceHint.
  ///
  /// In es, this message translates to:
  /// **'Di algo como «gasté veinte mil en almuerzo»'**
  String get captureVoiceHint;

  /// No description provided for @captureVoicePrivacyCaption.
  ///
  /// In es, this message translates to:
  /// **'El audio no se guarda. Solo se usa para llenar el formulario.'**
  String get captureVoicePrivacyCaption;

  /// No description provided for @captureVoicePartialCaption.
  ///
  /// In es, this message translates to:
  /// **'Al terminar abrimos el formulario con lo que se entendió. Tú confirmas.'**
  String get captureVoicePartialCaption;

  /// No description provided for @captureVoiceCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get captureVoiceCancel;

  /// No description provided for @captureVoiceDone.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get captureVoiceDone;

  /// No description provided for @captureVoiceSoundLevelLabel.
  ///
  /// In es, this message translates to:
  /// **'Nivel del micrófono'**
  String get captureVoiceSoundLevelLabel;

  /// No description provided for @captureVoiceNoAmountTitle.
  ///
  /// In es, this message translates to:
  /// **'No alcanzamos a captar el monto'**
  String get captureVoiceNoAmountTitle;

  /// No description provided for @captureVoiceNoAmountMessage.
  ///
  /// In es, this message translates to:
  /// **'Lo que dijiste no se pierde: se va como nota al formulario.'**
  String get captureVoiceNoAmountMessage;

  /// No description provided for @captureVoiceRetry.
  ///
  /// In es, this message translates to:
  /// **'Intentar de nuevo'**
  String get captureVoiceRetry;

  /// No description provided for @captureVoiceWriteByHand.
  ///
  /// In es, this message translates to:
  /// **'Escribir a mano'**
  String get captureVoiceWriteByHand;

  /// No description provided for @captureVoicePermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'El micrófono está desactivado'**
  String get captureVoicePermissionTitle;

  /// No description provided for @captureVoicePermissionMessage.
  ///
  /// In es, this message translates to:
  /// **'Lo usamos solo mientras dictas, para llenar el formulario por ti. El audio no se guarda.'**
  String get captureVoicePermissionMessage;

  /// No description provided for @captureVoicePermissionFact1Title.
  ///
  /// In es, this message translates to:
  /// **'Solo mientras dictas'**
  String get captureVoicePermissionFact1Title;

  /// No description provided for @captureVoicePermissionFact1Body.
  ///
  /// In es, this message translates to:
  /// **'El micrófono se apaga en cuanto terminas la frase o cancelas.'**
  String get captureVoicePermissionFact1Body;

  /// No description provided for @captureVoicePermissionFact2Title.
  ///
  /// In es, this message translates to:
  /// **'El audio no se guarda'**
  String get captureVoicePermissionFact2Title;

  /// No description provided for @captureVoicePermissionFact2Body.
  ///
  /// In es, this message translates to:
  /// **'Se usa para entender la frase y se descarta al terminar. No se respalda ni se sincroniza.'**
  String get captureVoicePermissionFact2Body;

  /// No description provided for @captureVoicePermissionFact3Title.
  ///
  /// In es, this message translates to:
  /// **'Puedes seguir sin él'**
  String get captureVoicePermissionFact3Title;

  /// No description provided for @captureVoicePermissionFact3Body.
  ///
  /// In es, this message translates to:
  /// **'Escribir un movimiento a mano funciona igual que siempre, con o sin micrófono.'**
  String get captureVoicePermissionFact3Body;

  /// No description provided for @captureVoicePermissionOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get captureVoicePermissionOpenSettings;

  /// No description provided for @captureVoicePermissionAllow.
  ///
  /// In es, this message translates to:
  /// **'Activar el micrófono'**
  String get captureVoicePermissionAllow;

  /// No description provided for @captureVoiceUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'El dictado no está disponible aquí'**
  String get captureVoiceUnavailableTitle;

  /// No description provided for @captureVoiceUnavailableMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu teléfono no puede transcribir en el idioma de la app ahora mismo. Escribir a mano funciona igual que siempre.'**
  String get captureVoiceUnavailableMessage;

  /// No description provided for @captureVoiceOnDeviceUnavailableMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu teléfono no puede transcribir sin enviar el audio a internet, y no lo hacemos sin preguntarte antes. Escribir a mano funciona igual que siempre.'**
  String get captureVoiceOnDeviceUnavailableMessage;

  /// No description provided for @captureVoiceNoConnectionMessage.
  ///
  /// In es, this message translates to:
  /// **'El dictado necesita conexión en este teléfono y ahora no la hay. Escribir a mano funciona igual que siempre.'**
  String get captureVoiceNoConnectionMessage;

  /// No description provided for @captureVoiceBusyMessage.
  ///
  /// In es, this message translates to:
  /// **'Otra app está usando el micrófono. Cuando la cierres puedes volver a dictar.'**
  String get captureVoiceBusyMessage;

  /// No description provided for @captureVoiceDictate.
  ///
  /// In es, this message translates to:
  /// **'Dictar'**
  String get captureVoiceDictate;

  /// No description provided for @captureVoiceDictateTooltip.
  ///
  /// In es, this message translates to:
  /// **'Dictar el movimiento'**
  String get captureVoiceDictateTooltip;

  /// No description provided for @captureVoiceFabLongPressHint.
  ///
  /// In es, this message translates to:
  /// **'Mantén presionado para dictar'**
  String get captureVoiceFabLongPressHint;

  /// Nombre del servicio que transcribe la voz en Android.
  ///
  /// In es, this message translates to:
  /// **'Google'**
  String get captureVoiceVendorGoogle;

  /// Nombre del servicio que transcribe la voz en iOS.
  ///
  /// In es, this message translates to:
  /// **'Apple'**
  String get captureVoiceVendorApple;

  /// No description provided for @captureVoiceCloudConsentTitle.
  ///
  /// In es, this message translates to:
  /// **'Para dictar, {vendor} transcribe tu voz'**
  String captureVoiceCloudConsentTitle(String vendor);

  /// No description provided for @captureVoiceCloudConsentMessage.
  ///
  /// In es, this message translates to:
  /// **'Este teléfono no puede convertir la voz en texto por su cuenta. Si lo permites, el audio se envía a {vendor} solo para transcribirlo.'**
  String captureVoiceCloudConsentMessage(String vendor);

  /// No description provided for @captureVoiceCloudConsentFact1Title.
  ///
  /// In es, this message translates to:
  /// **'El audio sale del teléfono'**
  String get captureVoiceCloudConsentFact1Title;

  /// No description provided for @captureVoiceCloudConsentFact1Body.
  ///
  /// In es, this message translates to:
  /// **'{vendor} recibe lo que dictas y devuelve el texto. Ese es el paso que este teléfono no puede hacer solo.'**
  String captureVoiceCloudConsentFact1Body(String vendor);

  /// No description provided for @captureVoiceCloudConsentFact2Title.
  ///
  /// In es, this message translates to:
  /// **'billetudo no guarda nada'**
  String get captureVoiceCloudConsentFact2Title;

  /// No description provided for @captureVoiceCloudConsentFact2Body.
  ///
  /// In es, this message translates to:
  /// **'Ni el audio ni la transcripción se guardan, respaldan o sincronizan.'**
  String get captureVoiceCloudConsentFact2Body;

  /// No description provided for @captureVoiceCloudConsentFact3Title.
  ///
  /// In es, this message translates to:
  /// **'Tú confirmas antes de guardar'**
  String get captureVoiceCloudConsentFact3Title;

  /// No description provided for @captureVoiceCloudConsentFact3Body.
  ///
  /// In es, this message translates to:
  /// **'Lo dictado solo llena el formulario. Nada se registra hasta que lo revises.'**
  String get captureVoiceCloudConsentFact3Body;

  /// No description provided for @captureVoiceCloudConsentAllow.
  ///
  /// In es, this message translates to:
  /// **'Permitir y dictar'**
  String get captureVoiceCloudConsentAllow;

  /// No description provided for @captureVoiceCloudConsentReversible.
  ///
  /// In es, this message translates to:
  /// **'Puedes cambiar esta decisión cuando quieras en Ajustes.'**
  String get captureVoiceCloudConsentReversible;

  /// No description provided for @captureVoiceCloudConsentDeclinedMessage.
  ///
  /// In es, this message translates to:
  /// **'Elegiste que tu voz no se transcriba en la nube, y lo respetamos. Puedes cambiarlo en Ajustes. Escribir a mano funciona igual que siempre.'**
  String get captureVoiceCloudConsentDeclinedMessage;

  /// Pastilla bajo el monto cuando el parser infirió la magnitud de lo dictado.
  ///
  /// In es, this message translates to:
  /// **'Supusimos {amount} por «{spoken}»'**
  String captureVoiceAmountAssumption(String amount, String spoken);

  /// No description provided for @tutorialVoiceCaptureTitle.
  ///
  /// In es, this message translates to:
  /// **'Dicta un gasto sin teclear'**
  String get tutorialVoiceCaptureTitle;

  /// No description provided for @tutorialVoiceCapturePoint1Heading.
  ///
  /// In es, this message translates to:
  /// **'Mantén presionado el botón +'**
  String get tutorialVoiceCapturePoint1Heading;

  /// No description provided for @tutorialVoiceCapturePoint1Body.
  ///
  /// In es, this message translates to:
  /// **'En Inicio, deja el dedo un segundo sobre el botón + y empieza a hablar.'**
  String get tutorialVoiceCapturePoint1Body;

  /// No description provided for @tutorialVoiceCapturePoint2Heading.
  ///
  /// In es, this message translates to:
  /// **'Di la frase de corrido'**
  String get tutorialVoiceCapturePoint2Heading;

  /// No description provided for @tutorialVoiceCapturePoint2Body.
  ///
  /// In es, this message translates to:
  /// **'«Gasté veinte mil en almuerzo con Nequi». De ahí salen el monto, la categoría y la cuenta.'**
  String get tutorialVoiceCapturePoint2Body;

  /// No description provided for @tutorialVoiceCapturePoint3Heading.
  ///
  /// In es, this message translates to:
  /// **'Tú confirmas siempre'**
  String get tutorialVoiceCapturePoint3Heading;

  /// No description provided for @tutorialVoiceCapturePoint3Body.
  ///
  /// In es, this message translates to:
  /// **'La app llena el formulario con lo que entendió. Nada queda registrado hasta que tocas guardar.'**
  String get tutorialVoiceCapturePoint3Body;

  /// No description provided for @tutorialVoiceCaptureCta.
  ///
  /// In es, this message translates to:
  /// **'Probar ahora'**
  String get tutorialVoiceCaptureCta;

  /// No description provided for @notificationsChannelRemindersName.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de pagos'**
  String get notificationsChannelRemindersName;

  /// No description provided for @notificationsChannelRemindersDescription.
  ///
  /// In es, this message translates to:
  /// **'Avisos de los pagos programados que tú configuraste.'**
  String get notificationsChannelRemindersDescription;

  /// No description provided for @notificationsChannelCapturesName.
  ///
  /// In es, this message translates to:
  /// **'Registro de movimientos'**
  String get notificationsChannelCapturesName;

  /// No description provided for @notificationsChannelCapturesDescription.
  ///
  /// In es, this message translates to:
  /// **'Avisos para registrar un movimiento cuando lo pediste.'**
  String get notificationsChannelCapturesDescription;

  /// No description provided for @notificationsChannelMilestonesName.
  ///
  /// In es, this message translates to:
  /// **'Logros de tus metas'**
  String get notificationsChannelMilestonesName;

  /// No description provided for @notificationsChannelMilestonesDescription.
  ///
  /// In es, this message translates to:
  /// **'Avisos cuando una de tus metas llega a un hito.'**
  String get notificationsChannelMilestonesDescription;

  /// No description provided for @remindersNotificationBodyToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy se paga {amount} desde {account}'**
  String remindersNotificationBodyToday(String amount, String account);

  /// No description provided for @remindersNotificationBodyTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana se paga {amount} desde {account}'**
  String remindersNotificationBodyTomorrow(String amount, String account);

  /// No description provided for @remindersNotificationBodyInDays.
  ///
  /// In es, this message translates to:
  /// **'En {days} días se paga {amount} desde {account}'**
  String remindersNotificationBodyInDays(
      int days, String amount, String account);

  /// No description provided for @remindersFieldSectionLabel.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get remindersFieldSectionLabel;

  /// No description provided for @remindersOptionNone.
  ///
  /// In es, this message translates to:
  /// **'Sin recordatorio'**
  String get remindersOptionNone;

  /// No description provided for @remindersSheetCaption.
  ///
  /// In es, this message translates to:
  /// **'Te mandamos una notificación antes de que llegue la fecha.'**
  String get remindersSheetCaption;

  /// No description provided for @remindersOptionOnDueDate.
  ///
  /// In es, this message translates to:
  /// **'El día del pago'**
  String get remindersOptionOnDueDate;

  /// No description provided for @remindersOptionOneDayBefore.
  ///
  /// In es, this message translates to:
  /// **'1 día antes'**
  String get remindersOptionOneDayBefore;

  /// No description provided for @remindersOptionThreeDaysBefore.
  ///
  /// In es, this message translates to:
  /// **'3 días antes'**
  String get remindersOptionThreeDaysBefore;

  /// No description provided for @remindersOptionOneWeekBefore.
  ///
  /// In es, this message translates to:
  /// **'Una semana antes'**
  String get remindersOptionOneWeekBefore;

  /// No description provided for @remindersPermissionNotice.
  ///
  /// In es, this message translates to:
  /// **'Guardamos tu preferencia. Para que el aviso llegue, activa las notificaciones de Billetudo en los ajustes de tu teléfono.'**
  String get remindersPermissionNotice;

  /// No description provided for @remindersChipOnDueDate.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos el día del pago'**
  String get remindersChipOnDueDate;

  /// No description provided for @remindersChipOneDayBefore.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos 1 día antes'**
  String get remindersChipOneDayBefore;

  /// No description provided for @remindersChipDaysBefore.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos {days} días antes'**
  String remindersChipDaysBefore(int days);

  /// No description provided for @remindersChipOneWeekBefore.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos una semana antes'**
  String get remindersChipOneWeekBefore;

  /// No description provided for @notificationsSettingsPaymentReminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de pago'**
  String get notificationsSettingsPaymentReminders;

  /// No description provided for @notificationsSettingsPaymentRemindersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te avisamos antes de la fecha de un pago programado, con la anticipación que elegiste en cada uno.'**
  String get notificationsSettingsPaymentRemindersSubtitle;

  /// No description provided for @notificationsSettingsUpcomingCharges.
  ///
  /// In es, this message translates to:
  /// **'Cobros próximos'**
  String get notificationsSettingsUpcomingCharges;

  /// No description provided for @notificationsSettingsUpcomingChargesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un aviso cuando se acerca un pago que ya tienes programado.'**
  String get notificationsSettingsUpcomingChargesSubtitle;

  /// No description provided for @notificationsSettingsPendingConfirmations.
  ///
  /// In es, this message translates to:
  /// **'Pagos por confirmar'**
  String get notificationsSettingsPendingConfirmations;

  /// No description provided for @notificationsSettingsPendingConfirmationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuando un pago manual quedó esperando tu confirmación.'**
  String get notificationsSettingsPendingConfirmationsSubtitle;

  /// No description provided for @notificationsSettingsGoalMilestones.
  ///
  /// In es, this message translates to:
  /// **'Hitos de metas'**
  String get notificationsSettingsGoalMilestones;

  /// No description provided for @notificationsSettingsGoalMilestonesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuando llegas a la mitad de una meta y cuando la completas.'**
  String get notificationsSettingsGoalMilestonesSubtitle;

  /// No description provided for @insightGoalMilestoneTitle.
  ///
  /// In es, this message translates to:
  /// **'{name} va en {percent}%'**
  String insightGoalMilestoneTitle(String name, int percent);

  /// No description provided for @insightGoalCompletedTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Llegaste a tu meta {name}!'**
  String insightGoalCompletedTitle(String name);

  /// No description provided for @insightGoalMilestoneBody.
  ///
  /// In es, this message translates to:
  /// **'Llevas {amount} de {target}'**
  String insightGoalMilestoneBody(String amount, String target);

  /// No description provided for @settingsNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de pago, cobros próximos y metas'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @notificationsSettingsIntro.
  ///
  /// In es, this message translates to:
  /// **'Tú eliges qué te avisamos. Lo que apagues aquí deja de llegar y puedes volver a encenderlo cuando quieras.'**
  String get notificationsSettingsIntro;

  /// No description provided for @notificationsSettingsDeniedIntro.
  ///
  /// In es, this message translates to:
  /// **'Cuando vuelvas a permitir las notificaciones, estos ajustes quedan como los tenías. No se pierde nada.'**
  String get notificationsSettingsDeniedIntro;

  /// No description provided for @notificationsPermissionDeniedTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu teléfono tiene las notificaciones apagadas'**
  String get notificationsPermissionDeniedTitle;

  /// No description provided for @notificationsPermissionDeniedBody.
  ///
  /// In es, this message translates to:
  /// **'Mientras el permiso esté apagado no te llega ningún aviso, aunque aquí los dejes encendidos. Se activa desde los ajustes del teléfono.'**
  String get notificationsPermissionDeniedBody;

  /// No description provided for @notificationsPermissionDeniedCta.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes del teléfono'**
  String get notificationsPermissionDeniedCta;

  /// No description provided for @insightUpcomingChargeTitleToday.
  ///
  /// In es, this message translates to:
  /// **'{name} se cobra hoy'**
  String insightUpcomingChargeTitleToday(Object name);

  /// No description provided for @insightUpcomingChargeTitleTomorrow.
  ///
  /// In es, this message translates to:
  /// **'{name} se cobra mañana'**
  String insightUpcomingChargeTitleTomorrow(Object name);

  /// No description provided for @insightUpcomingChargeTitleInDays.
  ///
  /// In es, this message translates to:
  /// **'{name} se cobra en {days} días'**
  String insightUpcomingChargeTitleInDays(Object days, Object name);

  /// No description provided for @insightUpcomingChargeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{amount} · Pago programado'**
  String insightUpcomingChargeSubtitle(Object amount);

  /// No description provided for @insightPendingConfirmationTitleToday.
  ///
  /// In es, this message translates to:
  /// **'{name} estaba programado para hoy'**
  String insightPendingConfirmationTitleToday(Object name);

  /// No description provided for @insightPendingConfirmationTitleYesterday.
  ///
  /// In es, this message translates to:
  /// **'{name} estaba programado para ayer'**
  String insightPendingConfirmationTitleYesterday(Object name);

  /// No description provided for @insightPendingConfirmationTitleDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'{name} estaba programado hace {days} días'**
  String insightPendingConfirmationTitleDaysAgo(Object days, Object name);

  /// No description provided for @insightPendingConfirmationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'{amount} · Espera tu confirmación'**
  String insightPendingConfirmationSubtitle(Object amount);

  /// No description provided for @insightActionViewPayment.
  ///
  /// In es, this message translates to:
  /// **'Ver pago'**
  String get insightActionViewPayment;

  /// No description provided for @insightActionRemindLater.
  ///
  /// In es, this message translates to:
  /// **'Recordar después'**
  String get insightActionRemindLater;

  /// No description provided for @insightActionConfirmPayment.
  ///
  /// In es, this message translates to:
  /// **'Confirmar pago'**
  String get insightActionConfirmPayment;

  /// No description provided for @insightActionNotYet.
  ///
  /// In es, this message translates to:
  /// **'Todavía no'**
  String get insightActionNotYet;

  /// No description provided for @insightActionViewGoal.
  ///
  /// In es, this message translates to:
  /// **'Ver meta'**
  String get insightActionViewGoal;
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
