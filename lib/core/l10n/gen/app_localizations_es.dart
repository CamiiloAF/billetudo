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
  String get commonContinue => 'Continuar';

  @override
  String get commonAnd => 'y';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonLoadMore => 'Ver más';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonMoreActions => 'Más opciones';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonClear => 'Limpiar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonRecommended => 'Recomendado';

  @override
  String get commonCreate => 'Crear';

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
      'Tus datos siguen guardados en tu dispositivo. Intenta de nuevo.';

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
  String get accountTypeBank => 'Cuenta corriente';

  @override
  String get accountTypeCard => 'Tarjeta de crédito';

  @override
  String get accountTypeSavings => 'Ahorros';

  @override
  String get accountTypeInvestment => 'Inversión';

  @override
  String get accountTypeOther => 'Cuenta general';

  @override
  String get accountBalanceLabel => 'Saldo actual';

  @override
  String get accountAvailableCreditLabel => 'Cupo disponible';

  @override
  String get accountDebtLabel => 'Deuda actual';

  @override
  String get accountBalanceAdjustTitle => 'Ajustar saldo';

  @override
  String accountBalanceAdjustCurrent(String amount) {
    return 'Saldo actual: $amount';
  }

  @override
  String accountBalanceAdjustCurrentDebt(String amount) {
    return 'Deuda actual: $amount';
  }

  @override
  String get accountBalanceAdjustNewLabel => 'Nuevo saldo deseado';

  @override
  String get accountBalanceAdjustNewDebtLabel => 'Nueva deuda';

  @override
  String get accountBalanceAdjustHowLabel => '¿Cómo quieres aplicarlo?';

  @override
  String get accountBalanceAdjustRegisterTitle => 'Registrar ajuste';

  @override
  String accountBalanceAdjustRegisterBody(String diff) {
    return 'Creamos un movimiento con fecha de hoy por la diferencia ($diff). Suma a tus reportes y presupuestos.';
  }

  @override
  String get accountBalanceAdjustCorrectTitle => 'Corregir saldo inicial';

  @override
  String get accountBalanceAdjustCorrectBody =>
      'Ajustamos tu saldo de arranque para que cuadre. No crea ningún movimiento.';

  @override
  String get accountBalanceAdjustApplyCta => 'Aplicar';

  @override
  String get accountBalanceAdjustError =>
      'No pudimos ajustar el saldo. Intenta de nuevo.';

  @override
  String get accountBalanceAdjustNote => 'Ajuste de saldo';

  @override
  String get accountDebtShortLabel => 'Deuda';

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
    return '••••••• $last4';
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
  String get accountFormNameLabel => 'Nombre de la cuenta';

  @override
  String get accountFormNameHint => 'Ej. Cuenta de ahorros';

  @override
  String get accountFormInstitutionLabel => 'Institución (opcional)';

  @override
  String get accountFormInstitutionHint => 'Opcional';

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
  String get accountFormAmountHint => '\$0';

  @override
  String get accountFormSelectHint => 'Seleccionar';

  @override
  String get accountFormSaveCta => 'Guardar cuenta';

  @override
  String get accountErrorType => 'Elige el tipo de cuenta.';

  @override
  String get accountErrorNameRequired => 'Ingresa un nombre para la cuenta.';

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
  String get accountDeleteSheetMessage =>
      'Esta cuenta no tiene movimientos asociados. Esta acción no se puede deshacer.';

  @override
  String accountDeleteSheetImpact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Esta cuenta tiene $count transacciones asociadas. Si la eliminas, ese historial se archivará también. Esta acción no se puede deshacer.',
      one:
          'Esta cuenta tiene 1 transacción asociada. Si la eliminas, ese historial se archivará también. Esta acción no se puede deshacer.',
    );
    return '$_temp0';
  }

  @override
  String get accountArchiveSheetTitle => '¿Archivar esta cuenta?';

  @override
  String get accountArchiveSheetMessage =>
      'Podrás recuperarla cuando quieras desde “Cuentas archivadas”.';

  @override
  String get accountChangeSheetMessage =>
      'Cambiar el tipo o la moneda de esta cuenta puede afectar cálculos y reportes de tus transacciones existentes. ¿Deseas continuar?';

  @override
  String get accountChangeConfirm => 'Confirmar';

  @override
  String get accountCurrencySheetTitle => 'Selecciona la moneda';

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
  String get categoryFormAppearanceLabel => 'Ícono y color';

  @override
  String get categoryFormAppearanceEmptyLabel => 'Elegir ícono y color';

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
  String get categoryErrorNameRequired =>
      'Ingresa un nombre para la categoría.';

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
  String get categoryDeleteSubcategoryAction => 'Eliminar subcategoría';

  @override
  String get categoryAppearancePickerTitle => 'Ícono y color';

  @override
  String get categoryColorLockedSubcategory =>
      'El color se hereda de la categoría padre y no se puede cambiar. Elige el ícono que prefieras.';

  @override
  String get categoryAppearanceIconSectionLabel => 'Ícono';

  @override
  String get categoryAppearanceColorSectionLabel => 'Color';

  @override
  String get categoryParentPickerTitle => 'Categoría padre';

  @override
  String get categoryParentPickerHint =>
      'Solo se muestran categorías principales de Gasto. Las subcategorías no pueden anidarse dentro de otras subcategorías.';

  @override
  String get categoryParentPickerEmpty =>
      'No hay categorías disponibles todavía.';

  @override
  String get categoryDeleteSimpleTitle => '¿Eliminar esta categoría?';

  @override
  String get categoryDeleteSimpleMessage =>
      'Esta categoría se eliminará de tu lista. Podrás recuperarla luego desde la papelera, en Ajustes.';

  @override
  String categoryDeleteTransactionsMessage(String categoryName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '\"$categoryName\" tiene $count movimientos asociados. Elige qué hacer con ellos antes de eliminar la categoría.',
      one:
          '\"$categoryName\" tiene 1 movimiento asociado. Elige qué hacer con él antes de eliminar la categoría.',
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
  String categoryDeleteSubcategoriesMessage(String categoryName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '\"$categoryName\" tiene $count subcategorías activas. Debes resolverlas antes de eliminar esta categoría raíz.',
      one:
          '\"$categoryName\" tiene 1 subcategoría activa. Debes resolverla antes de eliminar esta categoría raíz.',
    );
    return '$_temp0';
  }

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
      'Se eliminarán la categoría y todas sus subcategorías. Podrás deshacerlo justo después de eliminar.';

  @override
  String get transactionsTitle => 'Movimientos';

  @override
  String get transactionsSearchHint => 'Buscar por nota o categoría';

  @override
  String get transactionsLoading => 'Cargando movimientos';

  @override
  String get transactionsEmptyMessage =>
      'Todavía no hay movimientos registrados.';

  @override
  String get transactionsEmptyPeriodMessage =>
      'No hay movimientos en este periodo.';

  @override
  String get transactionsErrorTitle => 'No pudimos cargar tus movimientos';

  @override
  String get transactionsErrorLocalFirst =>
      'Tus datos siguen guardados en tu dispositivo. Intenta de nuevo.';

  @override
  String get transactionsAdd => 'Agregar movimiento';

  @override
  String get transactionsUndoDeletedMessage => 'Movimiento eliminado.';

  @override
  String get transactionsUndoAction => 'Deshacer';

  @override
  String get transactionsFilterAccounts => 'Cuentas';

  @override
  String get transactionsFilterCategories => 'Categorías';

  @override
  String get transactionsFilterType => 'Tipo';

  @override
  String get transactionsFilterDate => 'Fecha';

  @override
  String get transactionsFilterTag => 'Etiqueta';

  @override
  String get transactionsFilterBudget => 'Presupuesto';

  @override
  String get transactionsSortDateDesc => 'Más recientes primero';

  @override
  String get transactionsSortDateAsc => 'Más antiguos primero';

  @override
  String get transactionsSortAmountDesc => 'Mayor a menor';

  @override
  String get transactionsSortAmountAsc => 'Menor a mayor';

  @override
  String get transactionsSortSectionDate => 'FECHA';

  @override
  String get transactionsSortSectionAmount => 'MONTO';

  @override
  String get transactionsSortActiveByDate => 'Ordenado por fecha';

  @override
  String get transactionsSortActiveByAmount => 'Ordenado por monto';

  @override
  String transactionsFilterAccountsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuentas',
      one: '1 cuenta',
    );
    return '$_temp0';
  }

  @override
  String get transactionsBalanceTotalLabel => 'Saldo total';

  @override
  String transactionsBalanceTotalSemantics(String label, String amount) {
    return '$label: $amount';
  }

  @override
  String get transactionsBalanceCardBalanceLabel => 'Saldo';

  @override
  String get transactionsBalanceCarouselCollapse => 'Ocultar saldos';

  @override
  String get transactionsBalanceCarouselExpand => 'Mostrar saldos';

  @override
  String get transactionsGroupToday => 'Hoy';

  @override
  String get transactionsGroupYesterday => 'Ayer';

  @override
  String transactionsGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimientos',
      one: '1 movimiento',
    );
    return '$_temp0';
  }

  @override
  String get transactionTypeExpense => 'Gasto';

  @override
  String get transactionTypeIncome => 'Ingreso';

  @override
  String get transactionTypeTransfer => 'Transferencia';

  @override
  String get transactionFormNewExpenseTitle => 'Nuevo gasto';

  @override
  String get transactionFormNewIncomeTitle => 'Nuevo ingreso';

  @override
  String get transactionFormNewTransferTitle => 'Nueva transferencia';

  @override
  String get transactionFormEditTitle => 'Editar movimiento';

  @override
  String get transactionFormAmountLabel => 'Monto';

  @override
  String get transactionFormAccountLabel => 'Cuenta';

  @override
  String get transactionFormAccountChoose => 'Elegir cuenta';

  @override
  String get transactionFormTransferAccountLabel => 'Cuenta destino';

  @override
  String get transactionFormCategoryLabel => 'Categoría';

  @override
  String get transactionErrorAccount => 'Elige una cuenta.';

  @override
  String get transactionErrorCategory => 'Elige una categoría.';

  @override
  String get transactionErrorAmount => 'Ingresa un monto mayor a cero.';

  @override
  String get transactionErrorTransferAccount => 'Elige la cuenta de destino.';

  @override
  String get categorySelectTitle => 'Elegir categoría';

  @override
  String get categorySelectSearchHint => 'Buscar categoría';

  @override
  String get categorySelectMore => 'Ver más';

  @override
  String get categorySelectEmpty => 'No encontramos categorías con ese nombre';

  @override
  String get categorySelectExpand => 'Mostrar subcategorías';

  @override
  String get categorySelectCollapse => 'Ocultar subcategorías';

  @override
  String get transactionFormDateLabel => 'Fecha';

  @override
  String get transactionFormNoteLabel => 'Nota';

  @override
  String get transactionFormNoteHint => 'Agrega una nota (opcional)';

  @override
  String get transactionFormTagsLabel => 'Etiquetas';

  @override
  String get transactionFormAddTag => 'Agregar etiqueta';

  @override
  String get transactionFormTagNew => 'Nueva';

  @override
  String get transactionFormTagsSheetTitle => 'Etiquetas';

  @override
  String get transactionFormSourceLabel => 'Origen';

  @override
  String get transactionFormTransferAmountLabel => 'Monto a transferir';

  @override
  String get transactionFormTransferFromLabel => 'Cuenta origen';

  @override
  String get transactionFormCountsInBudgetLabel =>
      '¿Incluir en tu presupuesto?';

  @override
  String get transactionFormCountsInBudgetHintOff =>
      'Actívala para que se sume a tus presupuestos y reportes.';

  @override
  String get transactionFormCountsInBudgetHintOn =>
      'Se suma a tus presupuestos y reportes.';

  @override
  String get transactionFormSwapAccounts => 'Intercambiar cuentas';

  @override
  String get transactionFormDateToday => 'Hoy';

  @override
  String get transactionFormDateYesterday => 'Ayer';

  @override
  String transactionFormDateValue(String prefix, String date) {
    return '$prefix, $date';
  }

  @override
  String get datePickerTitle => 'Elegir fecha';

  @override
  String get datePickerPreviousMonth => 'Mes anterior';

  @override
  String get datePickerNextMonth => 'Mes siguiente';

  @override
  String get transactionFormExpandAmount => 'Editar monto';

  @override
  String get transactionFormCollapseAmount => 'Ocultar teclado';

  @override
  String get transactionFormKeypadAdd => 'Sumar';

  @override
  String get transactionFormKeypadSubtract => 'Restar';

  @override
  String get transactionFormKeypadMultiply => 'Multiplicar';

  @override
  String get transactionFormKeypadDivide => 'Dividir';

  @override
  String get transactionFormKeypadEquals => 'Calcular resultado';

  @override
  String get transactionFormKeypadConfirm => 'Confirmar';

  @override
  String get transactionFormKeypadDecimal => 'Punto decimal';

  @override
  String get transactionFormKeypadBackspace => 'Borrar';

  @override
  String get transactionSourceManual => 'Manual';

  @override
  String get transactionSourceVoice => 'Voz';

  @override
  String get transactionSourceOcr => 'Foto de recibo';

  @override
  String get transactionSourceNotification => 'Notificación bancaria';

  @override
  String get transactionSourceImported => 'Importado';

  @override
  String get transactionSourceScheduled => 'Programado';

  @override
  String transactionEditImpactMessage(String links) {
    return 'Esta transacción está vinculada a $links. Si cambias el monto, revisa que siga coincidiendo.';
  }

  @override
  String get transactionEditImpactLinkScheduled => 'tu pago programado';

  @override
  String get transactionEditImpactLinkGoal => 'tu meta';

  @override
  String get transactionEditImpactLinkDebt => 'tu deuda';

  @override
  String get transactionDeleteTitle => '¿Eliminar este movimiento?';

  @override
  String get transactionDeleteMessage =>
      'Podrás deshacerlo justo después de eliminar.';

  @override
  String get transactionDetailTitleExpense => 'Detalle del gasto';

  @override
  String get transactionDetailTitleIncome => 'Detalle del ingreso';

  @override
  String get transactionDetailTitleTransfer => 'Detalle de la transferencia';

  @override
  String transactionDetailSource(String source) {
    return 'Registrado como $source';
  }

  @override
  String get transactionDetailAccountLabel => 'Cuenta';

  @override
  String get transactionDetailAccountFromLabel => 'Cuenta origen';

  @override
  String get transactionDetailAccountToLabel => 'Cuenta destino';

  @override
  String get transactionDetailCategoryLabel => 'Categoría';

  @override
  String get transactionDetailDateLabel => 'Fecha';

  @override
  String get transactionDetailNoteLabel => 'Nota';

  @override
  String get transactionDetailNoNote => 'Sin nota';

  @override
  String get transactionDetailSourceLabel => 'Origen';

  @override
  String transactionDetailDebtLinkedLabel(String debtName) {
    return 'Enlazada a deuda: $debtName';
  }

  @override
  String get transactionDetailTagsLabel => 'Etiquetas';

  @override
  String get transactionDetailTransferSubtitle => 'Transferencia';

  @override
  String get transactionDetailDeleteLink => 'Eliminar movimiento';

  @override
  String get accountFilterSheetTitle => 'Filtrar por cuenta';

  @override
  String get accountFilterSelectAll => 'Todas';

  @override
  String get accountFilterSelectNone => 'Ninguna';

  @override
  String get categoryFilterSheetTitle => 'Filtrar por categoría';

  @override
  String get typeFilterSheetTitle => 'Filtrar por tipo';

  @override
  String get dateFilterSheetTitle => 'Filtrar por fecha';

  @override
  String get budgetPeriodFilterSheetTitle => 'Filtrar por presupuesto';

  @override
  String get budgetPeriodFilterEmptyMessage => 'No tienes presupuestos activos';

  @override
  String get dateFilterWeek => 'Semana';

  @override
  String get dateFilterMonth => 'Mes';

  @override
  String get dateFilterYear => 'Año';

  @override
  String get dateFilterCustomRange => 'Rango personalizado';

  @override
  String get dateFilterStart => 'Desde';

  @override
  String get dateFilterEnd => 'Hasta';

  @override
  String dateFilterRangeLabel(String start, String end) {
    return '$start - $end';
  }

  @override
  String get tagFilterSheetTitle => 'Filtrar por etiqueta';

  @override
  String get tagFilterSearchHint => 'Buscar etiqueta';

  @override
  String get tagFilterEmpty => 'No encontramos etiquetas con ese nombre';

  @override
  String get newTagSheetTitle => 'Nueva etiqueta';

  @override
  String get newTagNameHint => 'Nombre de la etiqueta';

  @override
  String get navHome => 'Inicio';

  @override
  String get navBudgets => 'Presupuestos';

  @override
  String get navGoals => 'Metas';

  @override
  String get navScheduledPayments => 'Pagos';

  @override
  String get navMore => 'Más';

  @override
  String get homeGreeting => 'Hola de nuevo';

  @override
  String homeGreetingNamed(String name) {
    return 'Hola de nuevo, $name';
  }

  @override
  String get homeNotificationsTooltip => 'Notificaciones';

  @override
  String get homeSyncSynced => 'Sincronizado';

  @override
  String get homeSyncSyncing => 'Sincronizando…';

  @override
  String get homeSyncOffline => 'Sin conexión';

  @override
  String get homeSyncSheetSyncedTitle => 'Todo a salvo';

  @override
  String get homeSyncSheetSyncedMessage =>
      'Tu información está a salvo y sincronizada.';

  @override
  String get homeSyncSheetSyncingTitle => 'Sincronizando…';

  @override
  String get homeSyncSheetSyncingMessage =>
      'Estamos guardando tus cambios en la nube. Puedes seguir usando la app.';

  @override
  String get homeSyncSheetOfflineTitle => 'Sin conexión';

  @override
  String get homeSyncSheetOfflineMessage =>
      'Tus datos están guardados en este teléfono. Se sincronizarán en cuanto vuelva la conexión.';

  @override
  String get homeSyncSheetDismiss => 'Entendido';

  @override
  String homeSpentInMonth(String month) {
    return 'Gastado en $month';
  }

  @override
  String get homeBudgetInvitation =>
      'Define un presupuesto para ver cuánto te queda este mes';

  @override
  String get homeNoSpendingYet => 'Aún no hay gastos este mes';

  @override
  String homeHeroBudgetProgress(int pct, String amount) {
    return '$pct% de $amount';
  }

  @override
  String homeHeroBudgetDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'faltan $count días',
      one: 'falta $count día',
      zero: 'último día',
    );
    return '$_temp0';
  }

  @override
  String get homeQuickAccessTitle => 'Acceso rápido';

  @override
  String get homeQuickAccessScheduledPayments => 'Pagos programados';

  @override
  String get homeRecentTitle => 'Movimientos recientes';

  @override
  String get homeSeeAll => 'Ver todos';

  @override
  String get homeBalancesTitle => 'Mis cuentas';

  @override
  String get homeBalancesSeeAll => 'Ver todas';

  @override
  String get homeEmptyMovements => 'Aún no registras movimientos';

  @override
  String get homeLoading => 'Cargando inicio';

  @override
  String get homeMonthPickerTitle => 'Selecciona el mes';

  @override
  String get homeAiBanner => 'Pronto: pregúntale a Billetudo';

  @override
  String get homeAiSheetMessage =>
      'Pronto podrás preguntarle a Billetudo sobre tu plata en lenguaje natural.';

  @override
  String get homeAiDisclaimer => 'No es asesoría financiera.';

  @override
  String get homeNotificationsSheetMessage =>
      'Las notificaciones llegarán pronto.';

  @override
  String get homeExitConfirmTitle => '¿Salir de Billetudo?';

  @override
  String get homeExitConfirmMessage =>
      'Puedes volver cuando quieras, tus datos se quedan guardados.';

  @override
  String get homeExitConfirmAction => 'Salir';

  @override
  String get comingSoonTitle => 'Próximamente';

  @override
  String get comingSoonMessage =>
      'Estamos preparando esta sección. Muy pronto la tendrás aquí.';

  @override
  String get comingSoonBadge => 'Próximamente';

  @override
  String get comingSoonUnderstood => 'Entendido';

  @override
  String get moreTitle => 'Más';

  @override
  String get moreAccountsDescription => 'Gestiona tus cuentas y saldos';

  @override
  String get moreCategoriesDescription => 'Organiza tus gastos e ingresos';

  @override
  String get moreDebts => 'Deudas';

  @override
  String get moreDebtsDescription => 'Sigue tus deudas y pagos';

  @override
  String get debtsTitle => 'Deudas';

  @override
  String get debtsAdd => 'Agregar deuda';

  @override
  String get debtsLoading => 'Cargando tus deudas';

  @override
  String get debtsSummaryTitle => 'Resumen';

  @override
  String get debtsSectionTitle => 'Tus deudas';

  @override
  String get debtsEmptyMessage => 'Aún no tienes deudas registradas';

  @override
  String get debtsEmptyDescription =>
      'Registra lo que debes o lo que te deben para seguir tu progreso de pago en un solo lugar.';

  @override
  String get debtsErrorTitle => 'No pudimos cargar tus deudas';

  @override
  String get debtDetailErrorTitle => 'No pudimos cargar esta deuda';

  @override
  String get debtDirectionIOwe => 'Yo debo';

  @override
  String get debtDirectionOwedToMe => 'Me deben';

  @override
  String debtProgressPaid(int pct) {
    return '$pct% pagado';
  }

  @override
  String debtProgressCollected(int pct) {
    return '$pct% cobrado';
  }

  @override
  String debtAmountOf(String amount) {
    return 'de $amount';
  }

  @override
  String debtDueOn(String date) {
    return 'Vence $date';
  }

  @override
  String debtPercentValue(int pct) {
    return '$pct%';
  }

  @override
  String get debtDetailBalanceLabel => 'Saldo pendiente';

  @override
  String get debtDetailPaidLabel => 'pagado';

  @override
  String get debtDetailCollectedLabel => 'cobrado';

  @override
  String debtDetailGrowth(String amount) {
    return 'Crece ~$amount/día';
  }

  @override
  String get debtDetailEstimated => 'estimado';

  @override
  String get debtDetailUpdateBalance => 'Actualizar saldo';

  @override
  String get debtDetailMovementsTitle => 'Movimientos';

  @override
  String get debtDetailRegisterPayment => 'Registrar abono';

  @override
  String get debtDetailCompleteDebt => 'Completar deuda';

  @override
  String get debtInstallmentTitle => 'Próxima cuota';

  @override
  String debtInstallmentBadge(String date) {
    return 'Cuota · $date';
  }

  @override
  String get debtInstallmentScheduledBadge => 'Pago programado';

  @override
  String get debtConfigureInstallmentTitle => 'Configurar cuota';

  @override
  String get debtConfigureInstallmentSubtitle =>
      'Programa la cuota de esta deuda';

  @override
  String get debtLedgerOpening => 'Saldo de apertura';

  @override
  String get debtLedgerDisbursement => 'Desembolso';

  @override
  String get debtLedgerPaymentOwe => 'Abono a la deuda';

  @override
  String get debtLedgerPaymentOwed => 'Pago recibido';

  @override
  String get debtLedgerInterest => 'Interés';

  @override
  String get debtLedgerAdjustment => 'Saldo actualizado';

  @override
  String debtLedgerRunning(String amount) {
    return 'Saldo $amount';
  }

  @override
  String get debtLedgerTagEstimated => 'Estimado';

  @override
  String get debtLedgerTagNoAccount => 'No afecta cuentas';

  @override
  String get debtEditTooltip => 'Editar deuda';

  @override
  String get debtDetailTitleFallback => 'Deuda';

  @override
  String get debtFormNewTitle => 'Nueva deuda';

  @override
  String get debtFormEditTitle => 'Editar deuda';

  @override
  String get debtFormDirectionLabel => '¿Debes o te deben?';

  @override
  String get debtFormOpeningBalanceLabel => 'Saldo de apertura';

  @override
  String get debtFormErrorAmountZero =>
      'El saldo de apertura debe ser mayor a 0';

  @override
  String get debtFormNameLabel => 'Nombre de la deuda';

  @override
  String get debtFormNameHint => 'Crédito vehicular, préstamo a Andrés…';

  @override
  String get debtFormNameRequired => 'Ponle un nombre a la deuda';

  @override
  String get debtFormCounterpartyLabel => 'Contraparte';

  @override
  String get debtFormCounterpartyLabelIOwe => 'Le debo a';

  @override
  String get debtFormCounterpartyLabelOwedToMe => 'Me debe';

  @override
  String get debtFormCounterpartyHint => 'Banco, persona…';

  @override
  String get debtFormStartDateLabel => 'Fecha';

  @override
  String get debtFormDueDateLabel => 'Fecha de vencimiento';

  @override
  String get debtFormDueDateHint => 'Sin fecha';

  @override
  String get debtFormErrorDueBeforeStart =>
      'La fecha de vencimiento debe ser posterior a la fecha de inicio';

  @override
  String get debtFormInterestLabel => 'Interés anual (opcional)';

  @override
  String get debtFormInterestHint => '0';

  @override
  String get debtFormInterestError => 'Revisa la tasa de interés';

  @override
  String get debtFormAccrualModeLabel => 'Modo de interés';

  @override
  String get debtFormAccrualManual => 'Manual';

  @override
  String get debtFormAccrualAuto => 'Automático';

  @override
  String get debtFormAccrualHint =>
      'Manual: tú pones la cifra del banco. Automático estima el crecimiento diario (estimado).';

  @override
  String get debtFormCreateCta => 'Crear deuda';

  @override
  String get debtFormSaveCta => 'Guardar cambios';

  @override
  String get debtFormDelete => 'Eliminar deuda';

  @override
  String get debtCurrencySheetTitle => 'Moneda';

  @override
  String debtCurrencyPill(String code, String name) {
    return '$code · $name';
  }

  @override
  String get debtDeleteSheetTitle => '¿Eliminar esta deuda?';

  @override
  String get debtDeleteSheetMessage => 'Podrás recuperarla desde la papelera.';

  @override
  String debtContext(String name, String direction) {
    return '$name · $direction';
  }

  @override
  String debtDateToday(String date) {
    return 'Hoy, $date';
  }

  @override
  String get debtPaymentTitle => 'Registrar abono';

  @override
  String get debtPaymentAmountLabel => 'Abono';

  @override
  String get debtPaymentAddToAccountLabel => '¿Agregar a una cuenta?';

  @override
  String get debtPaymentAddToAccountHintYes =>
      'Moverá el saldo y contará en tus estadísticas';

  @override
  String get debtPaymentAddToAccountHintNo =>
      'Este abono baja el saldo de la deuda pero no moverá ninguna cuenta.';

  @override
  String get debtPaymentLinkExisting =>
      '¿Ya lo registraste? Enlaza un movimiento';

  @override
  String get debtPaymentDateLabel => 'Fecha';

  @override
  String get debtPaymentNoteLabel => 'Nota (opcional)';

  @override
  String get debtPaymentNoteHint => 'Agregar una nota';

  @override
  String get debtPaymentCategoryLabel => 'Categoría';

  @override
  String get debtPaymentCategoryNone => 'Elige una categoría';

  @override
  String get debtPaymentSelectAccount => 'Elige una cuenta';

  @override
  String get debtPaymentAccountPickerTitle => 'Elige una cuenta';

  @override
  String debtOpeningMovementNote(String debtName) {
    return 'Deuda: $debtName';
  }

  @override
  String get debtPaymentCta => 'Registrar abono';

  @override
  String get debtPaymentError =>
      'No pudimos registrar el abono. Intenta de nuevo.';

  @override
  String get debtUpdateBalanceTitle => 'Actualizar saldo';

  @override
  String get debtUpdateBalanceNewLabel => 'Nuevo saldo';

  @override
  String get debtUpdateBalanceEstimatedLabel => 'Saldo estimado hoy';

  @override
  String get debtUpdateBalanceAdjustLabel => 'Ajuste que se registra';

  @override
  String get debtUpdateBalanceHint =>
      'Registra un ajuste en la deuda para igualar la cifra del banco. No mueve ninguna cuenta.';

  @override
  String get debtUpdateBalanceDateLabel => 'Fecha del ajuste';

  @override
  String get debtUpdateBalanceCta => 'Guardar saldo';

  @override
  String get debtUpdateBalanceError =>
      'No pudimos actualizar el saldo. Intenta de nuevo.';

  @override
  String debtLinkBannerTitle(String debt) {
    return 'Enlazar a $debt';
  }

  @override
  String get debtLinkBannerBody =>
      'Elige un movimiento que ya registraste; lo atribuimos a esta deuda, no creamos uno nuevo.';

  @override
  String get debtLinkError =>
      'No pudimos enlazar el movimiento. Intenta de nuevo.';

  @override
  String get debtInitialRegistroTitle =>
      '¿Quieres crear un registro inicial para esta deuda?';

  @override
  String get debtInitialRegistroMessage =>
      'Si lo creas, cambiará el saldo de la cuenta que elijas.';

  @override
  String get debtInitialRegistroSoloDeuda => 'No, solo la deuda';

  @override
  String get debtInitialRegistroChooseAccount => 'Sí, elegir cuenta';

  @override
  String get debtUpdateRegistroTitle => '¿Actualizar también el registro?';

  @override
  String debtUpdateRegistroMessage(String from, String to) {
    return 'Cambiar el saldo de apertura actualizará el registro inicial de $from a $to.';
  }

  @override
  String get debtUpdateRegistroConfirm => 'Actualizar';

  @override
  String get debtOpeningLinkSnackbar => 'Saldo inicial · sin cuenta enlazada';

  @override
  String get debtLedgerAbonoNoAccountSnackbar =>
      'Este abono no movió ninguna cuenta';

  @override
  String get debtMenuTooltip => 'Más opciones';

  @override
  String get debtActionClose => 'Cerrar deuda';

  @override
  String get debtActionComplete => 'Completar deuda';

  @override
  String get debtFormErrorDirectionLocked =>
      'No puedes cambiar la dirección de esta deuda porque ya tiene movimientos registrados además de la apertura.';

  @override
  String get debtActionError =>
      'No pudimos completar la acción. Intenta de nuevo.';

  @override
  String get debtActionCloseSuccess => 'Deuda completada';

  @override
  String get debtCloseSheetTitle => '¿Cerrar esta deuda?';

  @override
  String debtCloseSheetMessageIOwe(String amount, String counterparty) {
    return 'Le debes $amount a $counterparty. Al cerrarla, dejará de aparecer en tus deudas activas y no te seguirá recordando pagarla.';
  }

  @override
  String debtCloseSheetMessageIOweNoCounterparty(String amount) {
    return 'Debes $amount. Al cerrarla, dejará de aparecer en tus deudas activas y no te seguirá recordando pagarla.';
  }

  @override
  String debtCloseSheetMessageOwedToMe(String counterparty, String amount) {
    return '$counterparty te debe $amount. Al cerrarla, dejará de aparecer en tus deudas activas y no te seguirá recordando cobrarla.';
  }

  @override
  String debtCloseSheetMessageOwedToMeNoCounterparty(String amount) {
    return 'Te deben $amount. Al cerrarla, dejará de aparecer en tus deudas activas y no te seguirá recordando cobrarla.';
  }

  @override
  String get debtCloseInfoLabel => 'Saldo pendiente al cerrar';

  @override
  String get debtCloseCta => 'Cerrar deuda';

  @override
  String get debtCelebrationTitleIOwe => '¡Felicidades! Ya no debes nada';

  @override
  String get debtCelebrationTitleOwedToMe =>
      '¡Felicidades! Ya no te deben nada';

  @override
  String debtCelebrationMessageIOwe(
      String name, String amount, String duration) {
    return 'Terminaste de pagar $name. En total pagaste $amount en $duration.';
  }

  @override
  String debtCelebrationMessageOwedToMe(
      String name, String amount, String duration) {
    return 'Terminaste de cobrar $name. En total cobraste $amount en $duration.';
  }

  @override
  String get debtCelebrationStatTotalPaidIOwe => 'Total pagado';

  @override
  String get debtCelebrationStatTotalPaidOwedToMe => 'Total cobrado';

  @override
  String get debtCelebrationStatDuration => 'Duración';

  @override
  String get debtCelebrationDismiss => 'Ahora no';

  @override
  String get debtCelebrationComplete => 'Completar';

  @override
  String debtDurationMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '1 mes',
    );
    return '$_temp0';
  }

  @override
  String debtDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get debtDirectionIOwePast => 'Debía';

  @override
  String get debtDirectionOwedToMePast => 'Me debían';

  @override
  String debtCardStatusPaid(String date) {
    return 'Pagada · $date';
  }

  @override
  String debtCardStatusClosed(String date) {
    return 'Cerrada · $date';
  }

  @override
  String get debtsTabActive => 'Activas';

  @override
  String get debtsTabClosed => 'Cerradas';

  @override
  String get debtsClosedPaidLabel => 'Pagué';

  @override
  String get debtsClosedCollectedLabel => 'Me pagaron';

  @override
  String get debtsClosedEmptyMessage => 'Aún no has cerrado ninguna deuda';

  @override
  String get debtsActiveEmptyMessage => 'No tienes deudas activas';

  @override
  String get moreScheduledPayments => 'Pagos programados';

  @override
  String get moreScheduledPaymentsDescription => 'Pagos e ingresos automáticos';

  @override
  String get moreReports => 'Gráficas e informes';

  @override
  String get moreReportsDescription => 'Visualiza tus finanzas con gráficas';

  @override
  String get moreGoalsDescription => 'Ahorra para tus metas y objetivos';

  @override
  String get moreImportExport => 'Importar y exportar';

  @override
  String get moreImportExportDescription => 'Guarda una copia o trae tus datos';

  @override
  String get moreSettings => 'Ajustes';

  @override
  String get moreSettingsDescription => 'Preferencias y tu cuenta';

  @override
  String get moreSignOut => 'Cerrar sesión';

  @override
  String get authContinueWithGoogle => 'Continuar con Google';

  @override
  String get authContinueWithApple => 'Continuar con Apple';

  @override
  String get authContinueWithoutAccount => 'Continuar sin cuenta';

  @override
  String get authLoginTitle => 'Nunca pierdas tu progreso';

  @override
  String get authLoginSubtitle =>
      'Un respaldo automático de tus cuentas y movimientos, listo para cuando lo necesites.';

  @override
  String get authTrustRow =>
      'Usa la app desde cualquier celular sin perder tu historial';

  @override
  String get authGoogleLoading => 'Conectando con Google…';

  @override
  String get authGoogleErrorSnackbar => 'No pudimos iniciar sesión con Google';

  @override
  String get authAppleErrorSnackbar => 'No pudimos iniciar sesión con Apple';

  @override
  String get authMergeTitle => 'Tus datos están a salvo';

  @override
  String get authMergeSubtitle =>
      'Combinamos todo lo que ya tenías guardado con tu cuenta. Nada se perdió en el camino.';

  @override
  String get authMergeStatAccounts => 'Cuentas';

  @override
  String get authMergeStatTransactions => 'Movimientos';

  @override
  String get authMergeStatCategories => 'Categorías';

  @override
  String get authMergeCaption =>
      'Tus dispositivos se mantendrán sincronizados automáticamente';

  @override
  String get authMergeCta => 'Ir a mis finanzas';

  @override
  String get authMergeErrorTitle => 'No pudimos fusionar tus datos';

  @override
  String get authMergeErrorMessage =>
      'Tus datos siguen a salvo en este dispositivo. Intenta de nuevo cuando tengas conexión.';

  @override
  String get authSignOutSheetTitle => 'Cerrar sesión';

  @override
  String get authSignOutSheetMessage =>
      'Tus cuentas y movimientos seguirán guardados en este teléfono. Dejarás de sincronizar hasta que vuelvas a iniciar sesión.';

  @override
  String get authSignOutSheetMessageDeleting =>
      'Dejarás de sincronizar hasta que vuelvas a iniciar sesión.';

  @override
  String get authSignOutCta => 'Cerrar sesión';

  @override
  String get authSignOutDeleteCta => 'Borrar y salir';

  @override
  String get authSignOutDeleteOptInTitle =>
      'Borrar también los datos de este teléfono';

  @override
  String get authSignOutDeleteOptInSubtitle =>
      'Tu cuenta en la nube no se toca: al volver a entrar, los recuperas.';

  @override
  String get authSignOutUnsyncedTitle => 'Hay cambios que aún no se han subido';

  @override
  String authSignOutUnsyncedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count cambios siguen guardados solo en este teléfono. Si borras ahora, esos cambios no quedarán en la nube.',
      one:
          '1 cambio sigue guardado solo en este teléfono. Si borras ahora, ese cambio no quedará en la nube.',
    );
    return '$_temp0';
  }

  @override
  String get authSignOutWipeErrorMessage =>
      'Cerramos tu sesión, pero no pudimos borrar los datos de este teléfono. Siguen aquí.';

  @override
  String get authSignOutFailedMessage =>
      'No pudimos cerrar tu sesión, así que no borramos nada de este teléfono. Inténtalo de nuevo.';

  @override
  String get authDeleteStep1Title => 'Eliminar tu cuenta';

  @override
  String get authDeleteStep1Message =>
      'Esta acción es irreversible. Se borrarán para siempre todos tus datos en la nube: cuentas, movimientos, categorías y todo lo demás asociado a tu cuenta.';

  @override
  String get authDeleteStep1Cta => 'Eliminar cuenta';

  @override
  String get authDeleteStep1ErrorTitle => 'No pudimos eliminar tu cuenta';

  @override
  String get authDeleteStep1ErrorMessage =>
      'Hubo un problema para conectar con el servidor y no pudimos completar la solicitud. Tus datos siguen a salvo en este dispositivo — intenta de nuevo.';

  @override
  String get authDeleteStep2Title =>
      '¿Qué hacemos con tus datos en este teléfono?';

  @override
  String get authDeleteStep2Subtitle =>
      'Tu cuenta en la nube ya fue eliminada. Elige qué pasa con lo que queda guardado aquí, en este dispositivo.';

  @override
  String get authDeleteStep2KeepTitle =>
      'Conservar mis datos en este dispositivo';

  @override
  String get authDeleteStep2KeepSubtitle =>
      'Sigue usando billetudo sin cuenta, con lo que ya tienes registrado.';

  @override
  String get authDeleteStep2DeleteTitle =>
      'Borrar también los datos de este dispositivo';

  @override
  String get authDeleteStep2DeleteSubtitle =>
      'Se elimina todo tu historial local.';

  @override
  String get authDeleteStep2Cta => 'Continuar';

  @override
  String get authDeleteStep3Title => 'Listo, tu cuenta fue eliminada';

  @override
  String get authDeleteStep3Subtitle =>
      'Ya no tenemos ningún dato tuyo en la nube. Puedes seguir usando billetudo cuando quieras, con o sin cuenta.';

  @override
  String get authDeleteStep3Cta => 'Ir al inicio';

  @override
  String get authSessionProviderGoogle => 'Sesión iniciada con Google';

  @override
  String get authSessionProviderApple => 'Sesión iniciada con Apple';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAccountSection => 'Cuenta y respaldo';

  @override
  String get settingsBackupTitle => 'Respaldar en la nube';

  @override
  String get settingsBackupSubtitle => 'Guarda tus datos de forma segura';

  @override
  String get settingsBudgetSection => 'Presupuesto';

  @override
  String get settingsPreferencesSection => 'Preferencias';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsAppearanceLight => 'Claro';

  @override
  String get settingsAppearanceDark => 'Oscuro';

  @override
  String get settingsAppearanceSystem => 'Sistema';

  @override
  String get settingsCurrency => 'Moneda';

  @override
  String get settingsCurrencySubtitle =>
      'Elige la moneda con la que registras tus movimientos';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String get budgetsTitle => 'Presupuestos';

  @override
  String get budgetsAdd => 'Nuevo presupuesto';

  @override
  String get budgetsNewCta => '+ Nuevo presupuesto';

  @override
  String get budgetsEmptyMessage => 'Aún no tienes presupuestos';

  @override
  String get budgetsEmptyCta => 'Crear presupuesto';

  @override
  String get budgetsEmptyDescription =>
      'Crea uno para controlar tu gasto sin esfuerzo';

  @override
  String get budgetsLoading => 'Cargando tus presupuestos';

  @override
  String get budgetsErrorTitle => 'No pudimos cargar tus presupuestos';

  @override
  String get budgetsMenuHistory => 'Ver histórico';

  @override
  String get budgetsMenuTooltip => 'Más opciones';

  @override
  String get budgetRemainingLabel => 'Te quedan';

  @override
  String get budgetOverspentLabel => 'Excedido por';

  @override
  String get budgetAtRiskLabel => 'Podría exceder por';

  @override
  String budgetResetsOn(String date) {
    return 'se reinicia el $date';
  }

  @override
  String budgetEndsOn(String date) {
    return 'termina el $date';
  }

  @override
  String get budgetScopeGlobal => 'Todo el gasto';

  @override
  String get budgetScopeStranded => 'Sin alcance válido';

  @override
  String budgetScopeAccounts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuentas',
      one: '$count cuenta',
    );
    return '$_temp0';
  }

  @override
  String budgetScopeCategories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorías',
      one: '$count categoría',
    );
    return '$_temp0';
  }

  @override
  String budgetPercent(int pct) {
    return '$pct%';
  }

  @override
  String budgetDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restan $count días',
      one: 'Resta $count día',
      zero: 'Último día',
    );
    return '$_temp0';
  }

  @override
  String budgetEndsInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Termina en $count días',
      one: 'Termina en $count día',
      zero: 'Último día',
    );
    return '$_temp0';
  }

  @override
  String budgetProgressBreakdown(String spent, String amount) {
    return '$spent de $amount';
  }

  @override
  String get budgetActivityTitle => 'Movimientos del periodo';

  @override
  String budgetActivityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimientos',
      one: '$count movimiento',
    );
    return '$_temp0';
  }

  @override
  String get budgetActivityEmpty => 'Sin movimientos en este periodo';

  @override
  String get budgetScheduledLabel => 'Programado';

  @override
  String budgetScheduledEntrySub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagos próximos',
      one: '$count pago próximo',
    );
    return '$_temp0';
  }

  @override
  String budgetScheduledEntrySubRisk(String amount) {
    return 'Excedería el presupuesto por $amount';
  }

  @override
  String budgetScheduledCaption(String amount, int pct) {
    return '+ $amount programado (llega a $pct% si se ejecuta)';
  }

  @override
  String budgetScheduledCaptionRisk(String amount, String overage) {
    return '+ $amount programado — excedería el presupuesto por $overage';
  }

  @override
  String budgetScheduledFreeCaption(String amount) {
    return '$amount quedarían libres si apruebas los programados';
  }

  @override
  String get budgetScheduledSheetTitle => 'Pagos programados del período';

  @override
  String get budgetScheduledSheetSeeAll => 'Ver todos los pagos programados';

  @override
  String budgetScheduledSheetHint(String amount) {
    return 'Suman $amount de lo reservado este período.';
  }

  @override
  String get budgetScheduledSheetEmpty =>
      'Aún no tienes pagos programados en este período';

  @override
  String budgetScheduledRowSubtitle(String date, String accountName) {
    return 'Próximo: $date · $accountName';
  }

  @override
  String get budgetOneOffWindow => 'Ventana única';

  @override
  String get budgetPeriodPreviousTooltip => 'Periodo anterior';

  @override
  String get budgetPeriodNextTooltip => 'Periodo siguiente';

  @override
  String get budgetPeriodStatusCurrent => 'vigente';

  @override
  String get budgetPeriodStatusPast => 'pasado';

  @override
  String get budgetPeriodStatusFuture => 'futuro';

  @override
  String get budgetActionClose => 'Cerrar (guardar en histórico)';

  @override
  String get budgetActionDelete => 'Eliminar';

  @override
  String get budgetActionDeleteBudget => 'Eliminar presupuesto';

  @override
  String get budgetActionAdjustAmount => 'Ajustar monto — este período';

  @override
  String get budgetDetailActionsSubtitle => 'Acciones del presupuesto';

  @override
  String get budgetDeleteConfirmMessage =>
      'Este presupuesto se eliminará. Podrás deshacerlo justo después de eliminar.';

  @override
  String get budgetFormNewTitle => 'Nuevo presupuesto';

  @override
  String get budgetFormEditTitle => 'Editar presupuesto';

  @override
  String get budgetFormNameLabel => 'Nombre';

  @override
  String get budgetFormIconNameLabel => 'Ícono y nombre';

  @override
  String budgetFormRowValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get budgetFormScopeAllHint =>
      'Incluye todo tu gasto: todas las cuentas y categorías.';

  @override
  String get budgetFormNameHint => 'Ej. Mercado del mes';

  @override
  String get budgetErrorName => 'Escribe un nombre para el presupuesto.';

  @override
  String get budgetErrorAmount => 'Ingresa un monto mayor a cero.';

  @override
  String get budgetErrorEndDate =>
      'Elige una fecha de fin posterior al inicio.';

  @override
  String get budgetFormIconLabel => 'Ícono';

  @override
  String get budgetFormAmountLabel => 'Monto';

  @override
  String get budgetFormRepeatLabel => 'Repetir';

  @override
  String get budgetFormRepeatPeriodic => 'Periódico';

  @override
  String get budgetFormRepeatOneOff => 'Una única vez';

  @override
  String get budgetFormPeriodLabel => 'Periodicidad';

  @override
  String get budgetPeriodWeekly => 'Semanal';

  @override
  String get budgetPeriodBiweekly => 'Quincenal';

  @override
  String get budgetPeriodMonthly => 'Mensual';

  @override
  String get budgetPeriodYearly => 'Anual';

  @override
  String get budgetFormStartLabel => 'Inicio';

  @override
  String get budgetFormEndLabel => 'Fin';

  @override
  String get budgetFormEndHint => 'Elegir fecha';

  @override
  String get budgetFormRepeatUntilLabel => 'Repetir hasta';

  @override
  String get budgetFormForever => 'Para siempre';

  @override
  String get budgetFormUntilDate => 'Hasta una fecha';

  @override
  String get budgetFormScopeLabel => 'Alcance';

  @override
  String get budgetFormScopeAll => 'Todo';

  @override
  String get budgetFormScopeCustom => 'Personalizado';

  @override
  String get budgetFormAccountsRow => 'Cuentas';

  @override
  String get budgetFormCategoriesRow => 'Categorías';

  @override
  String get budgetScopeAllAccounts => 'Todas las cuentas';

  @override
  String get budgetScopeAllCategories => 'Todas las categorías';

  @override
  String budgetFormThresholdRow(int pct) {
    return 'Avisarme al $pct% del presupuesto';
  }

  @override
  String get budgetFormThresholdOff => 'No avisarme';

  @override
  String get budgetFormCreateCta => 'Crear presupuesto';

  @override
  String get budgetFormSaveCta => 'Guardar cambios';

  @override
  String get budgetThresholdTitle => 'Avisarme cuando gaste el…';

  @override
  String get budgetThresholdHint =>
      'Te enviaremos un aviso local al llegar a ese % — sin costo.';

  @override
  String get budgetThresholdRecommended => 'Recomendado';

  @override
  String get budgetThresholdCustom => 'Personalizado';

  @override
  String get budgetThresholdCustomSubtitle => 'Define tu propio %';

  @override
  String get budgetThresholdCustomTitle => 'Define tu propio %';

  @override
  String get budgetThresholdCustomHint => 'Ajusta el porcentaje en pasos de 5.';

  @override
  String get budgetThresholdOffSubtitle =>
      'Desactiva la alerta de este presupuesto';

  @override
  String get budgetThresholdDecrease => 'Bajar el porcentaje';

  @override
  String get budgetThresholdIncrease => 'Subir el porcentaje';

  @override
  String get budgetIconSheetTitle => 'Elegir ícono';

  @override
  String get budgetIconSheetHint =>
      'El ícono se muestra en un fondo neutro — sin color por presupuesto.';

  @override
  String get budgetsHistoryTitle => 'Histórico';

  @override
  String get budgetsHistoryEmpty => 'No has cerrado ningún presupuesto';

  @override
  String get budgetsHistoryEmptyDescription =>
      'Cuando cierres uno, lo encontrarás aquí para consultarlo o reactivarlo';

  @override
  String get budgetsHistoryLoading => 'Cargando tu histórico';

  @override
  String get budgetDetailLoading => 'Cargando el presupuesto';

  @override
  String get budgetFormLoading => 'Cargando el formulario';

  @override
  String budgetClosedOn(String date) {
    return 'Cerrado $date';
  }

  @override
  String get budgetsHistorySubtitle => 'Presupuestos cerrados';

  @override
  String get budgetsHistoryHint =>
      'Los conservas sin borrar. Puedes reactivarlos cuando quieras.';

  @override
  String get budgetsMenuOptions => 'Opciones';

  @override
  String get budgetsMenuHistorySubtitle => 'Presupuestos cerrados';

  @override
  String get budgetsMenuEnableEnvelope => 'Activar modo sobres';

  @override
  String get budgetsMenuEnableEnvelopeSubtitle =>
      'Reparte todo tu ingreso en sobres';

  @override
  String get budgetsMenuDisableEnvelopeSubtitle => 'Vuelve a la lista normal';

  @override
  String get budgetsEnvelopeBadge => 'Modo sobres';

  @override
  String budgetsEnvelopeIncome(String income) {
    return 'Ingreso $income';
  }

  @override
  String budgetsEnvelopeAssigned(String assigned) {
    return 'Asignado $assigned';
  }

  @override
  String budgetsEnvelopeNudge(String amount) {
    return 'Casi lo logras: dale un trabajo a los $amount restantes.';
  }

  @override
  String budgetsEnvelopeNudgeOver(String amount) {
    return 'Asignaste $amount más de lo que entró. Ajusta un sobre cuando quieras.';
  }

  @override
  String get budgetAssignedLabel => 'Asignado';

  @override
  String get budgetReactivate => 'Reactivar';

  @override
  String get budgetResultWithin => 'Terminó dentro del presupuesto';

  @override
  String budgetResultOverspent(String amount) {
    return 'Excedido por $amount';
  }

  @override
  String deleteImpactBudgets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se usa en $count presupuestos.',
      one: 'Se usa en 1 presupuesto.',
    );
    return '$_temp0';
  }

  @override
  String get settingsEnvelopeMode => 'Modo sobres';

  @override
  String get settingsEnvelopeModeSubtitle =>
      'Reparte todo tu ingreso en sobres';

  @override
  String get settingsEnvelopeWhatIs => '¿Qué es?';

  @override
  String get envelopeInfoTitle => '¿Qué es el modo sobres?';

  @override
  String get envelopeInfoBody =>
      'Es una forma de presupuestar donde le das un trabajo a cada peso. Repartes todo tu ingreso del mes en \'sobres\' —tus presupuestos— hasta que no quede nada sin asignar.';

  @override
  String get envelopeInfoBulletJobs =>
      'Así decides a dónde va tu plata antes de gastarla: gastar, ahorrar o pagar deudas.';

  @override
  String get envelopeInfoBulletZero =>
      'Cuando \'Sin asignar\' llega a \$0, cada peso tiene un propósito.';

  @override
  String get envelopeInfoReassure =>
      'Es opcional y no te bloquea nada. Actívalo o desactívalo cuando quieras.';

  @override
  String get envelopeInfoActivate => 'Activar modo sobres';

  @override
  String get envelopeInfoGotIt => 'Entendido';

  @override
  String get budgetsMenuDisableEnvelope => 'Desactivar modo sobres';

  @override
  String get budgetsEnvelopeUnassignedLabel => 'Sin asignar este mes';

  @override
  String get budgetsEnvelopeOverLabel => 'Asignado de más';

  @override
  String get budgetsEnvelopeAllAssigned => 'Cada peso tiene un trabajo';

  @override
  String get firstLaunchOfflineTitle => 'Conéctate para continuar';

  @override
  String get firstLaunchOfflineSubtitle =>
      'Necesitamos conexión a internet para terminar de configurar tu cuenta. Cuando tengas señal, vuelve a intentarlo.';

  @override
  String get firstLaunchOfflineRetrying => 'Reintentando...';

  @override
  String get splashLoadingCaption => 'Cargando tus finanzas...';

  @override
  String get brandWordmarkPrefix => 'b';

  @override
  String get brandWordmarkDotlessI => 'ı';

  @override
  String get brandWordmarkSuffix => 'lletudo';

  @override
  String get scheduledPaymentsTitle => 'Pagos programados';

  @override
  String get scheduledPaymentsAdd => 'Nuevo pago programado';

  @override
  String get scheduledPaymentsLoading => 'Cargando tus pagos programados';

  @override
  String get scheduledPaymentUntitled => 'Pago programado';

  @override
  String get scheduledPaymentsEmptyMessage => 'Aún no tienes pagos programados';

  @override
  String get scheduledPaymentsErrorTitle =>
      'No pudimos cargar tus pagos programados';

  @override
  String get scheduledPaymentsErrorLocalFirst =>
      'Tus datos siguen guardados en tu dispositivo. Intenta de nuevo.';

  @override
  String scheduledPaymentsActiveCount(int count) {
    return 'Activos · $count';
  }

  @override
  String get scheduledPendingTitle => 'Por confirmar';

  @override
  String get scheduledPendingEmpty => 'No tienes pagos por confirmar.';

  @override
  String get scheduledReviewAll => 'Revisar todas';

  @override
  String get scheduledPendingBadge => 'Pendiente de confirmar';

  @override
  String get scheduledOnceBadge => 'Pago único';

  @override
  String get scheduledInactiveBadge => 'Inactivo';

  @override
  String get scheduledConfirmationSheetTitle => 'Confirmar pago';

  @override
  String get scheduledConfirmationSheetConfirm => 'Confirmar';

  @override
  String get scheduledConfirmationSheetSkip => 'Omitir';

  @override
  String get scheduledConfirmationSheetSnooze => 'Posponer';

  @override
  String scheduledGuidedReviewPosition(int position, int total) {
    return 'Pago $position de $total';
  }

  @override
  String get scheduledUndoSkipMessage => 'Pago omitido';

  @override
  String get scheduledUndoSnoozeMessage => 'Pago pospuesto';

  @override
  String get scheduledSnoozeSheetTitle => 'Posponer pago';

  @override
  String get scheduledSnoozeSheetSave => 'Posponer';

  @override
  String get scheduledDeleteSheetTitle => '¿Eliminar este pago programado?';

  @override
  String get scheduledDeleteSheetMessage =>
      'Se detiene la generación de pagos futuros. Las transacciones que ya generó se conservan en tu historial.';

  @override
  String get scheduledDeleteSheetTitleInstallment => '¿Eliminar esta cuota?';

  @override
  String get scheduledDeleteSheetMessageInstallment =>
      'Se deja de agendar la cuota. La deuda y los abonos que ya registró se conservan en tu historial.';

  @override
  String get scheduledPaymentFormNewTitle => 'Nuevo pago programado';

  @override
  String get scheduledPaymentFormEditTitle => 'Editar pago programado';

  @override
  String get scheduledPaymentFormNextDateLabel => 'Primer pago';

  @override
  String get scheduledPaymentFormOnceDateLabel => 'Fecha del pago';

  @override
  String get scheduledPaymentFormModeSectionLabel => 'Al llegar la fecha';

  @override
  String get scheduledPaymentFormTagNew => 'Etiqueta';

  @override
  String get scheduledPaymentFormFrequencyLabel => 'Frecuencia';

  @override
  String get scheduledPaymentFormCategoryMoreLabel => 'Otra';

  @override
  String get scheduledPaymentErrorAccount => 'Elige una cuenta.';

  @override
  String get scheduledPaymentErrorAmount => 'Ingresa un monto mayor a cero.';

  @override
  String get scheduledPaymentErrorTransferAccount =>
      'Elige la cuenta de destino.';

  @override
  String get scheduledPaymentErrorCategory => 'Elige una categoría.';

  @override
  String get scheduledPaymentInstallmentAmountExceedsError =>
      'La cuota no puede superar el saldo de la deuda.';

  @override
  String get scheduledPaymentFormNotFoundError =>
      'Este pago programado ya no existe. Es posible que lo hayas eliminado.';

  @override
  String get scheduledPaymentFormSaveError =>
      'No pudimos guardar los cambios. Intenta de nuevo.';

  @override
  String get scheduledPaymentFormIntervalStepperLabel => 'Repetir cada';

  @override
  String get scheduledPaymentFormEndDateLabel => 'Termina';

  @override
  String get scheduledPaymentFormEndDateNone => 'Para siempre';

  @override
  String get scheduledPaymentFormModeAutomaticTitle => 'Automático';

  @override
  String get scheduledPaymentFormModeAutomaticSubtitle =>
      'Se registra solo al llegar la fecha';

  @override
  String get scheduledPaymentFormModeManualTitle => 'Manual';

  @override
  String get scheduledPaymentFormModeManualSubtitle =>
      'Por ahora deberás confirmarlo tú mismo';

  @override
  String get scheduledPaymentFormDeleteAction => 'Eliminar pago programado';

  @override
  String get scheduledPaymentInstallmentTitle => 'Configurar cuota';

  @override
  String get scheduledPaymentInstallmentEditTitle => 'Editar cuota';

  @override
  String get scheduledPaymentInstallmentDeleteAction => 'Eliminar cuota';

  @override
  String get scheduledPaymentInstallmentBanner =>
      'Se crea un pago programado enlazado a esta deuda. Confírmalo o pospónlo en Pagos programados.';

  @override
  String get scheduledPaymentDetailLinkedDebtLabel => 'Cuota de';

  @override
  String get scheduledDebtChipLabel => 'Deuda';

  @override
  String get scheduledFrequencyOnce => 'Solo una vez';

  @override
  String get scheduledFrequencyDaily => 'cada día';

  @override
  String get scheduledFrequencyWeekly => 'cada semana';

  @override
  String get scheduledFrequencyMonthly => 'cada mes';

  @override
  String get scheduledFrequencyYearly => 'cada año';

  @override
  String get scheduledFrequencyChipOnce => 'Único';

  @override
  String get scheduledFrequencyChipDaily => 'Día';

  @override
  String get scheduledFrequencyChipWeekly => 'Semana';

  @override
  String get scheduledFrequencyChipMonthly => 'Mes';

  @override
  String get scheduledFrequencyChipYearly => 'Año';

  @override
  String get scheduledPaymentDetailTitle => 'Detalle';

  @override
  String scheduledPaymentDetailNextPayment(String date) {
    return 'Próximo pago: $date';
  }

  @override
  String get scheduledPaymentDetailHistoryTitle => 'Historial';

  @override
  String get scheduledPaymentDetailHistoryEmpty =>
      'Todavía no se ha generado ningún movimiento de este pago programado.';

  @override
  String get scheduledSkippedBadge => 'Omitido';

  @override
  String get scheduledRecoverAction => 'Recuperar';

  @override
  String get scheduledRecoverMessage => 'Pago recuperado';

  @override
  String get scheduledPaymentDetailHeroLabel => 'PRÓXIMO PAGO';

  @override
  String scheduledPaymentDetailRecurrenceOnce(String date) {
    return 'Una sola vez el $date';
  }

  @override
  String scheduledPaymentDetailRecurrenceForever(String unit, String date) {
    return 'Se repite $unit desde el $date, para siempre';
  }

  @override
  String scheduledPaymentDetailRecurrenceUntil(
      String unit, String date, String endDate) {
    return 'Se repite $unit desde el $date, hasta el $endDate';
  }

  @override
  String get scheduledRecurrenceUnitDaily => 'cada día';

  @override
  String scheduledRecurrenceUnitDailyInterval(int interval) {
    return 'cada $interval días';
  }

  @override
  String get scheduledRecurrenceUnitWeekly => 'cada semana';

  @override
  String scheduledRecurrenceUnitWeeklyInterval(int interval) {
    return 'cada $interval semanas';
  }

  @override
  String get scheduledRecurrenceUnitMonthly => 'cada mes';

  @override
  String scheduledRecurrenceUnitMonthlyInterval(int interval) {
    return 'cada $interval meses';
  }

  @override
  String get scheduledRecurrenceUnitYearly => 'cada año';

  @override
  String scheduledRecurrenceUnitYearlyInterval(int interval) {
    return 'cada $interval años';
  }

  @override
  String get scheduledPaymentDetailModeLabel => 'Modo de registro';

  @override
  String get scheduledPaymentDetailModeAutomatic => 'Automático';

  @override
  String get scheduledPaymentDetailModeManual => 'Manual';

  @override
  String get scheduledPaymentDetailAccountLabel => 'Cuenta';

  @override
  String get scheduledPaymentDetailStatusLabel => 'Estado';

  @override
  String get scheduledPaymentDetailStatusActive => 'Activa';

  @override
  String get scheduledPaymentDetailStatusFinished => 'Terminada';

  @override
  String get scheduledPaymentDetailHeroLabelExecuted => 'PAGO EJECUTADO';

  @override
  String get scheduledPaymentDetailConfirmNowCta => 'Confirmar ahora';

  @override
  String get scheduledPaymentDetailConfirmNowError =>
      'No pudimos confirmar este pago ahora. Intenta de nuevo.';

  @override
  String get scheduledPaymentDetailTagsLabel => 'Etiquetas';

  @override
  String get scheduledPaymentDetailTagsEmpty => 'Sin etiquetas';

  @override
  String get scheduledPaymentBridgeTitle => '¿Es un pago programado?';

  @override
  String get scheduledPaymentBridgeMessage =>
      'Elegiste una fecha futura. Un movimiento con fecha futura se registra como pago programado; así se aplica solo cuando llegue el día.';

  @override
  String get scheduledPaymentBridgeAccept => 'Sí, programarlo';

  @override
  String get scheduledPaymentBridgeDecline => 'Cambiar la fecha';

  @override
  String scheduledFinishedCount(int count) {
    return 'Terminados · $count';
  }

  @override
  String get scheduledFinishedCaption =>
      'Ya no generan movimientos. Los que crearon siguen en tus cuentas.';

  @override
  String get scheduledFinishedCardChip => 'Terminada';

  @override
  String get scheduledFinishedErrorTitle =>
      'No pudimos cargar tus pagos terminados';

  @override
  String scheduledFinishedLastPayment(String date) {
    return 'Último pago · $date';
  }

  @override
  String get scheduledPaymentsNoActiveMessage =>
      'Por ahora no tienes pagos programados activos';

  @override
  String scheduledPaymentsNoActiveDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tus $count pagos terminados siguen disponibles en «Terminados».',
      one: 'Tu pago terminado sigue disponible en «Terminados».',
    );
    return '$_temp0';
  }

  @override
  String scheduledPendingCardOverflow(int count) {
    return 'Ver los otros $count pendientes';
  }

  @override
  String scheduledPendingCardTitle(int count) {
    return 'Por confirmar $count';
  }

  @override
  String get scheduledPendingCardCaption => 'Aún no afectan tu saldo';

  @override
  String get scheduledPaymentsEmptyCta => 'Programar un pago';

  @override
  String get scheduledManualNotifyChip => 'Te avisamos';

  @override
  String get scheduledDueToday => 'Vence hoy';

  @override
  String get scheduledDueOneDayAgo => 'hace 1 día';

  @override
  String scheduledDueDaysAgo(int count) {
    return 'hace $count días';
  }

  @override
  String scheduledDueInDays(int count) {
    return 'en $count días';
  }

  @override
  String get scheduledDueInOneDay => 'en 1 día';

  @override
  String scheduledConfirmationSheetScopeNote(String amount) {
    return 'Lo que edites aplica solo a este pago. La plantilla sigue igual y el próximo mes vuelve a proponer $amount.';
  }

  @override
  String scheduledConfirmationSheetAccumulatedTitle(
      int count, String template) {
    return 'Tienes $count pagos de $template sin confirmar';
  }

  @override
  String scheduledConfirmationSheetAccumulatedSub(String date, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'Las otras $others siguen en tu lista.',
      one: 'La otra sigue en tu lista.',
    );
    return 'Ahora confirmas la más antigua, del $date. $_temp0';
  }

  @override
  String get scheduledConfirmationSheetAmountLabel => 'Monto a registrar';

  @override
  String get scheduledConfirmationSheetTransferAmountLabel =>
      'Monto a transferir';

  @override
  String get scheduledConfirmationSheetSourceAccountLabel => 'Cuenta origen';

  @override
  String get scheduledConfirmationSheetTargetAccountLabel => 'Cuenta destino';

  @override
  String get scheduledDetailActionsSheetSubtitle =>
      'Acciones del pago programado';

  @override
  String get scheduledDetailActionsSnooze => 'Posponer este pago';

  @override
  String get scheduledDetailActionsDelete => 'Eliminar pago programado';

  @override
  String get scheduledDetailActionsDeleteInstallment => 'Eliminar cuota';

  @override
  String get scheduledSnoozeSheetSectionTitle => 'Elige la nueva fecha';

  @override
  String get scheduledConfirmationSheetEditTooltip => 'Editar plantilla';

  @override
  String get scheduledGuidedReviewExit => 'Salir';

  @override
  String get scheduledGuidedReviewConfirmNext => 'Confirmar y siguiente';

  @override
  String scheduledSnoozeContextLine(String date) {
    return 'Vencía el $date · muévelo hacia adelante';
  }

  @override
  String get budgetAdjustSheetTitle => 'Ajustar monto';

  @override
  String budgetAdjustCurrentAmountInline(String amount) {
    return 'Actual $amount';
  }

  @override
  String budgetAdjustNewAmountLabel(String range) {
    return 'Nuevo monto · $range';
  }

  @override
  String budgetAdjustExplainer(String resumeDate, String originalAmount) {
    return 'El $resumeDate vuelve a $originalAmount automáticamente.';
  }

  @override
  String get budgetAdjustApplyCta => 'Aplicar cambios';

  @override
  String get budgetAdjustRemoveCta => 'Revertir ajuste';

  @override
  String get budgetAdjustBannerLabel => 'Ajuste de monto';

  @override
  String budgetAdjustBannerSub(String amount, String range) {
    return '$amount · $range';
  }

  @override
  String get budgetAdjustScheduledSnackbar =>
      'Ajuste programado para el período seleccionado.';

  @override
  String get budgetAdjustUpdatedSnackbar => 'Ajuste actualizado.';

  @override
  String get budgetAdjustCancelledSnackbar =>
      'Ajuste revertido — el período vuelve al monto habitual.';

  @override
  String get goalsTitle => 'Metas';

  @override
  String get goalsAdd => 'Nueva meta';

  @override
  String get goalsErrorTitle => 'No pudimos cargar tus metas';

  @override
  String get goalsEmptyMessage => 'Elige algo por lo que ahorrar';

  @override
  String get goalsEmptyDescription =>
      'Dale un propósito a tu dinero. Empieza con una idea o crea la tuya.';

  @override
  String get goalsEmptyTemplatesTitle => 'Empieza con una plantilla';

  @override
  String get goalsEmptyCustomCta => 'Crear meta personalizada';

  @override
  String get goalsArchivedCta => 'Metas archivadas';

  @override
  String get goalsArchivedTitle => 'Metas archivadas';

  @override
  String get goalsArchivedEmptyMessage => 'Aún no has archivado ninguna meta';

  @override
  String get goalsArchivedEmptyDescription =>
      'Cuando termines o pauses una meta, archívala: conserva su progreso y su historial, y sale de tu lista principal.';

  @override
  String goalCoherenceMessage(String amount) {
    return 'Tus metas superan el saldo real de la cuenta por $amount';
  }

  @override
  String goalMomentumStreak(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semanas seguidas',
      one: '1 semana seguida',
    );
    return '$_temp0';
  }

  @override
  String get goalMomentumStreakSub => 'Tu mejor racha aportando. ¡Sigue así!';

  @override
  String get goalMomentumBrokenTitle => 'Retoma tu racha de ahorro';

  @override
  String goalMomentumBrokenSub(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Hace $weeks semanas sin aportar · vuelve cuando quieras',
      one: 'Hace 1 semana sin aportar · vuelve cuando quieras',
    );
    return '$_temp0';
  }

  @override
  String goalMomentumMilestone(int pct, String goalName, String amount) {
    return 'Próximo hito: $pct% en $goalName · faltan $amount';
  }

  @override
  String goalCardRemaining(String amount) {
    return 'Te faltan $amount';
  }

  @override
  String goalCardCompleted(String amount) {
    return 'Ahorraste $amount';
  }

  @override
  String goalCardMeta(int pct) {
    return '$pct% completado';
  }

  @override
  String get goalCardChapterClosed => 'Cumplida · capítulo cerrado';

  @override
  String get goalDetailTitle => 'Meta';

  @override
  String goalDetailRemaining(String amount) {
    return 'Te faltan $amount';
  }

  @override
  String goalDetailAchieved(String amount) {
    return 'Ahorraste $amount';
  }

  @override
  String goalDetailSavedOfTarget(String saved, String target) {
    return '$saved ahorrado de $target';
  }

  @override
  String get goalActionsTooltip => 'Más acciones';

  @override
  String get goalEditTooltip => 'Editar meta';

  @override
  String get goalActionEditSubtitle => 'Nombre, objetivo, fecha o cuenta';

  @override
  String get goalActionArchive => 'Archivar meta';

  @override
  String get goalActionArchiveSubtitle =>
      'Sale de la lista y conserva su historial';

  @override
  String get goalActionUnarchive => 'Desarchivar meta';

  @override
  String get goalActionUnarchiveSubtitle => 'Vuelve a tu lista principal';

  @override
  String get goalActionDeleteLabel => 'Eliminar meta';

  @override
  String get goalActionDeleteSubtitle => 'Va a la papelera; puedes deshacerlo';

  @override
  String get goalRowUnarchive => 'Desarchivar';

  @override
  String get goalRowCompletedBadge => 'Cumplida';

  @override
  String goalRowArchivedOn(String account, String date) {
    return '$account · archivada el $date';
  }

  @override
  String goalRowArchivedOnNoAccount(String date) {
    return 'Archivada el $date';
  }

  @override
  String goalRowTargetOf(String amount) {
    return 'de $amount';
  }

  @override
  String get goalArchiveSheetTitle => '¿Archivar esta meta?';

  @override
  String get goalArchiveSheetMessage =>
      'Se quita de tu lista principal y deja de aceptar nuevos movimientos. Puedes desarchivarla cuando quieras.';

  @override
  String get goalArchiveConfirm => 'Archivar';

  @override
  String get goalUnarchiveSheetTitle => '¿Desarchivar esta meta?';

  @override
  String get goalUnarchiveSheetMessage =>
      'Vuelve a tu lista principal y podrás aportar y retirar de nuevo.';

  @override
  String get goalUnarchiveConfirm => 'Desarchivar';

  @override
  String get goalDeleteSheetTitle => '¿Eliminar esta meta?';

  @override
  String get goalDeleteSheetMessage =>
      'Se mueve a la papelera. Puedes recuperarla mientras no la elimines definitivamente.';

  @override
  String goalMovementsTitle(int count) {
    return 'Movimientos ($count)';
  }

  @override
  String get goalMovementsSectionTitle => 'Movimientos';

  @override
  String get goalMovementsEmpty =>
      'Todavía no registras movimientos en esta meta.';

  @override
  String get goalMovementContribution => 'Aporte';

  @override
  String get goalMovementWithdrawal => 'Retiro';

  @override
  String get goalMovementDateLabel => 'Fecha';

  @override
  String get goalMovementNoteLabel => 'Nota (opcional)';

  @override
  String get goalMovementNoteHint => 'Agregar una nota';

  @override
  String get goalMovementError =>
      'No pudimos guardar el movimiento. Intenta de nuevo.';

  @override
  String goalDateToday(String date) {
    return 'Hoy, $date';
  }

  @override
  String get goalContributeTitle => 'Registrar aporte';

  @override
  String goalContributeTitleWithName(String name) {
    return 'Aportar a $name';
  }

  @override
  String get goalContributeSubtitle => 'Suma a tu progreso de la meta.';

  @override
  String get goalContributeAmountLabel => 'Aporte';

  @override
  String get goalContributeCta => 'Aportar';

  @override
  String get goalWithdrawTitle => 'Registrar retiro';

  @override
  String goalWithdrawTitleWithName(String name) {
    return 'Retirar de $name';
  }

  @override
  String get goalWithdrawSubtitle => 'Sacar dinero de una meta es normal.';

  @override
  String get goalWithdrawAmountLabel => 'Retiro';

  @override
  String get goalMoveFundsToggleLabel => '¿Mover dinero de una cuenta?';

  @override
  String get goalMoveFundsToggleHintContribute =>
      'Solo registra el avance de tu meta; no mueve ninguna cuenta.';

  @override
  String get goalMoveFundsToggleHintWithdraw =>
      'Solo registra el retiro; no toca ninguna cuenta.';

  @override
  String get goalMoveFundsToggleHintContributeOn =>
      'Se crea una transferencia: el saldo de la cuenta de origen baja y el de la meta sube.';

  @override
  String get goalMoveFundsToggleHintContributeOnBudget =>
      'Se crea una transferencia hacia la cuenta de tu meta.';

  @override
  String get goalMoveFundsToggleHintWithdrawOn =>
      'Se crea una transferencia: sale de tu meta y entra a la cuenta de destino.';

  @override
  String get goalContributeSourceAccountLabel => 'Cuenta de origen';

  @override
  String get goalWithdrawDestinationAccountLabel => 'Cuenta de destino';

  @override
  String get goalAccountFieldPlaceholder => 'Elige una cuenta';

  @override
  String get goalBudgetToggleLabel => '¿Incluir en tu presupuesto?';

  @override
  String get goalBudgetToggleHintOff =>
      'No entra en tus presupuestos ni reportes.';

  @override
  String get goalBudgetToggleHintOnContribute =>
      'Cuenta como egreso en la cuenta de origen y como ingreso en la de tu meta.';

  @override
  String get goalBudgetToggleHintOnWithdraw =>
      'Cuenta como ingreso en la cuenta de destino, según tus presupuestos.';

  @override
  String get goalLinkTransactionCta => 'Enlazar un movimiento';

  @override
  String goalLinkBannerTitle(String name) {
    return 'Enlazar a $name';
  }

  @override
  String get goalLinkBannerBody =>
      'Elige un movimiento que ya registraste; lo atribuimos a esta meta, no creamos uno nuevo.';

  @override
  String get goalLinkError =>
      'No pudimos enlazar el movimiento. Intenta de nuevo.';

  @override
  String get goalWithdrawCta => 'Retirar';

  @override
  String get goalAdjustDateCta => 'Ajustar la fecha';

  @override
  String goalWithdrawAvailableLabel(String amount) {
    return 'Disponible en la meta: $amount';
  }

  @override
  String get goalWithdrawUseMaxCta => 'Usar todo';

  @override
  String get goalWithdrawErrorExceedsSaved =>
      'No puedes retirar más de lo que has ahorrado en esta meta.';

  @override
  String get goalQuickAmountLabel => 'APORTE RÁPIDO';

  @override
  String get goalQuickAmountAddCta => 'Nueva';

  @override
  String get goalQuickAmountFieldLabel => 'Monto';

  @override
  String get goalQuickAmountDeletedMessage => 'Aporte rápido eliminado';

  @override
  String get goalQuickAmountUndoAction => 'Deshacer';

  @override
  String get goalNewQuickAmountTitle => 'Nuevo aporte rápido';

  @override
  String get goalNewQuickAmountSubtitle =>
      'Guarda un monto para aportarlo con un toque la próxima vez.';

  @override
  String get goalNewQuickAmountCta => 'Crear chip';

  @override
  String get goalProjectionNoTargetDate => 'Sin fecha objetivo definida';

  @override
  String get goalProjectionOverdue =>
      'La fecha que elegiste ya pasó y tu meta sigue en pie. Ponle una fecha nueva y volvemos a proyectarte la llegada.';

  @override
  String get goalProjectionInsufficientHistory =>
      'Aporta un poco más para ver tu ritmo de ahorro';

  @override
  String goalProjectionMonthlyNeeded(String amount) {
    return 'Necesitas aportar $amount al mes para llegar a tu fecha';
  }

  @override
  String goalProjectionOnPace(String month) {
    return 'A tu ritmo, llegas en $month';
  }

  @override
  String goalMilestoneTitle(int pct) {
    return '¡Llegaste al $pct%!';
  }

  @override
  String goalMilestonePercent(int pct) {
    return '$pct%';
  }

  @override
  String goalMilestoneMessage(String name) {
    return 'Sigue así con $name. Cada aporte te acerca más.';
  }

  @override
  String get goalMilestoneCta => 'Seguir ahorrando';

  @override
  String get goalCompletedBadge => 'Meta cumplida';

  @override
  String goalCompletedTitle(String name) {
    return '¡Cumpliste $name!';
  }

  @override
  String goalCompletedMessage(String amount) {
    return 'Ahorraste $amount en total. Este logro queda contigo.';
  }

  @override
  String get goalCompletedCreateNext => 'Crear la próxima meta';

  @override
  String get goalCompletedArchive => 'Archivar meta';

  @override
  String get goalFormNewTitle => 'Nueva meta';

  @override
  String get goalFormEditTitle => 'Editar meta';

  @override
  String get goalFormTargetLabel => 'Objetivo';

  @override
  String get goalFormErrorTargetZero => 'El objetivo debe ser mayor a cero';

  @override
  String get goalFormNameLabel => 'Nombre';

  @override
  String get goalFormNameHint => 'Ej. Viaje a Cartagena';

  @override
  String get goalFormNameRequired => 'El nombre es obligatorio';

  @override
  String get goalFormAccountLabel => 'Cuenta vinculada (recomendado)';

  @override
  String get goalFormAccountHint => 'Elige una cuenta';

  @override
  String get goalFormAccountPickerTitle => 'Elige una cuenta';

  @override
  String get goalFormTargetDateLabel => 'Fecha objetivo (opcional)';

  @override
  String get goalFormTargetDateHint => 'Elegir una fecha posterior a hoy';

  @override
  String get goalFormErrorTargetDatePast => 'La fecha debe ser posterior a hoy';

  @override
  String get goalFormInitialSavedLabel =>
      '¿Ya tienes algo ahorrado? (opcional)';

  @override
  String get goalFormCreateCta => 'Crear meta';

  @override
  String get goalFormSaveCta => 'Guardar cambios';

  @override
  String get goalCurrencySheetTitle => 'Elige la moneda';

  @override
  String get goalIconSheetTitle => 'Elegir ícono';

  @override
  String get goalIconSheetHint =>
      'El ícono se muestra en un fondo neutro — sin color por meta.';

  @override
  String get goalFormIconAndNameLabel => 'Ícono y nombre';

  @override
  String goalFormCurrencyHintLocked(String account, String currency) {
    return 'La moneda la define la cuenta vinculada ($account, $currency). Cambia la cuenta si necesitas otra moneda.';
  }

  @override
  String get goalFormCurrencyHintUnlocked =>
      'Elige la moneda de tu meta. Si vinculas una cuenta, la moneda se fija a la de esa cuenta.';

  @override
  String get goalFormInitialSavedHint =>
      'Lo guardamos como el primer movimiento del historial, para que tu meta arranque completa.';

  @override
  String goalAccountFilterLabel(String accountName) {
    return 'Metas en $accountName';
  }

  @override
  String get goalAccountFilterClearTooltip => 'Quitar filtro';

  @override
  String get goalCoherenceLink => 'Ver las metas de esta cuenta';

  @override
  String goalDetailSavedOfTargetNoAccount(String saved, String target) {
    return '$saved de $target · sin cuenta vinculada';
  }

  @override
  String get goalDetailAccountUnavailableMessage =>
      'La cuenta que tenías vinculada ya no está disponible. Tu historial sigue completo y esta meta pasa a avance manual.';

  @override
  String get goalDetailAccountUnavailableLink => 'Vincular otra cuenta';

  @override
  String get goalMovementDetailTitle => 'Detalle del movimiento';

  @override
  String get goalMovementDetailHint =>
      'Puedes corregirlo o eliminarlo. Si el movimiento tiene una transferencia detrás, se actualiza junto con él.';

  @override
  String get goalMovementDetailDateLabel => 'Fecha';

  @override
  String get goalMovementDetailOriginAccountLabel => 'Cuenta de origen';

  @override
  String get goalMovementDetailTransferLabel => 'Transferencia';

  @override
  String goalMovementDetailTransferValue(String origin, String destination) {
    return '$origin → $destination';
  }

  @override
  String get goalMovementDetailNoteLabel => 'Nota';

  @override
  String get goalMovementEditTitle => 'Editar movimiento';

  @override
  String get goalMovementEditHint =>
      'Corrige el monto, la fecha o la nota de este movimiento. No crea ni elimina movimientos.';

  @override
  String get goalMovementAmountLabel => 'Monto';

  @override
  String get goalMovementKindContributionLower => 'aporte';

  @override
  String get goalMovementKindWithdrawalLower => 'retiro';

  @override
  String goalDeleteMovementTitle(String kind, String amount) {
    return '¿Eliminar este $kind de $amount?';
  }

  @override
  String goalDeleteMovementMessageTransfer(String origin, String destination) {
    return 'El avance de la meta se recalcula sin él. Como este movimiento tiene una transferencia detrás, esa transferencia también se elimina y los saldos de $origin y $destination vuelven a como estaban.';
  }

  @override
  String goalDeleteMovementMessageManual(String kind) {
    return 'El avance de la meta se recalcula sin él. Este $kind fue un registro manual, así que ninguna de tus cuentas cambia de saldo.';
  }

  @override
  String goalDeleteMovementMessageCompletedTransfer(
      String kind, String goalName, String origin, String destination) {
    return 'Este $kind hace parte de lo que completó $goalName: al eliminarlo, la meta vuelve a estar en curso hasta que la completes de nuevo. La transferencia detrás también se elimina y los saldos de $origin y $destination vuelven a como estaban.';
  }

  @override
  String goalDeleteMovementMessageCompletedManual(
      String kind, String goalName) {
    return 'Este $kind hace parte de lo que completó $goalName: al eliminarlo, la meta vuelve a estar en curso hasta que la completes de nuevo. Fue un registro manual, así que ninguna de tus cuentas cambia de saldo.';
  }

  @override
  String get syncStatusTitle => 'Estado de sincronización';

  @override
  String syncHeroAttentionTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cambios están solo en este teléfono',
      one: '1 cambio está solo en este teléfono',
    );
    return '$_temp0';
  }

  @override
  String syncHeroAttentionKicker(String since) {
    return 'Sin subir a la nube desde $since';
  }

  @override
  String get syncHeroAttentionKickerNever => 'Todavía sin subir a la nube';

  @override
  String syncHeroAttentionBody(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Los tenemos completos aquí. Mientras no suban, la nube no tiene copia de ellos: si cambias de teléfono o reinstalas la app, esos $countString cambios no volverían.',
      one:
          'Lo tenemos completo aquí. Mientras no suba, la nube no tiene copia de él: si cambias de teléfono o reinstalas la app, ese cambio no volvería.',
    );
    return '$_temp0';
  }

  @override
  String get syncHeroStaleTitle => 'Sin contacto con la nube';

  @override
  String get syncHeroStaleBody =>
      'No hay cambios esperando: lo que registraste ya está a salvo en la nube. Pero mientras no haya contacto, lo que registres de ahora en adelante se queda solo en este teléfono.';

  @override
  String get syncHeroSyncedTitle => 'Todo está sincronizado';

  @override
  String get syncHeroSyncedKicker => 'Nada esperando para subir';

  @override
  String get syncHeroSyncedBody =>
      'Tus datos están completos en este teléfono y también hay copia en la nube. Si cambias de teléfono, los recuperas al iniciar sesión.';

  @override
  String get syncHeroNeverTitle => 'Aún no se ha sincronizado';

  @override
  String get syncHeroNeverKicker => 'Acabas de iniciar sesión';

  @override
  String get syncHeroNeverBody =>
      'Tus datos están completos en este teléfono. En cuanto haya conexión suben solos a la nube; no tienes que hacer nada.';

  @override
  String get syncHeroOfflineTitle => 'Sin conexión';

  @override
  String get syncHeroOfflineKicker => 'Se reanuda sola al volver la señal';

  @override
  String get syncHeroOfflineBody =>
      'Tus datos están guardados en este teléfono y no se pierde nada mientras tanto. Lo que falte por subir se sincroniza solo en cuanto vuelva la conexión.';

  @override
  String get syncHeroOfflineCaption =>
      'Se reintentará solo en cuanto haya conexión.';

  @override
  String get syncHeroSignedOutTitle => 'No hay sesión iniciada';

  @override
  String get syncHeroSignedOutKicker => 'Tus datos viven solo en este teléfono';

  @override
  String get syncHeroSignedOutBody =>
      'Todo está completo aquí y la app funciona igual sin cuenta. Lo único que falta es la copia en la nube: sin ella, un cambio de teléfono o una reinstalación no tendrían de dónde recuperar tus datos.';

  @override
  String get syncSignInCta => 'Iniciar sesión';

  @override
  String get syncRetryNowCta => 'Reintentar ahora';

  @override
  String get syncSyncNowCta => 'Sincronizar ahora';

  @override
  String get syncSyncingCta => 'Sincronizando…';

  @override
  String syncLastSyncLabel(String relative) {
    return 'Última sincronización: $relative';
  }

  @override
  String syncLastSuccessfulSyncLabel(String relative) {
    return 'Última sincronización exitosa: $relative';
  }

  @override
  String get syncNeverSyncedLabel => 'Aún no se ha sincronizado';

  @override
  String get syncNoActiveSyncLabel => 'Sin sincronización activa';

  @override
  String syncTimeAgo(String duration) {
    return 'hace $duration';
  }

  @override
  String get syncDurationMoment => 'un momento';

  @override
  String syncDurationMinutes(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String syncDurationHours(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String syncDurationDays(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get syncSectionPending => 'Qué está esperando';

  @override
  String syncSectionPendingLink(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return 'Ver los $countString';
  }

  @override
  String get syncSectionDiagnostics => 'Diagnóstico';

  @override
  String get syncSectionBackupAndDiagnostics => 'Copia y diagnóstico';

  @override
  String get syncSectionMeanwhile => 'Mientras tanto';

  @override
  String get syncSaveCopyTitle => 'Guardar una copia';

  @override
  String get syncSaveCopyDescription =>
      'Un archivo con todo lo tuyo, listo para volver a cargarlo.';

  @override
  String syncSaveCopyDescriptionAttention(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Esos $countString cambios viven solo aquí. Una copia los pone a salvo.',
      one: 'Ese cambio vive solo aquí. Una copia lo pone a salvo.',
    );
    return '$_temp0';
  }

  @override
  String get syncSaveCopyDescriptionStale =>
      'Lo que registres desde ahora se queda aquí hasta que vuelva el contacto. Una copia lo pone a salvo.';

  @override
  String get syncSaveCopyDescriptionSignedOut =>
      'Sin cuenta, un archivo de copia es la única forma de no depender de este teléfono.';

  @override
  String get syncSaveCopyChip => 'Restaurable en la app';

  @override
  String get syncTechnicalLogTitle => 'Registro técnico';

  @override
  String get syncTechnicalLogSubtitle =>
      'Para enviarlo a soporte si hace falta';

  @override
  String get syncExportExcelTitle => 'Exportar a Excel';

  @override
  String get syncExportExcelSubtitle => 'Para verlos en una hoja de cálculo';

  @override
  String get syncPendingListTitle => 'Cambios sin subir';

  @override
  String syncPendingListSummary(num count, String since) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cambios esperando · el más antiguo, desde $since',
      one: '1 cambio esperando · desde $since',
    );
    return '$_temp0';
  }

  @override
  String syncPendingRowTitle(String kind, String label) {
    return '$kind · $label';
  }

  @override
  String syncPendingRowMeta(num attempts, String date) {
    final intl.NumberFormat attemptsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String attemptsString = attemptsNumberFormat.format(attempts);

    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'Pendiente desde el $date · $attemptsString intentos',
      one: 'Pendiente desde el $date · 1 intento',
    );
    return '$_temp0';
  }

  @override
  String get syncEntityTransaction => 'Movimiento';

  @override
  String get syncEntityAccount => 'Cuenta';

  @override
  String get syncEntityBudget => 'Presupuesto';

  @override
  String get syncEntityGoal => 'Meta';

  @override
  String get syncEntityGoalContribution => 'Aporte a meta';

  @override
  String get syncEntityDebt => 'Deuda';

  @override
  String get syncEntityDebtEntry => 'Pago de deuda';

  @override
  String get syncEntityScheduledPayment => 'Pago programado';

  @override
  String get syncEntityCategory => 'Categoría';

  @override
  String get syncEntityTag => 'Etiqueta';

  @override
  String get syncEntitySettings => 'Ajustes';

  @override
  String get syncEntityOther => 'Cambio';

  @override
  String syncDetailWaiting(String duration) {
    return 'Lleva $duration esperando';
  }

  @override
  String syncDetailAttempts(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString intentos de subida',
      one: '1 intento de subida',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailRisk =>
      'La nube todavía no tiene copia de este cambio: si reinstalas la app o cambias de teléfono, no volvería.';

  @override
  String get syncDetailRetry => 'Reintentar';

  @override
  String get syncPendingEmptyMessage => 'Nada esperando para subir';

  @override
  String get syncPendingEmptyDescription =>
      'Todo lo que registraste ya llegó a la nube.';

  @override
  String syncLogSheetSubtitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Últimas $countString líneas · útil para soporte',
      one: 'Última línea · útil para soporte',
      zero: 'Aún no hay líneas · nada que reportar',
    );
    return '$_temp0';
  }

  @override
  String get syncLogPrivacyNote =>
      'El registro no incluye montos ni los nombres de tus movimientos: solo fechas, códigos y reintentos.';

  @override
  String get syncLogEmpty => 'Todavía no hay nada registrado.';

  @override
  String get syncLogCopy => 'Copiar';

  @override
  String get syncLogShare => 'Compartir';

  @override
  String get syncLogShareSubject => 'Registro de sincronización de Billetudo';

  @override
  String get syncLogCopied => 'Registro copiado';

  @override
  String syncRetrySuccess(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Todo al día · $countString cambios subidos',
      one: 'Todo al día · 1 cambio subido',
    );
    return '$_temp0';
  }

  @override
  String get syncRetryPartial =>
      'No se pudo subir todo. Sigue guardado en este teléfono.';

  @override
  String get syncRetryPartialAction => 'Ver detalle';

  @override
  String get homeSyncAttention => 'Cambios sin subir';

  @override
  String homeSyncSheetStalledTitle(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString cambios están solo en este teléfono',
      one: '1 cambio está solo en este teléfono',
    );
    return '$_temp0';
  }

  @override
  String get homeSyncSheetStalledMessage =>
      'No pudimos guardarlos en la nube. Aquí están completos, pero la nube todavía no tiene copia de ellos.';

  @override
  String get homeSyncSheetStaleTitle => 'Sin contacto con la nube';

  @override
  String homeSyncSheetStaleMessage(String duration) {
    return 'No hay cambios pendientes: lo que registraste ya está a salvo en la nube. Pero llevamos $duration sin conectar, así que lo que registres de ahora en adelante se queda solo en este teléfono.';
  }

  @override
  String get homeSyncSheetTooLongTitle => 'La sincronización está tardando';

  @override
  String homeSyncSheetTooLongMessage(String duration) {
    return 'Llevamos $duration intentando subir tus cambios. En este teléfono no falta nada; lo que aún no ocurre es la copia en la nube.';
  }

  @override
  String get homeSyncSheetDetails => 'Ver detalles';

  @override
  String get settingsSyncStatus => 'Estado de sincronización';

  @override
  String get importExportHubTitle => 'Importar y exportar';

  @override
  String get importExportHubErrorTitle => 'No pudimos cargar esta pantalla';

  @override
  String get importExportHeroTitle => 'Guardar una copia de tus datos';

  @override
  String get importExportHeroKicker => 'Un archivo .billetudo.json';

  @override
  String get importExportCloudNote =>
      'Es distinto al respaldo en la nube: esta copia queda en tu dispositivo y no necesita cuenta.';

  @override
  String get importExportHeroBody =>
      'Movimientos, cuentas, presupuestos, metas, deudas y pagos programados en un solo archivo tuyo. Si cambias de teléfono, la app lo vuelve a cargar tal cual.';

  @override
  String importExportCopyStatusLastSaved(String date) {
    return 'Última copia: $date';
  }

  @override
  String get importExportCopyStatusNeverSaved =>
      'Aún no has guardado una copia';

  @override
  String get importExportSaveCopyCta => 'Guardar una copia';

  @override
  String get importExportPrivacyNote =>
      'La copia se guarda sin cifrar y sin el número de cuenta. Tú eliges dónde la guardas.';

  @override
  String get importExportSectionOtherActions => 'Exportar e importar';

  @override
  String get importExportExportCsvTitle => 'Exportar a CSV';

  @override
  String get importExportExportPageTitle => 'Exportar tus datos';

  @override
  String get importExportExportCsvSubtitle =>
      'Para Excel o Sheets · no restaura la app';

  @override
  String get importExportImportCsvTitle => 'Importar desde un CSV';

  @override
  String get importExportImportCsvSubtitle =>
      'Tu banco, Wallet, Mint o cualquier archivo';

  @override
  String get importExportRestoreTitle => 'Restaurar desde una copia';

  @override
  String get importExportRestoreSubtitle =>
      'Vuelve a cargar un archivo .billetudo.json';

  @override
  String get importExportSectionRecentImports => 'Importaciones recientes';

  @override
  String get importExportSeeAll => 'Ver todas';

  @override
  String importExportBatchMeta(int count, String relative) {
    return '$count movimientos · $relative';
  }

  @override
  String get importExportBatchRevertedBadge => 'Revertida';

  @override
  String importExportRelativeDays(int n) {
    return 'hace $n días';
  }

  @override
  String importExportRelativeHours(int n) {
    return 'hace $n horas';
  }

  @override
  String get importExportRelativeJustNow => 'hace un momento';

  @override
  String get importExportEmptyHeroTitle => 'Trae tu historial';

  @override
  String get importExportEmptyHeroBody =>
      'Importa un CSV de Wallet, Mint o tu banco y tú decides qué es cada columna. Si vienes de otro teléfono, restaura tu copia y vuelve todo tal cual.';

  @override
  String get importExportEmptyImportCta => 'Importar un CSV';

  @override
  String get importExportSectionOtherOptions => 'Otras opciones';

  @override
  String get importExportEmptyExportRowTitle => 'Exportar y guardar copias';

  @override
  String get importExportEmptyExportRowSubtitle =>
      'Se activan con tu primer movimiento. Ahí podrás sacar un CSV o guardar una copia con todo. Es distinto al respaldo en la nube: la copia queda en tu dispositivo.';

  @override
  String get importExportExportEmptyTitle =>
      'Todavía no tienes movimientos para exportar';

  @override
  String get importExportExportEmptyBody =>
      'En cuanto registres tu primer movimiento, podrás exportarlo.';

  @override
  String get importExportScopeTransactions => 'Transacciones';

  @override
  String get importExportScopeTransactionsHint =>
      'Incluye tus movimientos en el archivo';

  @override
  String get importExportScopeAccounts => 'Cuentas';

  @override
  String get importExportScopeAccountsHint =>
      'Incluye tu estructura de cuentas';

  @override
  String get importExportScopeCategories => 'Categorías';

  @override
  String get importExportScopeCategoriesHint =>
      'Incluye tu estructura de categorías';

  @override
  String get importExportAllHistory => 'Todo el histórico';

  @override
  String get importExportAllHistoryHint =>
      'Ignora el filtro de fechas y exporta todo';

  @override
  String get importExportPickDateRange => 'Elegir rango de fechas';

  @override
  String get importExportZipNotice =>
      'Al elegir más de uno, se entrega un solo archivo .zip.';

  @override
  String get importExportExportCta => 'Exportar';

  @override
  String get importExportFiltersTitle => 'Filtros de transacciones';

  @override
  String get importExportFiltersSubtitle =>
      'Solo aplican si exportas Transacciones.';

  @override
  String get importExportFilterSearchPlaceholder => 'Buscar por texto';

  @override
  String get importExportFilterAllAccounts => 'Todas las cuentas';

  @override
  String get importExportProgressExportingTitle => 'Exportando tus datos…';

  @override
  String get importExportProgressImportingTitle =>
      'Importando tus movimientos…';

  @override
  String get importExportProgressRestoringTitle => 'Restaurando tu copia…';

  @override
  String get importExportProgressSavingCopyTitle => 'Guardando tu copia…';

  @override
  String importExportProgressCaption(int processed, int total) {
    return '$processed de $total filas';
  }

  @override
  String get importExportProgressHint =>
      'No cierres la app mientras esto termina. Puedes cancelar sin perder lo que ya tenías.';

  @override
  String get importExportIoErrorWriteTitle => 'No pudimos guardar el archivo';

  @override
  String get importExportIoErrorWriteBody =>
      'Puede ser falta de espacio o de permiso para escribir en tu dispositivo. Eliminamos el archivo parcial para no dejar nada a medias — tus datos en la app están a salvo.';

  @override
  String get importExportIoErrorUnreadableTitle =>
      'No pudimos leer este archivo';

  @override
  String get importExportIoErrorUnreadableBody =>
      'No parece un CSV válido, o está vacío. Prueba exportarlo otra vez desde tu banco o la otra app. Tus datos en Billetudo siguen intactos.';

  @override
  String get importExportChooseAnotherFile => 'Elegir otro archivo';

  @override
  String get importExportSelectFileTitle => 'Selecciona tu archivo CSV';

  @override
  String get importExportSelectFileBody =>
      'Acepta cualquier CSV: tú decides qué es cada columna en el siguiente paso.';

  @override
  String get importExportSelectFileCta => 'Elegir archivo';

  @override
  String get importExportStepMapping => 'Mapeo de columnas';

  @override
  String get importExportStepDestinations => 'Resolver destinos';

  @override
  String get importExportStepPreview => 'Vista previa';

  @override
  String get importExportStepSummary => 'Resumen';

  @override
  String importExportTemplateMatched(String name) {
    return 'Reconocimos el formato de \"$name\" — confirma para continuar';
  }

  @override
  String get importExportFieldNotUsed => 'No usar';

  @override
  String get importExportFieldRequired => 'Obligatorio';

  @override
  String get importExportFieldOptional => 'Opcional';

  @override
  String importExportFieldPreview(String value) {
    return 'Vista previa: $value';
  }

  @override
  String get importExportFormatDetectedTitle => 'Formato detectado';

  @override
  String get importExportFormatDateLabel => 'Formato de fecha';

  @override
  String get importExportFormatDecimalLabel => 'Convención decimal';

  @override
  String get importExportFormatSignLabel => 'Gasto o ingreso se expresa con';

  @override
  String get importExportDateOrderYmd => 'AAAA/MM/DD';

  @override
  String get importExportDateOrderDmy => 'DD/MM/AAAA';

  @override
  String get importExportDateOrderMdy => 'MM/DD/AAAA';

  @override
  String get importExportDecimalDot => '1.234,56 → 1234.56 (punto decimal)';

  @override
  String get importExportDecimalComma => '1.234,56 (coma decimal)';

  @override
  String get importExportSignByTypeColumn => 'Columna tipo (ingreso o gasto)';

  @override
  String get importExportSignByAmountSign =>
      'Signo del monto (negativo = gasto)';

  @override
  String get importExportLivePreviewLabel => 'Así queda tu primera fila real';

  @override
  String get importExportFieldsSectionTitle => 'Campos';

  @override
  String get importExportFieldPickerTitle => '¿Qué campo es esta columna?';

  @override
  String get importExportFieldId => 'Id';

  @override
  String get importExportFieldDate => 'Fecha';

  @override
  String get importExportFieldAmount => 'Monto';

  @override
  String get importExportFieldType => 'Tipo';

  @override
  String get importExportFieldCurrency => 'Moneda';

  @override
  String get importExportFieldAccount => 'Cuenta';

  @override
  String get importExportFieldTransferAccount => 'Cuenta destino';

  @override
  String get importExportFieldCategory => 'Categoría';

  @override
  String get importExportFieldSubcategory => 'Subcategoría';

  @override
  String get importExportFieldNote => 'Nota';

  @override
  String get importExportFieldTags => 'Etiquetas';

  @override
  String get importExportDestinationsNoneTitle =>
      'Todo coincide con lo que ya tienes';

  @override
  String get importExportDestinationsAllInvalidTitle =>
      'Nada por resolver todavía';

  @override
  String importExportDestinationsAllInvalidBody(int count) {
    return 'Ninguna de las $count filas se pudo leer con el mapeo actual — revisa el paso anterior antes de seguir.';
  }

  @override
  String get importExportDestinationsReviewMappingCta => 'Revisar mapeo';

  @override
  String get importExportMappingModeAutomatic => 'Automático';

  @override
  String get importExportMappingModeManual => 'Manual';

  @override
  String get importExportMappingModeAutoSummaryTitle =>
      'Así vamos a leer tu archivo';

  @override
  String get importExportMappingModeAutoConfirmCta => 'Confirmar mapeo';

  @override
  String get importExportMappingModeAutoIncompleteHint =>
      'Nos falta identificar fecha, monto o cuenta — cambia a Manual para mapearlos.';

  @override
  String get importExportDateFormatOptionIso => 'AAAA-MM-DD';

  @override
  String get importExportDateFormatOptionDmySlash => 'DD/MM/AAAA';

  @override
  String get importExportDateFormatOptionDmyDash => 'DD-MM-AAAA';

  @override
  String get importExportDateFormatOptionDmyDot => 'DD.MM.AAAA';

  @override
  String get importExportDateFormatOptionMdySlash => 'MM/DD/AAAA';

  @override
  String get importExportDateFormatOptionMdyDash => 'MM-DD-AAAA';

  @override
  String get importExportDateFormatOptionMdyDot => 'MM.DD.AAAA';

  @override
  String importExportDateFormatPreviewUnreadable(String value) {
    return '\"$value\" no se pudo leer con este formato';
  }

  @override
  String get importExportTypeValuesResultIncome =>
      'Esta fila se leería como ingreso';

  @override
  String get importExportTypeValuesResultExpense =>
      'Esta fila se leería como gasto';

  @override
  String get importExportTypeValuesResultTransfer =>
      'Esta fila se leería como transferencia';

  @override
  String get importExportTypeValuesResultNoMatch =>
      'No pudimos clasificar tu primera fila con estos valores';

  @override
  String get importExportTypeValuesIncomeLabel =>
      'Valor que significa \"ingreso\"';

  @override
  String get importExportTypeValuesExpenseLabel =>
      'Valor que significa \"gasto\"';

  @override
  String get importExportTypeValuesTransferLabel =>
      'Valor que significa \"transferencia\"';

  @override
  String get importExportDestinationNotFound => 'No existe todavía en tu app';

  @override
  String get importExportDestinationCreateNew => 'Crear nueva';

  @override
  String get importExportDestinationMapExisting => 'Mapear a existente';

  @override
  String get importExportDestinationsPickerEmpty => 'Todavía no tienes ninguna';

  @override
  String get importExportDestinationsSectionAccounts => 'Cuentas';

  @override
  String get importExportDestinationsSectionCategories => 'Categorías';

  @override
  String get importExportDestinationsSectionTags => 'Etiquetas';

  @override
  String get importExportDestinationsNewAccountsNote =>
      'Las cuentas que crees aquí empiezan en \$0 y tipo Otra — su saldo real se reconstruye con las transacciones que importes.';

  @override
  String get importExportStatRead => 'leídas';

  @override
  String get importExportStatWillImport => 'a importar';

  @override
  String get importExportStatDuplicates => 'repetidos';

  @override
  String get importExportStatErrors => 'inválidas';

  @override
  String get importExportOmitAllDuplicates => 'Omitir todos';

  @override
  String get importExportIncludeAllDuplicates => 'Importar todos';

  @override
  String get importExportDuplicateExact => 'Ya está importada';

  @override
  String get importExportDuplicateProbable =>
      'Posible duplicado: mismo monto y fecha';

  @override
  String importExportInvalidRowsCount(int n) {
    return 'Ver $n filas con error';
  }

  @override
  String importExportRowNumber(int n) {
    return 'Fila $n';
  }

  @override
  String get importExportIssueMissingAccount => 'Falta la cuenta';

  @override
  String get importExportIssueMissingDate => 'Falta la fecha';

  @override
  String get importExportIssueInvalidDate => 'Fecha no reconocida';

  @override
  String get importExportIssueMissingAmount => 'Falta el monto';

  @override
  String get importExportIssueInvalidAmount => 'Monto no reconocido';

  @override
  String get importExportIssueInvalidType => 'Tipo no reconocido';

  @override
  String get importExportConfirmImportCta => 'Confirmar importación';

  @override
  String importExportImportRowsCta(int count) {
    return 'Importar $count movimientos';
  }

  @override
  String importExportDuplicatesSectionTitle(int count) {
    return 'Posibles duplicados ($count)';
  }

  @override
  String get importExportSaveTemplateToggleLabel =>
      'Guardar esta plantilla de mapeo';

  @override
  String get importExportSaveTemplateToggleHint =>
      'La usarás con un toque la próxima vez que importes de este mismo origen.';

  @override
  String get importExportSaveTemplateNameLabel => 'Nombre de la plantilla';

  @override
  String get importExportSaveTemplateNameHint => 'Ej. Bancolombia CSV';

  @override
  String get importExportSummaryTitle => 'Importación completa';

  @override
  String importExportSummarySubtitle(String fileName) {
    return '$fileName se procesó y ya está disponible en tus movimientos.';
  }

  @override
  String get importExportSummaryImported => 'Importadas';

  @override
  String get importExportSummarySkippedDuplicate => 'Omitidas por duplicado';

  @override
  String get importExportSummarySkippedError => 'Omitidas por error';

  @override
  String get importExportSummaryAccountsCreated => 'Cuentas creadas';

  @override
  String get importExportSummaryCategoriesCreated => 'Categorías creadas';

  @override
  String get importExportSummaryTagsCreated => 'Etiquetas creadas';

  @override
  String get importExportSummarySeeSkipped => 'Ver omitidas';

  @override
  String importExportSummarySeeSkippedWithCount(int count) {
    return 'Ver $count omitidas y por qué';
  }

  @override
  String get importExportSkippedSheetTitle => 'Lo que no se importó';

  @override
  String importExportSkippedDuplicateReason(int count) {
    return '$count por posible duplicado: mismo id, o mismo monto y fecha, que un movimiento que ya tenías.';
  }

  @override
  String importExportSkippedErrorReason(int count) {
    return '$count por un dato que no pudimos leer: fecha, monto o cuenta incompletos o inválidos en el archivo.';
  }

  @override
  String get importExportBatchesTitle => 'Importaciones';

  @override
  String get importExportBatchesErrorTitle =>
      'No pudimos cargar tus importaciones';

  @override
  String get importExportBatchesEmptyTitle => 'Aún no has importado nada';

  @override
  String get importExportBatchesEmptyBody =>
      'Cuando importes un archivo, aparecerá aquí.';

  @override
  String get importExportUndoConfirmTitle => '¿Deshacer esta importación?';

  @override
  String importExportUndoConfirmBody(String file, int count) {
    return 'Se quitarán las $count filas que trajo \"$file\". Lo que sigas usando fuera de esta importación se conserva.';
  }

  @override
  String get importExportUndoConfirmCta => 'Deshacer importación';

  @override
  String get importExportUndoConfirmKeepNote =>
      'Las cuentas y categorías que creó esta importación se conservan al deshacerla — solo se eliminan las transacciones que trajo.';

  @override
  String get importExportRestorePickFileBody =>
      'Elige un archivo .billetudo.json para ver qué trae antes de restaurar nada.';

  @override
  String get importExportRestorePickFileCta => 'Elegir archivo';

  @override
  String importExportRestoreSummaryTitle(String date) {
    return 'Copia del $date';
  }

  @override
  String get importExportRestoreSheetTitle => 'Restaurar copia';

  @override
  String importExportRestoreSheetSubtitle(
      String date, int version, String appVersion) {
    return 'Copia del $date · versión $version · creada con Billetudo $appVersion';
  }

  @override
  String importExportRestoreRowCounts(int n) {
    return 'Trae $n filas en total';
  }

  @override
  String get importExportRestoreStatAccounts => 'cuentas';

  @override
  String get importExportRestoreStatCategories => 'categorías';

  @override
  String get importExportRestoreStatTransactions => 'movimientos';

  @override
  String get importExportRestoreStatBudgets => 'presupuestos';

  @override
  String get importExportRestoreStatGoals => 'metas';

  @override
  String get importExportRestoreStatDebts => 'deudas';

  @override
  String get importExportRestoreChoiceLabel =>
      '¿Qué hacemos con tus datos actuales?';

  @override
  String get importExportRestoreChoiceHint =>
      'Fusionar combina por id: lo nuevo se crea, lo existente se actualiza. Reemplazar todo borra tus datos actuales (y los de la nube, si tienes sesión) y deja solo el contenido de la copia.';

  @override
  String get importExportReplaceAllConfirmTitle =>
      'Esta acción no se puede deshacer';

  @override
  String importExportReplaceAllConfirmBody(String date) {
    return 'Vas a reemplazar TODOS tus datos actuales por los de la copia del $date. Si tienes sesión iniciada, esto también borra tus datos en la nube.';
  }

  @override
  String get importExportRestoreModeMerge => 'Fusionar';

  @override
  String get importExportRestoreModeMergeHint =>
      'Combina con lo que ya tienes. No duplica si repites la restauración.';

  @override
  String get importExportRestoreModeReplace => 'Reemplazar todo';

  @override
  String get importExportRestoreCta => 'Restaurar';

  @override
  String get importExportRestoreModeReplaceHint =>
      'Borra tus datos locales y deja exactamente lo que trae la copia. Irreversible.';

  @override
  String get importExportReplaceAllAck =>
      'Entiendo que esto borra mis datos actuales, incluida la nube si tengo sesión iniciada, y no se puede deshacer.';

  @override
  String get importExportRestoreConfirmMergeCta => 'Restaurar y fusionar';

  @override
  String get importExportRestoreConfirmReplaceCta => 'Reemplazar todo';

  @override
  String get importExportRestoreErrorTitle => 'No pudimos validar este archivo';

  @override
  String get importExportRestoreErrorBody =>
      'Puede que no sea una copia de Billetudo o que sea de una versión más nueva. Tus datos en la app siguen intactos.';

  @override
  String get importExportRestoreExecutionErrorTitle =>
      'No pudimos completar la restauración';

  @override
  String get importExportRestoreExecutionErrorBody =>
      'El archivo era válido, pero algo falló a mitad de camino. La restauración se cancela por completo cuando eso pasa — tus datos actuales no se modificaron. Intenta de nuevo.';

  @override
  String get importExportRestoreDoneTitle => 'Restauración completa';

  @override
  String get importExportRestoreCreated => 'creadas';

  @override
  String get importExportRestoreUpdated => 'actualizadas';

  @override
  String get importExportRestoreSkipped => 'omitidas';

  @override
  String get reportsTabSummary => 'Resumen';

  @override
  String get reportsTabCashflow => 'Flujo';

  @override
  String get reportsTabNetWorth => 'Patrimonio';

  @override
  String get reportsTabCategories => 'Categorías';

  @override
  String reportsPeriodLastMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Últimos $count meses',
      one: 'Último mes',
    );
    return '$_temp0';
  }

  @override
  String reportsPeriodDaysWithData(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días con datos',
      one: '$count día con datos',
    );
    return '$_temp0';
  }

  @override
  String reportsPeriodSinceDate(String date) {
    return 'Desde el $date';
  }

  @override
  String get reportsPeriodSheetTitle => 'Filtrar periodo';

  @override
  String get reportsPeriodGranularityMonth => 'Mes';

  @override
  String get reportsPeriodGranularityYear => 'Año';

  @override
  String get reportsPeriodClear => 'Limpiar';

  @override
  String get reportsCashflowCardTitle => 'Flujo de caja';

  @override
  String get reportsCashflowCardSubtitle => 'Ingresos vs. gastos, mes a mes';

  @override
  String get reportsCashflowIncomeLabel => 'Ingresos';

  @override
  String get reportsCashflowExpenseLabel => 'Gastos';

  @override
  String get reportsCashflowDebtLegendLabel => 'Movimientos de deuda';

  @override
  String reportsCashflowPositiveLabel(String periodPhrase) {
    return 'Ahorraste en $periodPhrase';
  }

  @override
  String reportsCashflowNegativeLabel(String periodPhrase) {
    return 'Balance de $periodPhrase';
  }

  @override
  String reportsCashflowShortHistoryLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Balance de tus primeros $count días',
      one: 'Balance de tu primer día',
    );
    return '$_temp0';
  }

  @override
  String reportsCashflowPeriodPhraseLastMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'los últimos $count meses',
      one: 'el último mes',
    );
    return '$_temp0';
  }

  @override
  String get reportsCashflowPeriodPhraseGeneric => 'el periodo seleccionado';

  @override
  String reportsCashflowNegativeExplainer(String amount, String periodPhrase) {
    return 'Salió $amount más de lo que entró en $periodPhrase. Abajo puedes ver qué meses pesaron más.';
  }

  @override
  String get reportsCashflowViewCategoriesLink => 'Ver en qué se fue';

  @override
  String reportsCashflowCurrentMonthNote(String month, int day) {
    return '$month va en curso: llega hasta el $day.';
  }

  @override
  String get reportsCashflowDebtToggleLabel => 'Separar movimientos de deuda';

  @override
  String get reportsCashflowDebtToggleHint =>
      'Se muestran como una serie aparte, nunca se ocultan.';

  @override
  String get reportsCashflowShortHistoryNote =>
      'Ajustamos la vista a los días que ya registraste. Cuando completes tu primer mes, verás la comparación mes a mes.';

  @override
  String get reportsNetWorthCardTitle => 'Patrimonio';

  @override
  String get reportsNetWorthCaption =>
      'El líquido es lo que puedes usar hoy. El total resta lo que debes y suma lo que te deben.';

  @override
  String get reportsNetWorthLegendLiquid => 'Patrimonio líquido';

  @override
  String get reportsNetWorthLegendTotal => 'Patrimonio total';

  @override
  String get reportsNetWorthFigureLiquidLabel => 'Líquido';

  @override
  String get reportsNetWorthFigureTotalLabel => 'Total';

  @override
  String get reportsNetWorthInterestNote =>
      'El interés de una deuda baja tu patrimonio, pero no aparece en Flujo: no es plata que salió de una cuenta.';

  @override
  String get reportsNetWorthArchivedToggleLabel => 'Incluir cuentas archivadas';

  @override
  String get reportsNetWorthArchivedToggleHint =>
      'Hoy quedan fuera de las dos cifras.';

  @override
  String reportsNetWorthSubtitle(String from, String to, String currency) {
    return 'Del cierre de $from al $to · $currency';
  }

  @override
  String get reportsCategoriesCardTitle => 'Estructura de gasto';

  @override
  String reportsCategoriesSubtitle(
      int count, String range, String isSubcategory) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subcategorías · $range',
      one: '$count subcategoría · $range',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorías · $range',
      one: '$count categoría · $range',
    );
    String _temp2 = intl.Intl.selectLogic(
      isSubcategory,
      {
        'true': '$_temp0',
        'other': '$_temp1',
      },
    );
    return '$_temp2';
  }

  @override
  String reportsCategoriesTopLabel(String name, int pct) {
    return 'Mayor gasto: $name · $pct%';
  }

  @override
  String get reportsCategoriesUncategorized => 'Sin categoría';

  @override
  String get reportsCategoriesViewSubcategories => 'Profundizar';

  @override
  String get reportsCategoriesBack => 'Atrás';

  @override
  String reportsCategoriesMovementsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movimientos',
      one: '$count movimiento',
    );
    return '$_temp0';
  }

  @override
  String get reportsDashboardBudgetsTitle => 'Presupuestos';

  @override
  String reportsDashboardBudgetsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count presupuestos activos · ciclos propios',
      one: '$count presupuesto activo · ciclos propios',
    );
    return '$_temp0';
  }

  @override
  String get reportsDashboardGoalsTitle => 'Metas';

  @override
  String reportsDashboardGoalsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count metas en curso',
      one: '$count meta en curso',
    );
    return '$_temp0';
  }

  @override
  String reportsGoalSummaryAmountOfTarget(String saved, String target) {
    return '$saved de $target';
  }

  @override
  String get reportsDashboardBudgetsEmptySubtitle =>
      'Aún no has creado ninguno';

  @override
  String get reportsDashboardBudgetsEmptyMessage =>
      'Cuando crees un presupuesto, aquí verás cuánto te queda del ciclo.';

  @override
  String get reportsDashboardGoalsEmptySubtitle => 'Aún no has creado ninguna';

  @override
  String get reportsDashboardGoalsEmptyMessage =>
      'Tus metas de ahorro mostrarán su avance aquí, todas juntas.';

  @override
  String get reportsDashboardCrossLinkDebts => 'Ver el avance de tus deudas';

  @override
  String reportsDashboardHeroBudgetsAvailable(String amount) {
    return '$amount disponibles';
  }

  @override
  String reportsDashboardHeroGoalsSaved(String amount) {
    return '$amount ahorrados';
  }

  @override
  String get reportsEmptyTitle => 'Aún no hay movimientos en este periodo';

  @override
  String get reportsEmptyMessage =>
      'Registra un gasto o un ingreso y aquí verás cómo se mueve tu plata mes a mes.';

  @override
  String get reportsSyncNoticeMessage =>
      'Hay cambios sin sincronizar. Lo que ves aquí está completo y guardado en tu teléfono.';

  @override
  String get reportsExportTooltip => 'Exportar como imagen';

  @override
  String get reportsExportError =>
      'No pudimos exportar la gráfica. Intenta de nuevo.';

  @override
  String reportsExportShareText(String title) {
    return 'Gráfica de $title — billetudo';
  }

  @override
  String get reportsChartSkeletonLoadingLabel => 'Cargando gráfica';

  @override
  String get accountTypeSheetTitle => 'Selecciona el tipo de cuenta';

  @override
  String get onboardingWelcomeHeadline =>
      'Todo lo esencial. Gratis. Para siempre.';

  @override
  String get onboardingWelcomeSubhead =>
      'Tus datos viven en tu teléfono. El respaldo en la nube es opcional.';

  @override
  String get onboardingWelcomeCaption =>
      'Ya dejamos categorías listas para ti.';

  @override
  String get onboardingWelcomeCta => 'Comenzar';

  @override
  String get onboardingAlreadyHaveAccount => 'Ya tengo cuenta';

  @override
  String get onboardingAccountHeadline => 'Crea tu primera cuenta';

  @override
  String get onboardingAccountSubhead =>
      'Empieza con esta sugerencia o cámbiala a tu gusto.';

  @override
  String get onboardingAccountDefaultName => 'Ahorros';

  @override
  String get onboardingAccountCta => 'Crear cuenta';

  @override
  String get onboardingAccountSkip => 'Omitir por ahora';

  @override
  String get onboardingBackupHeadline => 'Respalda tus datos, cuando quieras';

  @override
  String get onboardingBackupBody =>
      'Hoy tus datos viven solo en este teléfono. El respaldo es gratis y los guarda en la nube, listos para recuperarlos si cambias de equipo o reinstalas — sin él, se quedan únicamente aquí.';

  @override
  String get onboardingBackupFootnote =>
      'Actívalo luego en Ajustes → Respaldar.';

  @override
  String get onboardingBackupCta => 'Activar respaldo';

  @override
  String get onboardingBackupSkip => 'Después';

  @override
  String get onboardingClosingHeadline => 'Tu billetera está lista';

  @override
  String get onboardingClosingSubheadWithAccount =>
      'Registra tu primer movimiento y empieza a tomar el control de tu dinero.';

  @override
  String get onboardingClosingSubheadNoAccount =>
      'Para registrar movimientos necesitas una cuenta. Crea la primera en un momento.';

  @override
  String get onboardingClosingCtaTransaction => 'Registra tu primer movimiento';

  @override
  String get onboardingClosingCtaAccount => 'Crea tu primera cuenta';

  @override
  String get onboardingClosingSkip => 'Lo hago después';
}
