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
  String get commonEdit => 'Editar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonDone => 'Listo';

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
  String get accountFormCurrentDebtLabel => 'Deuda actual';

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
  String get categoryDeleteSubcategoryAction => 'Eliminar subcategoría';

  @override
  String get categoryAppearancePickerTitle => 'Icono y color';

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
  String get categoryParentPickerEmpty =>
      'No hay categorías disponibles todavía.';

  @override
  String get categoryDeleteSimpleTitle => '¿Eliminar esta categoría?';

  @override
  String get categoryDeleteSimpleMessage =>
      'Podrás deshacerlo justo después de eliminar.';

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
  String get transactionEditImpactTitle => 'Este movimiento está vinculado';

  @override
  String get transactionEditImpactScheduled =>
      'Afecta su pago programado asociado.';

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
  String get moreScheduledPayments => 'Recurrentes';

  @override
  String get moreReports => 'Gráficas e informes';

  @override
  String get moreImportExport => 'Importar y exportar';

  @override
  String get moreSettings => 'Ajustes';

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
      'Tus cuentas y movimientos seguirán guardados en este dispositivo, no se borran. Pero los cambios que hagas aquí después no se sincronizarán hasta que vuelvas a iniciar sesión.';

  @override
  String get authSignOutCta => 'Cerrar sesión';

  @override
  String get authDeleteStep1Title => 'Eliminar tu cuenta';

  @override
  String get authDeleteStep1Message =>
      'Vamos a borrar tus cuentas, movimientos, categorías y todo lo demás asociado a tu cuenta en la nube. Esta acción no se puede deshacer.';

  @override
  String get authDeleteStep1Cta => 'Eliminar cuenta';

  @override
  String get authDeleteStep1ErrorTitle => 'No pudimos eliminar tu cuenta';

  @override
  String get authDeleteStep1ErrorMessage =>
      'Tus datos siguen a salvo en este dispositivo. Intenta de nuevo cuando tengas conexión.';

  @override
  String get authDeleteStep2Title =>
      '¿Qué hacemos con tus datos en este teléfono?';

  @override
  String get authDeleteStep2Subtitle =>
      'Tu cuenta en la nube ya se eliminó. Esto es solo sobre este dispositivo.';

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
  String get settingsPreferencesSection => 'Preferencias';

  @override
  String get settingsAppearance => 'Apariencia';

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
  String get budgetsLoading => 'Cargando tus presupuestos';

  @override
  String get budgetsErrorTitle => 'No pudimos cargar tus presupuestos';

  @override
  String get budgetsMenuHistory => 'Ver histórico';

  @override
  String get budgetRemainingLabel => 'Te quedan';

  @override
  String get budgetOverspentLabel => 'Excedido por';

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
  String budgetProgressBreakdown(String spent, String amount) {
    return '$spent de $amount';
  }

  @override
  String get budgetActivityTitle => 'Actividad del periodo';

  @override
  String get budgetActivityEmpty => 'Sin movimientos en este periodo';

  @override
  String get budgetLoadMore => 'Cargar más';

  @override
  String get budgetOpenInTransactions => 'Abrir en Movimientos';

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
  String get budgetDeleteConfirmMessage =>
      'Podrás deshacerlo justo después de eliminar.';

  @override
  String get budgetFormNewTitle => 'Nuevo presupuesto';

  @override
  String get budgetFormEditTitle => 'Editar presupuesto';

  @override
  String get budgetFormNameLabel => 'Nombre';

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
  String get budgetThresholdTitle => 'Umbral de alerta';

  @override
  String get budgetThresholdCustom => 'Personalizado';

  @override
  String get budgetIconSheetTitle => 'Elegir ícono';

  @override
  String get budgetsHistoryTitle => 'Histórico';

  @override
  String get budgetsHistoryEmpty => 'No has cerrado ningún presupuesto';

  @override
  String get budgetsHistoryLoading => 'Cargando tu histórico';

  @override
  String get budgetReactivate => 'Reactivar';

  @override
  String get budgetResultWithin => 'Dentro del presupuesto';

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
      'Reparte tu ingreso del mes entre tus presupuestos';

  @override
  String get settingsEnvelopeWhatIs => '¿Qué es?';

  @override
  String get envelopeInfoTitle => '¿Qué es el modo sobres?';

  @override
  String get envelopeInfoBody =>
      'Es una forma sencilla de organizar tu dinero: en vez de gastar de un montón común, repartes lo que recibes cada mes en sobres, uno por cada cosa que te importa (mercado, arriendo, salidas). Así, antes de gastar, ya sabes cuánto tiene cada sobre. La idea es que todo tu ingreso quede repartido, para que cada peso tenga un propósito. Es opcional y puedes prenderlo o apagarlo cuando quieras.';

  @override
  String get envelopeInfoGotIt => 'Entendido';

  @override
  String get budgetsMenuDisableEnvelope => 'Desactivar modo sobres';

  @override
  String get budgetsEnvelopeUnassignedLabel => 'Sin asignar';

  @override
  String get budgetsEnvelopeOverLabel => 'Asignado de más';

  @override
  String get budgetsEnvelopeAllAssigned => 'Cada peso tiene un trabajo';

  @override
  String budgetsEnvelopeCaption(String income, String assigned) {
    return '$income de ingreso · $assigned asignado';
  }

  @override
  String get firstLaunchOfflineTitle => 'Conéctate para continuar';

  @override
  String get firstLaunchOfflineSubtitle =>
      'Necesitamos conexión a internet para terminar de configurar tu cuenta. Cuando tengas señal, vuelve a intentarlo.';

  @override
  String get firstLaunchOfflineRetrying => 'Reintentando...';

  @override
  String get scheduledPaymentsTitle => 'Pagos programados';

  @override
  String get scheduledPaymentsAdd => 'Nuevo pago programado';

  @override
  String get scheduledPaymentsLoading => 'Cargando tus pagos programados';

  @override
  String get scheduledPaymentsEmptyMessage =>
      'Aún no tienes pagos programados. Agrega uno para no perder de vista tus pagos recurrentes.';

  @override
  String get scheduledPaymentsErrorTitle =>
      'No pudimos cargar tus pagos programados';

  @override
  String get scheduledPaymentsErrorLocalFirst =>
      'Tus datos siguen a salvo en este dispositivo. Intenta de nuevo.';

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
      'Se detiene la generación de nuevos pagos, pero los movimientos ya generados conservan su historial.';

  @override
  String get scheduledPaymentFormNewTitle => 'Nuevo pago programado';

  @override
  String get scheduledPaymentFormEditTitle => 'Editar pago programado';

  @override
  String get scheduledPaymentFormNextDateLabel => 'Próxima fecha';

  @override
  String get scheduledPaymentFormFrequencyLabel => 'Frecuencia';

  @override
  String get scheduledPaymentFormCategoryMoreLabel => 'Otra';

  @override
  String get scheduledPaymentFormIntervalStepperLabel => 'Repetir cada';

  @override
  String get scheduledPaymentFormEndDateLabel => 'Fecha de fin';

  @override
  String get scheduledPaymentFormEndDateNone => 'Sin fecha de fin';

  @override
  String get scheduledPaymentFormModeAutomaticTitle => 'Automático';

  @override
  String get scheduledPaymentFormModeAutomaticSubtitle => 'Se registra solo';

  @override
  String get scheduledPaymentFormModeManualTitle => 'Manual';

  @override
  String get scheduledPaymentFormModeManualSubtitle =>
      'Te avisamos antes de afectar tu saldo';

  @override
  String get scheduledPaymentFormDeleteAction => 'Eliminar pago programado';

  @override
  String get scheduledFrequencyOnce => 'Solo una vez';

  @override
  String get scheduledFrequencyDaily => 'Cada día';

  @override
  String get scheduledFrequencyWeekly => 'Cada semana';

  @override
  String get scheduledFrequencyMonthly => 'Cada mes';

  @override
  String get scheduledFrequencyYearly => 'Cada año';

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
  String get scheduledPaymentDetailTitle => 'Pago programado';

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
  String scheduledPaymentDetailHistorySeeAll(int count) {
    return 'Ver historial completo ($count)';
  }

  @override
  String get scheduledPaymentDetailHeroLabel => 'Próximo pago';

  @override
  String scheduledPaymentDetailRecurrenceOnce(String date) {
    return 'Pago único el $date';
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
  String get scheduledPaymentDetailModeLabel => 'Modo';

  @override
  String get scheduledPaymentDetailModeAutomatic => 'Automático';

  @override
  String get scheduledPaymentDetailModeManual => 'Manual';

  @override
  String get scheduledPaymentDetailAccountLabel => 'Cuenta';

  @override
  String get scheduledPaymentDetailStatusLabel => 'Estado';

  @override
  String get scheduledPaymentDetailStatusActive => 'Activo';

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
  String get scheduledFinishedTitle => 'Terminados';

  @override
  String get scheduledFinishedEmpty =>
      'Todavía no tienes pagos programados terminados.';

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
  String get scheduledDueToday => 'Vence hoy';

  @override
  String scheduledDueInDays(int count) {
    return 'en $count días';
  }

  @override
  String get scheduledDueInOneDay => 'en 1 día';

  @override
  String get scheduledConfirmationSheetScopeNote =>
      'Lo que edites aquí aplica solo a este pago, no cambia la plantilla.';

  @override
  String scheduledConfirmationSheetAccumulated(
      int count, String template, String date) {
    return 'Tienes $count pagos de $template sin confirmar. Ahora confirmas el más antiguo, del $date.';
  }

  @override
  String get scheduledConfirmationSheetEditTooltip => 'Editar plantilla';

  @override
  String get scheduledGuidedReviewExit => 'Salir';

  @override
  String get scheduledGuidedReviewConfirmNext => 'Confirmar y siguiente';

  @override
  String scheduledSnoozeContextLine(String template, String date) {
    return '$template · vencía el $date · muévelo hacia adelante';
  }
}
