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
  String get commonBack => 'Atrás';

  @override
  String get errorUnexpected => 'Algo salió mal. Intenta de nuevo.';

  @override
  String get errorDatabase =>
      'No pudimos guardar los cambios. Intenta de nuevo.';

  @override
  String get errorSecureStorage =>
      'No pudimos acceder al almacenamiento seguro del dispositivo.';

  @override
  String get accountsTitle => 'Cuentas';

  @override
  String get accountsOpenAction => 'Ver mis cuentas';

  @override
  String get accountsAdd => 'Agregar cuenta';

  @override
  String get accountsTotalLabel => 'Patrimonio total';

  @override
  String accountsTotalDebtsLine(String amount) {
    return 'Deudas: -$amount';
  }

  @override
  String get accountsEmptyMessage => 'Aún no has agregado ninguna cuenta';

  @override
  String get accountsErrorTitle => 'No pudimos cargar tus cuentas';

  @override
  String get accountsErrorLocalFirst =>
      'Tus datos siguen guardados en tu dispositivo';

  @override
  String get accountsArchivedTitle => 'Cuentas archivadas';

  @override
  String get accountsArchivedEmptyMessage =>
      'Aún no has archivado ninguna cuenta';

  @override
  String get accountsUnarchive => 'Desarchivar';

  @override
  String get accountsLoading => 'Cargando tus cuentas';

  @override
  String get accountTypeCash => 'Efectivo';

  @override
  String get accountTypeBank => 'Banco';

  @override
  String get accountTypeCard => 'Tarjeta de crédito';

  @override
  String get accountTypeSavings => 'Ahorros';

  @override
  String get accountTypeInvestment => 'Inversión';

  @override
  String get accountTypeOther => 'Otra';

  @override
  String get accountBalanceLabel => 'Saldo actual';

  @override
  String get accountAvailableCreditLabel => 'Cupo disponible';

  @override
  String get accountDebtLabel => 'Deuda actual';

  @override
  String get accountOverLimitBadge => 'Sobrecupo';

  @override
  String accountOverLimitCaption(String amount) {
    return 'Excedido en $amount';
  }

  @override
  String accountCreditUsedCaption(String used, String limit) {
    return '$used de $limit usado';
  }

  @override
  String accountBalancePage(int index, int total) {
    return 'Página $index de $total';
  }

  @override
  String get accountInfoInstitution => 'Institución';

  @override
  String get accountInfoType => 'Tipo';

  @override
  String get accountInfoInterestRate => 'Tasa de interés';

  @override
  String get accountInfoNumber => 'Número de cuenta';

  @override
  String get accountInfoStatementDay => 'Día de corte';

  @override
  String get accountInfoPaymentDueDay => 'Día de pago';

  @override
  String accountInterestRateValue(String rate) {
    return '$rate%';
  }

  @override
  String accountDayOfMonthValue(int day) {
    return '$day de cada mes';
  }

  @override
  String accountNumberMasked(String last4) {
    return '•••• $last4';
  }

  @override
  String get accountNumberReveal => 'Mostrar número';

  @override
  String get accountNumberHide => 'Ocultar número';

  @override
  String get accountNumberCopy => 'Copiar número';

  @override
  String get accountNumberCopied =>
      'Número copiado. Se borra del portapapeles en un minuto.';

  @override
  String get accountArchiveAction => 'Archivar';

  @override
  String get accountDeleteAction => 'Eliminar cuenta';

  @override
  String get accountFormNewTitle => 'Nueva cuenta';

  @override
  String get accountFormEditTitle => 'Editar cuenta';

  @override
  String get accountFormTypeLabel => 'Tipo de cuenta';

  @override
  String get accountFormTypeChange => 'Cambiar';

  @override
  String get accountFormNameLabel => 'Nombre';

  @override
  String get accountFormNameHint => 'Ej. Cuenta de ahorros';

  @override
  String get accountFormInstitutionLabel => 'Institución';

  @override
  String get accountFormInstitutionHint => 'Ej. Bancolombia';

  @override
  String get accountFormInitialBalanceLabel => 'Saldo inicial';

  @override
  String get accountFormCurrencyLabel => 'Moneda';

  @override
  String get accountFormInterestRateLabel => 'Tasa de interés';

  @override
  String get accountFormInterestRateHint => 'Ej. 24,5';

  @override
  String get accountFormNumberLabel => 'Número de cuenta';

  @override
  String get accountFormNumberHint => 'Opcional';

  @override
  String get accountFormNumberHelp =>
      'Se guarda solo en este dispositivo, nunca en la nube.';

  @override
  String get accountFormNumberReadError =>
      'No pudimos leer el número guardado en este dispositivo. Lo dejamos tal cual está: si quieres cambiarlo, escríbelo de nuevo.';

  @override
  String get accountFormLast4Label => 'Últimos 4 dígitos';

  @override
  String get accountFormLast4Hint => 'Ej. 4321';

  @override
  String get accountFormCardSectionTitle => 'Datos de la tarjeta';

  @override
  String get accountFormCreditLimitLabel => 'Cupo máximo';

  @override
  String get accountFormStatementDayLabel => 'Día de corte';

  @override
  String get accountFormPaymentDueDayLabel => 'Día de pago';

  @override
  String get accountFormAmountHint => '0';

  @override
  String get accountFormSelectHint => 'Seleccionar';

  @override
  String get accountErrorType => 'Elige el tipo de cuenta.';

  @override
  String get accountErrorName => 'Escribe un nombre de hasta 100 caracteres.';

  @override
  String get accountErrorCurrency => 'Elige una moneda.';

  @override
  String get accountErrorInstitution =>
      'La institución admite hasta 100 caracteres.';

  @override
  String get accountErrorFullNumber =>
      'Revisa el número de cuenta: solo dígitos.';

  @override
  String get accountErrorLast4 => 'Ingresa hasta 4 dígitos.';

  @override
  String get accountErrorInterestRate =>
      'Ingresa una tasa válida, por ejemplo 24,5.';

  @override
  String get accountErrorInitialBalance => 'Ingresa un saldo válido.';

  @override
  String get accountErrorCreditLimit => 'Ingresa el cupo de la tarjeta.';

  @override
  String get accountErrorStatementDay => 'Elige un día entre 1 y 31.';

  @override
  String get accountErrorPaymentDueDay => 'Elige un día entre 1 y 31.';

  @override
  String get accountDeleteSheetTitle => '¿Eliminar esta cuenta?';

  @override
  String get accountDeleteSheetMessage =>
      'La cuenta dejará de aparecer en tus listas.';

  @override
  String accountDeleteSheetImpact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tiene $count movimientos asociados.',
      one: 'Tiene 1 movimiento asociado.',
    );
    return '$_temp0';
  }

  @override
  String get accountArchiveSheetTitle => '¿Archivar esta cuenta?';

  @override
  String get accountArchiveSheetMessage =>
      'Podrás recuperarla cuando quieras desde “Cuentas archivadas”.';

  @override
  String get accountChangeSheetTitle => '¿Confirmas el cambio?';

  @override
  String get accountChangeSheetMessage =>
      'Esta cuenta ya tiene movimientos. Cambiar su tipo o su moneda cambia cómo se leen sus cifras.';

  @override
  String get accountChangeConfirm => 'Confirmar';

  @override
  String get accountCurrencySheetTitle => 'Moneda';

  @override
  String get currencyCopName => 'Peso colombiano';

  @override
  String get currencyUsdName => 'Dólar estadounidense';

  @override
  String get accountCannotDeleteTitle => 'No se puede eliminar';

  @override
  String get accountCannotDeleteMessage =>
      'Necesitas al menos una cuenta para registrar tus movimientos. Crea otra y luego podrás eliminar esta.';

  @override
  String get accountCannotDeleteUnderstood => 'Entendido';

  @override
  String get categoriesTitle => 'Categorías';

  @override
  String get categoriesOpenAction => 'Ver mis categorías';

  @override
  String get categoriesAdd => 'Crear categoría';

  @override
  String get categoriesErrorTitle => 'No pudimos cargar tus categorías';

  @override
  String get categoriesEmptyExpense => 'Aún no tienes categorías de gasto';

  @override
  String get categoriesEmptyIncome => 'Aún no tienes categorías de ingreso';

  @override
  String get categoriesLoading => 'Cargando tus categorías';

  @override
  String categorySubcategoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subcategorías',
      one: '1 subcategoría',
      zero: 'Sin subcategorías',
    );
    return '$_temp0';
  }

  @override
  String get categoryAddSubcategory => 'Agregar subcategoría';

  @override
  String get categoryKindExpense => 'Gasto';

  @override
  String get categoryKindIncome => 'Ingreso';

  @override
  String get categoryFormNewTitle => 'Nueva categoría';

  @override
  String get categoryFormNewSubcategoryTitle => 'Nueva subcategoría';

  @override
  String get categoryFormEditTitle => 'Editar categoría';

  @override
  String get categoryFormEditSubcategoryTitle => 'Editar subcategoría';

  @override
  String get categoryFormAppearanceLabel => 'Icono y color';

  @override
  String get categoryFormAppearanceEmptySublabel =>
      'Toca para elegir (opcional)';

  @override
  String get categoryFormAppearanceFilledSublabel => 'Toca para cambiar';

  @override
  String get categoryFormNameLabel => 'Nombre';

  @override
  String get categoryFormNameHint => 'Ej. Comida y bebida';

  @override
  String get categoryFormKindLabel => 'Tipo';

  @override
  String get categoryFormParentLabel => 'Categoría padre';

  @override
  String get categoryErrorName => 'Escribe un nombre de hasta 100 caracteres.';

  @override
  String get categoryKindLockedSubcategory =>
      'Hereda el tipo de la categoría padre — no se puede cambiar en subcategorías.';

  @override
  String get categoryKindLockedRoot =>
      'No se puede cambiar el tipo porque tiene subcategorías activas. Elimina o reasigna las subcategorías primero.';

  @override
  String get categoryDeleteAction => 'Eliminar categoría';

  @override
  String get categoryAppearancePickerTitle => 'Icono y color';

  @override
  String get categoryParentPickerTitle => 'Categoría padre';

  @override
  String get categoryParentPickerEmpty =>
      'No hay categorías disponibles todavía.';

  @override
  String get categoryDeleteSimpleTitle => '¿Eliminar esta categoría?';

  @override
  String get categoryDeleteSimpleMessage =>
      'Podrás recuperarla después desde la papelera.';

  @override
  String get categoryDeleteTransactionsTitle => '¿Eliminar esta categoría?';

  @override
  String categoryDeleteTransactionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tiene $count movimientos asociados.',
      one: 'Tiene 1 movimiento asociado.',
    );
    return '$_temp0';
  }

  @override
  String get categoryDeleteReassignOption => 'Reasignar a otra categoría';

  @override
  String get categoryDeleteClearOption => 'Dejar sin categoría';

  @override
  String get categoryReassignTransactionsPickerTitle =>
      'Reasignar a otra categoría';

  @override
  String get categoryDeleteSubcategoriesTitle =>
      'Esta categoría tiene subcategorías';

  @override
  String get categoryDeleteSubcategoriesMessage =>
      'Antes de eliminarla, decide qué pasa con sus subcategorías.';

  @override
  String get categoryReassignSubcategoriesOption => 'Reasignar subcategorías';

  @override
  String get categoryReassignSubcategoriesPickerTitle =>
      'Mover subcategorías a';

  @override
  String get categoryCascadeDeleteOption => 'Eliminar todo en cascada';

  @override
  String get categoryCascadeConfirmTitle =>
      '¿Eliminar la categoría y sus subcategorías?';

  @override
  String get categoryCascadeConfirmMessage =>
      'Se eliminarán la categoría y todas sus subcategorías. Podrás recuperarlas después desde la papelera.';
}
