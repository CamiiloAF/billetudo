// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Billetudo';

  @override
  String get bootstrapReady =>
      'Technical foundation ready. Screens arrive with each feature.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get commonApply => 'Apply';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get errorDatabase =>
      'We couldn\'t save your changes. Please try again.';

  @override
  String get errorSecureStorage =>
      'We couldn\'t access the device\'s secure storage.';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsOpenAction => 'See my accounts';

  @override
  String get accountsAdd => 'Add account';

  @override
  String get accountsTotalLabel => 'Total net worth';

  @override
  String accountsTotalDebtsLine(String amount) {
    return 'Debts: -$amount';
  }

  @override
  String get accountsEmptyMessage => 'You haven\'t added any account yet';

  @override
  String get accountsErrorTitle => 'We couldn\'t load your accounts';

  @override
  String get accountsErrorLocalFirst =>
      'Your data is still saved on your device';

  @override
  String get accountsArchivedTitle => 'Archived accounts';

  @override
  String get accountsArchivedEmptyMessage =>
      'You haven\'t archived any account yet';

  @override
  String get accountsUnarchive => 'Unarchive';

  @override
  String get accountsLoading => 'Loading your accounts';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeCard => 'Credit card';

  @override
  String get accountTypeSavings => 'Savings';

  @override
  String get accountTypeInvestment => 'Investment';

  @override
  String get accountTypeOther => 'Other';

  @override
  String get accountBalanceLabel => 'Current balance';

  @override
  String get accountAvailableCreditLabel => 'Available credit';

  @override
  String get accountDebtLabel => 'Current debt';

  @override
  String get accountOverLimitBadge => 'Over limit';

  @override
  String accountOverLimitCaption(String amount) {
    return 'Exceeded by $amount';
  }

  @override
  String accountCreditUsedCaption(String used, String limit) {
    return '$used of $limit used';
  }

  @override
  String accountBalancePage(int index, int total) {
    return 'Page $index of $total';
  }

  @override
  String get accountInfoInstitution => 'Institution';

  @override
  String get accountInfoType => 'Type';

  @override
  String get accountInfoInterestRate => 'Interest rate';

  @override
  String get accountInfoNumber => 'Account number';

  @override
  String get accountInfoStatementDay => 'Statement day';

  @override
  String get accountInfoPaymentDueDay => 'Payment due day';

  @override
  String accountInterestRateValue(String rate) {
    return '$rate%';
  }

  @override
  String accountDayOfMonthValue(int day) {
    return 'Day $day of each month';
  }

  @override
  String accountNumberMasked(String last4) {
    return '•••• $last4';
  }

  @override
  String get accountNumberReveal => 'Show number';

  @override
  String get accountNumberHide => 'Hide number';

  @override
  String get accountNumberCopy => 'Copy number';

  @override
  String get accountNumberCopied =>
      'Number copied. It clears from the clipboard in a minute.';

  @override
  String get accountArchiveAction => 'Archive';

  @override
  String get accountDeleteAction => 'Delete account';

  @override
  String get accountFormNewTitle => 'New account';

  @override
  String get accountFormEditTitle => 'Edit account';

  @override
  String get accountFormTypeLabel => 'Account type';

  @override
  String get accountFormTypeChange => 'Change';

  @override
  String get accountFormNameLabel => 'Name';

  @override
  String get accountFormNameHint => 'E.g. Savings account';

  @override
  String get accountFormInstitutionLabel => 'Institution';

  @override
  String get accountFormInstitutionHint => 'E.g. Bancolombia';

  @override
  String get accountFormInitialBalanceLabel => 'Opening balance';

  @override
  String get accountFormCurrencyLabel => 'Currency';

  @override
  String get accountFormInterestRateLabel => 'Interest rate';

  @override
  String get accountFormInterestRateHint => 'E.g. 24.5';

  @override
  String get accountFormNumberLabel => 'Account number';

  @override
  String get accountFormNumberHint => 'Optional';

  @override
  String get accountFormNumberHelp =>
      'Saved only on this device, never in the cloud.';

  @override
  String get accountFormNumberReadError =>
      'We couldn\'t read the number saved on this device. We\'ll leave it exactly as it is — to change it, type it again.';

  @override
  String get accountFormLast4Label => 'Last 4 digits';

  @override
  String get accountFormLast4Hint => 'E.g. 4321';

  @override
  String get accountFormCardSectionTitle => 'Card details';

  @override
  String get accountFormCreditLimitLabel => 'Credit limit';

  @override
  String get accountFormStatementDayLabel => 'Statement day';

  @override
  String get accountFormPaymentDueDayLabel => 'Payment due day';

  @override
  String get accountFormAmountHint => '0';

  @override
  String get accountFormSelectHint => 'Select';

  @override
  String get accountErrorType => 'Pick the account type.';

  @override
  String get accountErrorName => 'Enter a name of up to 100 characters.';

  @override
  String get accountErrorCurrency => 'Pick a currency.';

  @override
  String get accountErrorInstitution =>
      'The institution allows up to 100 characters.';

  @override
  String get accountErrorFullNumber => 'Check the account number: digits only.';

  @override
  String get accountErrorLast4 => 'Enter up to 4 digits.';

  @override
  String get accountErrorInterestRate =>
      'Enter a valid rate, for example 24.5.';

  @override
  String get accountErrorInitialBalance => 'Enter a valid balance.';

  @override
  String get accountErrorCreditLimit => 'Enter the card\'s credit limit.';

  @override
  String get accountErrorStatementDay => 'Pick a day between 1 and 31.';

  @override
  String get accountErrorPaymentDueDay => 'Pick a day between 1 and 31.';

  @override
  String get accountDeleteSheetTitle => 'Delete this account?';

  @override
  String get accountDeleteSheetMessage =>
      'The account will no longer appear in your lists.';

  @override
  String accountDeleteSheetImpact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'It has $count linked transactions.',
      one: 'It has 1 linked transaction.',
    );
    return '$_temp0';
  }

  @override
  String get accountArchiveSheetTitle => 'Archive this account?';

  @override
  String get accountArchiveSheetMessage =>
      'You can bring it back any time from “Archived accounts”.';

  @override
  String get accountChangeSheetTitle => 'Confirm the change?';

  @override
  String get accountChangeSheetMessage =>
      'This account already has transactions. Changing its type or currency changes how its figures read.';

  @override
  String get accountChangeConfirm => 'Confirm';

  @override
  String get accountCurrencySheetTitle => 'Currency';

  @override
  String get currencyCopName => 'Colombian peso';

  @override
  String get currencyUsdName => 'US dollar';

  @override
  String get accountCannotDeleteTitle => 'Can\'t delete this account';

  @override
  String get accountCannotDeleteMessage =>
      'You need at least one account to record your transactions. Create another one and then you can delete this.';

  @override
  String get accountCannotDeleteUnderstood => 'Got it';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesOpenAction => 'View my categories';

  @override
  String get categoriesAdd => 'Create category';

  @override
  String get categoriesErrorTitle => 'We couldn\'t load your categories';

  @override
  String get categoriesEmptyExpense =>
      'You don\'t have any expense categories yet';

  @override
  String get categoriesEmptyIncome =>
      'You don\'t have any income categories yet';

  @override
  String get categoriesLoading => 'Loading your categories';

  @override
  String categorySubcategoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subcategories',
      one: '1 subcategory',
      zero: 'No subcategories',
    );
    return '$_temp0';
  }

  @override
  String get categoryAddSubcategory => 'Add subcategory';

  @override
  String get categoryKindExpense => 'Expense';

  @override
  String get categoryKindIncome => 'Income';

  @override
  String get categoryFormNewTitle => 'New category';

  @override
  String get categoryFormNewSubcategoryTitle => 'New subcategory';

  @override
  String get categoryFormEditTitle => 'Edit category';

  @override
  String get categoryFormEditSubcategoryTitle => 'Edit subcategory';

  @override
  String get categoryFormAppearanceLabel => 'Icon and color';

  @override
  String get categoryFormAppearanceEmptySublabel => 'Tap to choose (optional)';

  @override
  String get categoryFormAppearanceFilledSublabel => 'Tap to change';

  @override
  String get categoryFormNameLabel => 'Name';

  @override
  String get categoryFormNameHint => 'E.g. Food and drink';

  @override
  String get categoryFormKindLabel => 'Type';

  @override
  String get categoryFormParentLabel => 'Parent category';

  @override
  String get categoryErrorName => 'Enter a name of up to 100 characters.';

  @override
  String get categoryKindLockedSubcategory =>
      'Inherits the parent category\'s type — it can\'t be changed on subcategories.';

  @override
  String get categoryKindLockedRoot =>
      'The type can\'t be changed because it has active subcategories. Delete or reassign the subcategories first.';

  @override
  String get categoryDeleteAction => 'Delete category';

  @override
  String get categoryAppearancePickerTitle => 'Icon and color';

  @override
  String get categoryParentPickerTitle => 'Parent category';

  @override
  String get categoryParentPickerEmpty => 'No categories available yet.';

  @override
  String get categoryDeleteSimpleTitle => 'Delete this category?';

  @override
  String get categoryDeleteSimpleMessage =>
      'You can bring it back later from the trash.';

  @override
  String get categoryDeleteTransactionsTitle => 'Delete this category?';

  @override
  String categoryDeleteTransactionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'It has $count linked transactions.',
      one: 'It has 1 linked transaction.',
    );
    return '$_temp0';
  }

  @override
  String get categoryDeleteReassignOption => 'Reassign to another category';

  @override
  String get categoryDeleteClearOption => 'Leave uncategorized';

  @override
  String get categoryReassignTransactionsPickerTitle =>
      'Reassign to another category';

  @override
  String get categoryDeleteSubcategoriesTitle =>
      'This category has subcategories';

  @override
  String get categoryDeleteSubcategoriesMessage =>
      'Before deleting it, decide what happens to its subcategories.';

  @override
  String get categoryReassignSubcategoriesOption => 'Reassign subcategories';

  @override
  String get categoryReassignSubcategoriesPickerTitle =>
      'Move subcategories to';

  @override
  String get categoryCascadeDeleteOption => 'Delete everything in cascade';

  @override
  String get categoryCascadeConfirmTitle =>
      'Delete the category and its subcategories?';

  @override
  String get categoryCascadeConfirmMessage =>
      'This deletes the category and all of its subcategories. You can bring them back later from the trash.';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsSearchHint => 'Search by note or category';

  @override
  String get transactionsLoading => 'Loading transactions';

  @override
  String get transactionsEmptyMessage => 'No transactions recorded yet.';

  @override
  String get transactionsEmptyPeriodMessage =>
      'No transactions in this period.';

  @override
  String get transactionsErrorTitle => 'We couldn\'t load your transactions';

  @override
  String get transactionsErrorLocalFirst =>
      'Your data is still safe on this device.';

  @override
  String get transactionsAdd => 'Add transaction';

  @override
  String get transactionsUndoDeletedMessage => 'Transaction deleted.';

  @override
  String get transactionsUndoAction => 'Undo';

  @override
  String get transactionsFilterAccounts => 'Accounts';

  @override
  String get transactionsFilterCategories => 'Categories';

  @override
  String get transactionsFilterType => 'Type';

  @override
  String get transactionsFilterDate => 'Date';

  @override
  String get transactionsFilterTag => 'Tag';

  @override
  String get transactionsSortDateDesc => 'Most recent first';

  @override
  String get transactionsSortAmountDesc => 'Amount: high to low';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get transactionFormNewExpenseTitle => 'New expense';

  @override
  String get transactionFormNewIncomeTitle => 'New income';

  @override
  String get transactionFormNewTransferTitle => 'New transfer';

  @override
  String get transactionFormEditTitle => 'Edit transaction';

  @override
  String get transactionFormAmountLabel => 'Amount';

  @override
  String get transactionFormAccountLabel => 'Account';

  @override
  String get transactionFormAccountChoose => 'Choose account';

  @override
  String get transactionFormTransferAccountLabel => 'Destination account';

  @override
  String get transactionFormCategoryLabel => 'Category';

  @override
  String get transactionFormCategoryNone => 'No category';

  @override
  String get transactionFormDateLabel => 'Date';

  @override
  String get transactionFormNoteLabel => 'Note';

  @override
  String get transactionFormNoteHint => 'Add a note (optional)';

  @override
  String get transactionFormTagsLabel => 'Tags';

  @override
  String get transactionFormAddTag => 'Add tag';

  @override
  String get transactionFormSourceLabel => 'Source';

  @override
  String get transactionSourceManual => 'Manual';

  @override
  String get transactionSourceVoice => 'Voice';

  @override
  String get transactionSourceOcr => 'Receipt photo';

  @override
  String get transactionSourceNotification => 'Bank notification';

  @override
  String get transactionSourceImported => 'Imported';

  @override
  String get transactionSourceRecurring => 'Recurring';

  @override
  String get transactionEditImpactTitle => 'This transaction is linked';

  @override
  String get transactionEditImpactRecurring =>
      'It affects its linked recurring template.';

  @override
  String get transactionEditImpactGoal =>
      'It affects the goal it contributes to.';

  @override
  String get transactionEditImpactDebt => 'It affects the debt it pays down.';

  @override
  String get transactionEditImpactConfirm => 'Save anyway';

  @override
  String get transactionDeleteTitle => 'Delete this transaction?';

  @override
  String get transactionDeleteMessage =>
      'You can bring it back later from the trash.';

  @override
  String get transactionDetailTitle => 'Transaction detail';

  @override
  String get transactionDetailEdit => 'Edit';

  @override
  String get transactionDetailDelete => 'Delete';

  @override
  String transactionDetailSource(String source) {
    return 'Recorded as $source';
  }

  @override
  String transactionDetailAccountLine(String account) {
    return 'Account: $account';
  }

  @override
  String transactionDetailTransferLine(String account) {
    return 'Destination account: $account';
  }

  @override
  String transactionDetailCategoryLine(String category) {
    return 'Category: $category';
  }

  @override
  String transactionDetailNoteLine(String note) {
    return 'Note: $note';
  }

  @override
  String transactionDetailTagsLine(String tags) {
    return 'Tags: $tags';
  }

  @override
  String get accountFilterSheetTitle => 'Filter by account';

  @override
  String get accountFilterSelectAll => 'All';

  @override
  String get accountFilterSelectNone => 'None';

  @override
  String get categoryFilterSheetTitle => 'Filter by category';

  @override
  String get typeFilterSheetTitle => 'Filter by type';

  @override
  String get dateFilterSheetTitle => 'Filter by date';

  @override
  String get dateFilterWeek => 'Week';

  @override
  String get dateFilterMonth => 'Month';

  @override
  String get dateFilterYear => 'Year';

  @override
  String get dateFilterCustomRange => 'Custom range';

  @override
  String get dateFilterStart => 'From';

  @override
  String get dateFilterEnd => 'To';

  @override
  String dateFilterRangeLabel(String start, String end) {
    return '$start - $end';
  }

  @override
  String get tagFilterSheetTitle => 'Filter by tag';

  @override
  String get newTagSheetTitle => 'New tag';

  @override
  String get newTagNameHint => 'Tag name';

  @override
  String get navHome => 'Home';

  @override
  String get navBudgets => 'Budgets';

  @override
  String get navGoals => 'Goals';

  @override
  String get navMore => 'More';

  @override
  String get homeGreeting => 'Welcome back';

  @override
  String homeGreetingNamed(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get homeNotificationsTooltip => 'Notifications';

  @override
  String get homeSyncSynced => 'Synced';

  @override
  String get homeSyncSyncing => 'Syncing';

  @override
  String get homeSyncOffline => 'Offline';

  @override
  String homeSpentInMonth(String month) {
    return 'Spent in $month';
  }

  @override
  String get homeBudgetInvitation =>
      'Set a budget to see how much you have left this month';

  @override
  String get homeNoSpendingYet => 'No spending yet this month';

  @override
  String get homeRecentTitle => 'Recent activity';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeEmptyMovements => 'You have not logged any movements yet';

  @override
  String get homeLoading => 'Loading home';

  @override
  String get homeMonthPickerTitle => 'Choose month';

  @override
  String get homeAiBanner => 'Coming soon: ask Billetudo';

  @override
  String get homeAiSheetMessage =>
      'Soon you will be able to ask Billetudo about your money in plain language.';

  @override
  String get homeAiDisclaimer => 'This is not financial advice.';

  @override
  String get homeNotificationsSheetMessage => 'Notifications are coming soon.';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonMessage =>
      'We are building this section. It will be here very soon.';

  @override
  String get comingSoonBadge => 'Coming soon';

  @override
  String get comingSoonUnderstood => 'Got it';

  @override
  String get moreTitle => 'More';

  @override
  String get moreDebts => 'Debts';

  @override
  String get moreRecurring => 'Recurring';

  @override
  String get moreReports => 'Charts and reports';

  @override
  String get moreImportExport => 'Import and export';

  @override
  String get moreSettings => 'Settings';

  @override
  String get moreSignOut => 'Sign out';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueWithoutAccount => 'Continue without an account';

  @override
  String get authLoginTitle => 'Never lose your progress';

  @override
  String get authLoginSubtitle =>
      'An automatic backup of your accounts and transactions, ready whenever you need it.';

  @override
  String get authTrustRow =>
      'Use the app from any phone without losing your history';

  @override
  String get authGoogleLoading => 'Connecting to Google…';

  @override
  String get authGoogleErrorSnackbar => 'We couldn\'t sign you in with Google';

  @override
  String get authAppleErrorSnackbar => 'We couldn\'t sign you in with Apple';

  @override
  String get authMergeTitle => 'Your data is safe';

  @override
  String get authMergeSubtitle =>
      'We combined everything you already had saved with your account. Nothing was lost along the way.';

  @override
  String get authMergeStatAccounts => 'Accounts';

  @override
  String get authMergeStatTransactions => 'Transactions';

  @override
  String get authMergeStatCategories => 'Categories';

  @override
  String get authMergeCaption => 'Your devices will stay automatically synced';

  @override
  String get authMergeCta => 'Go to my finances';

  @override
  String get authMergeErrorTitle => 'We couldn\'t merge your data';

  @override
  String get authMergeErrorMessage =>
      'Your data is still safe on this device. Try again once you have a connection.';

  @override
  String get authSignOutSheetTitle => 'Sign out';

  @override
  String get authSignOutSheetMessage =>
      'Your accounts and transactions will stay saved on this device — they won\'t be deleted. But changes you make here afterwards won\'t sync until you sign in again.';

  @override
  String get authSignOutCta => 'Sign out';

  @override
  String get authDeleteStep1Title => 'Delete your account';

  @override
  String get authDeleteStep1Message =>
      'We\'re about to delete your accounts, transactions, categories and everything else tied to your account in the cloud. This can\'t be undone.';

  @override
  String get authDeleteStep1Cta => 'Delete account';

  @override
  String get authDeleteStep1ErrorTitle => 'We couldn\'t delete your account';

  @override
  String get authDeleteStep1ErrorMessage =>
      'Your data is still safe on this device. Try again once you have a connection.';

  @override
  String get authDeleteStep2Title =>
      'What should we do with your data on this phone?';

  @override
  String get authDeleteStep2Subtitle =>
      'Your cloud account is already deleted. This is only about this device.';

  @override
  String get authDeleteStep2KeepTitle => 'Keep my data on this device';

  @override
  String get authDeleteStep2KeepSubtitle =>
      'Keep using billetudo without an account, with what you already logged.';

  @override
  String get authDeleteStep2DeleteTitle => 'Also delete this device\'s data';

  @override
  String get authDeleteStep2DeleteSubtitle =>
      'Erases all of your local history.';

  @override
  String get authDeleteStep2Cta => 'Continue';

  @override
  String get authDeleteStep3Title => 'Done, your account was deleted';

  @override
  String get authDeleteStep3Subtitle =>
      'We no longer have any of your data in the cloud. You can keep using billetudo whenever you want, with or without an account.';

  @override
  String get authDeleteStep3Cta => 'Go to home';

  @override
  String get authSessionProviderGoogle => 'Signed in with Google';

  @override
  String get authSessionProviderApple => 'Signed in with Apple';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccountSection => 'Account and backup';

  @override
  String get settingsBackupTitle => 'Back up to the cloud';

  @override
  String get settingsBackupSubtitle => 'Keep your data safe';

  @override
  String get settingsPreferencesSection => 'Preferences';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsCurrencySubtitle =>
      'Choose the currency you log your transactions in';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetsAdd => 'New budget';

  @override
  String get budgetsNewCta => '+ New budget';

  @override
  String get budgetsEmptyMessage => 'You don\'t have any budgets yet';

  @override
  String get budgetsEmptyCta => 'Create budget';

  @override
  String get budgetsLoading => 'Loading your budgets';

  @override
  String get budgetsErrorTitle => 'We couldn\'t load your budgets';

  @override
  String get budgetsMenuHistory => 'View history';

  @override
  String get budgetRemainingLabel => 'You have left';

  @override
  String get budgetOverspentLabel => 'Over by';

  @override
  String budgetResetsOn(String date) {
    return 'resets on $date';
  }

  @override
  String budgetEndsOn(String date) {
    return 'ends on $date';
  }

  @override
  String get budgetScopeGlobal => 'All spending';

  @override
  String get budgetScopeStranded => 'No valid scope';

  @override
  String budgetScopeAccounts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '$count account',
    );
    return '$_temp0';
  }

  @override
  String budgetScopeCategories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '$count category',
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
      other: '$count days left',
      one: '$count day left',
      zero: 'Last day',
    );
    return '$_temp0';
  }

  @override
  String budgetProgressBreakdown(String spent, String amount) {
    return '$spent of $amount';
  }

  @override
  String get budgetActivityTitle => 'This period\'s activity';

  @override
  String get budgetActivityEmpty => 'No transactions in this period';

  @override
  String get budgetLoadMore => 'Load more';

  @override
  String get budgetOpenInTransactions => 'Open in Transactions';

  @override
  String get budgetPeriodStatusCurrent => 'current';

  @override
  String get budgetPeriodStatusPast => 'past';

  @override
  String get budgetPeriodStatusFuture => 'upcoming';

  @override
  String get budgetActionClose => 'Close (save to history)';

  @override
  String get budgetActionDelete => 'Delete';

  @override
  String get budgetDeleteConfirmTitle => 'Delete budget?';

  @override
  String get budgetDeleteConfirmMessage => 'You can restore it from the trash.';

  @override
  String get budgetFormNewTitle => 'New budget';

  @override
  String get budgetFormEditTitle => 'Edit budget';

  @override
  String get budgetFormNameLabel => 'Name';

  @override
  String get budgetFormNameHint => 'e.g. Monthly groceries';

  @override
  String get budgetFormIconLabel => 'Icon';

  @override
  String get budgetFormAmountLabel => 'Amount';

  @override
  String get budgetFormRepeatLabel => 'Repeat';

  @override
  String get budgetFormRepeatPeriodic => 'Recurring';

  @override
  String get budgetFormRepeatOneOff => 'One-off';

  @override
  String get budgetFormPeriodLabel => 'Frequency';

  @override
  String get budgetPeriodWeekly => 'Weekly';

  @override
  String get budgetPeriodBiweekly => 'Fortnightly';

  @override
  String get budgetPeriodMonthly => 'Monthly';

  @override
  String get budgetPeriodYearly => 'Yearly';

  @override
  String get budgetFormStartLabel => 'Start';

  @override
  String get budgetFormEndLabel => 'End';

  @override
  String get budgetFormRepeatUntilLabel => 'Repeat until';

  @override
  String get budgetFormForever => 'Forever';

  @override
  String get budgetFormUntilDate => 'Until a date';

  @override
  String get budgetFormScopeLabel => 'Scope';

  @override
  String get budgetFormScopeAll => 'All';

  @override
  String get budgetFormScopeCustom => 'Custom';

  @override
  String get budgetFormAccountsRow => 'Accounts';

  @override
  String get budgetFormCategoriesRow => 'Categories';

  @override
  String get budgetScopeAllAccounts => 'All accounts';

  @override
  String get budgetScopeAllCategories => 'All categories';

  @override
  String budgetFormThresholdRow(int pct) {
    return 'Alert me at $pct% of the budget';
  }

  @override
  String get budgetFormThresholdOff => 'Don\'t alert me';

  @override
  String get budgetFormCreateCta => 'Create budget';

  @override
  String get budgetFormSaveCta => 'Save changes';

  @override
  String get budgetThresholdTitle => 'Alert threshold';

  @override
  String get budgetThresholdCustom => 'Custom';

  @override
  String get budgetIconSheetTitle => 'Choose icon';

  @override
  String get budgetsHistoryTitle => 'History';

  @override
  String get budgetsHistoryEmpty => 'You haven\'t closed any budgets';

  @override
  String get budgetsHistoryLoading => 'Loading your history';

  @override
  String get budgetReactivate => 'Reactivate';

  @override
  String get budgetResultWithin => 'Within budget';

  @override
  String budgetResultOverspent(String amount) {
    return 'Over by $amount';
  }

  @override
  String deleteImpactBudgets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used in $count budgets.',
      one: 'Used in 1 budget.',
    );
    return '$_temp0';
  }

  @override
  String get settingsEnvelopeMode => 'Envelope mode';

  @override
  String get settingsEnvelopeModeSubtitle =>
      'Split this month\'s income across your budgets';

  @override
  String get settingsEnvelopeWhatIs => 'What is it?';

  @override
  String get envelopeInfoTitle => 'What is envelope mode?';

  @override
  String get envelopeInfoBody =>
      'It\'s a simple way to organize your money: instead of spending from one big pile, you split what you get each month into envelopes, one for each thing that matters to you (groceries, rent, going out). That way, before you spend, you already know how much each envelope holds. The idea is for all your income to be split up, so every cent has a purpose. It\'s optional and you can turn it on or off whenever you like.';

  @override
  String get envelopeInfoGotIt => 'Got it';

  @override
  String get budgetsMenuDisableEnvelope => 'Turn off envelope mode';

  @override
  String get budgetsEnvelopeUnassignedLabel => 'Unassigned';

  @override
  String get budgetsEnvelopeOverLabel => 'Over-assigned';

  @override
  String get budgetsEnvelopeAllAssigned => 'Every cent has a job';

  @override
  String budgetsEnvelopeCaption(String income, String assigned) {
    return '$income income · $assigned assigned';
  }
}
