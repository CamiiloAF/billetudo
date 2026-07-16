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
  String get commonApply => 'Aplicar';

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
      'Tus datos siguen a salvo en este dispositivo.';

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
  String get transactionsSortAmountDesc => 'Monto: mayor a menor';

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
  String get transactionFormCategoryNone => 'Sin categoría';

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
  String get transactionFormSourceLabel => 'Origen';

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
  String get transactionSourceRecurring => 'Recurrente';

  @override
  String get transactionEditImpactTitle => 'Este movimiento está vinculado';

  @override
  String get transactionEditImpactRecurring => 'Afecta su recurrente asociado.';

  @override
  String get transactionEditImpactGoal => 'Afecta la meta a la que aporta.';

  @override
  String get transactionEditImpactDebt => 'Afecta la deuda a la que abona.';

  @override
  String get transactionEditImpactConfirm => 'Guardar de todas formas';

  @override
  String get transactionDeleteTitle => '¿Eliminar este movimiento?';

  @override
  String get transactionDeleteMessage =>
      'Podrás recuperarlo después desde la papelera.';

  @override
  String get transactionDetailTitle => 'Detalle del movimiento';

  @override
  String get transactionDetailEdit => 'Editar';

  @override
  String get transactionDetailDelete => 'Eliminar';

  @override
  String transactionDetailSource(String source) {
    return 'Registrado como $source';
  }

  @override
  String transactionDetailAccountLine(String account) {
    return 'Cuenta: $account';
  }

  @override
  String transactionDetailTransferLine(String account) {
    return 'Cuenta destino: $account';
  }

  @override
  String transactionDetailCategoryLine(String category) {
    return 'Categoría: $category';
  }

  @override
  String transactionDetailNoteLine(String note) {
    return 'Nota: $note';
  }

  @override
  String transactionDetailTagsLine(String tags) {
    return 'Etiquetas: $tags';
  }

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
  String get homeNotificationsTooltip => 'Notificaciones';

  @override
  String get homeSyncSynced => 'Sincronizado';

  @override
  String get homeSyncSyncing => 'Sincronizando';

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
  String get homeRecentTitle => 'Movimientos recientes';

  @override
  String get homeSeeAll => 'Ver todos';

  @override
  String get homeEmptyMovements => 'Aún no registras movimientos';

  @override
  String get homeLoading => 'Cargando inicio';

  @override
  String get homeMonthPickerTitle => 'Elegir mes';

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
  String get moreDebts => 'Deudas';

  @override
  String get moreRecurring => 'Recurrentes';

  @override
  String get moreReports => 'Gráficas e informes';

  @override
  String get moreImportExport => 'Importar y exportar';

  @override
  String get moreSettings => 'Ajustes';
}
