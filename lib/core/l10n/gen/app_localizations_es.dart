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
  String get moreRecurring => 'Recurrentes';

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
  String get budgetDeleteConfirmTitle => '¿Eliminar presupuesto?';

  @override
  String get budgetDeleteConfirmMessage =>
      'Podrás recuperarlo desde la papelera.';

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
}
