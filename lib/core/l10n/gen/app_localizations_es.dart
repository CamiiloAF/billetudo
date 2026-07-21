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
  String get commonBack => 'Atrás';

  @override
  String get commonMoreActions => 'Más opciones';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonDone => 'Listo';

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
  String get transactionFormTransferInfo =>
      'Las transferencias no cuentan como gasto ni ingreso.';

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
  String get moreScheduledPayments => 'Pagos programados';

  @override
  String get moreScheduledPaymentsDescription => 'Pagos e ingresos automáticos';

  @override
  String get moreReports => 'Gráficas e informes';

  @override
  String get moreReportsDescription => 'Visualiza tus finanzas con gráficas';

  @override
  String get moreImportExport => 'Importar y exportar';

  @override
  String get moreImportExportDescription => 'Respalda o trae tus datos';

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
  String get budgetScheduledSheetTitle => 'Pagos programados del período';

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
  String get budgetLoadMore => 'Ver más';

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
      'Te avisamos para que confirmes antes de afectar tu saldo';

  @override
  String get scheduledPaymentFormDeleteAction => 'Eliminar pago programado';

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
  String get scheduledPaymentDetailHistoryTitle => 'Ya generados';

  @override
  String get scheduledPaymentDetailHistoryEmpty =>
      'Todavía no se ha generado ningún movimiento de este pago programado.';

  @override
  String scheduledPaymentDetailHistorySeeAll(int count) {
    return 'Ver historial completo ($count)';
  }

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
      'Elegiste una fecha futura. Puedes convertir este movimiento en un pago programado para no tener que registrarlo de nuevo.';

  @override
  String get scheduledPaymentBridgeAccept => 'Sí, programarlo';

  @override
  String get scheduledPaymentBridgeDecline => 'No, guardar como siempre';

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
  String get budgetAdjustRemoveCta => 'Quitar ajuste';

  @override
  String get budgetAdjustBannerLabel => 'Ajuste de monto programado';

  @override
  String budgetAdjustBannerSub(String amount) {
    return '$amount este período';
  }

  @override
  String get budgetAdjustScheduledSnackbar =>
      'Ajuste aplicado al período seleccionado.';

  @override
  String get budgetAdjustUpdatedSnackbar => 'Ajuste actualizado.';

  @override
  String get budgetAdjustCancelledSnackbar =>
      'Ajuste cancelado — el período vuelve al monto habitual.';
}
