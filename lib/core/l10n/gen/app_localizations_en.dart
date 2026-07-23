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
  String get commonContinue => 'Continue';

  @override
  String get commonAnd => 'and';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get commonMoreActions => 'More options';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonDone => 'Done';

  @override
  String get commonCreate => 'Create';

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
      'Your data is still saved on your device. Try again.';

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
  String get accountBalanceAdjustTitle => 'Adjust balance';

  @override
  String accountBalanceAdjustCurrent(String amount) {
    return 'Current balance: $amount';
  }

  @override
  String accountBalanceAdjustCurrentDebt(String amount) {
    return 'Current debt: $amount';
  }

  @override
  String get accountBalanceAdjustNewLabel => 'New desired balance';

  @override
  String get accountBalanceAdjustNewDebtLabel => 'New debt';

  @override
  String get accountBalanceAdjustHowLabel => 'How do you want to apply it?';

  @override
  String get accountBalanceAdjustRegisterTitle => 'Register adjustment';

  @override
  String accountBalanceAdjustRegisterBody(String diff) {
    return 'We create a movement dated today for the difference ($diff). It counts toward your reports and budgets.';
  }

  @override
  String get accountBalanceAdjustCorrectTitle => 'Correct opening balance';

  @override
  String get accountBalanceAdjustCorrectBody =>
      'We adjust your starting balance so it matches. No movement is created.';

  @override
  String get accountBalanceAdjustApplyCta => 'Apply';

  @override
  String get accountBalanceAdjustError =>
      'We couldn\'t adjust the balance. Try again.';

  @override
  String get accountBalanceAdjustNote => 'Balance adjustment';

  @override
  String get accountDebtShortLabel => 'Debt';

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
    return '••••••• $last4';
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
  String get accountFormNameLabel => 'Account name';

  @override
  String get accountFormNameHint => 'E.g. Savings account';

  @override
  String get accountFormInstitutionLabel => 'Institution (optional)';

  @override
  String get accountFormInstitutionHint => 'Optional';

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
  String get accountFormAmountHint => '\$0';

  @override
  String get accountFormSelectHint => 'Select';

  @override
  String get accountFormSaveCta => 'Save account';

  @override
  String get accountErrorType => 'Pick the account type.';

  @override
  String get accountErrorNameRequired => 'Enter a name for the account.';

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
  String get accountDeleteSheetMessage =>
      'This account has no linked transactions. This action cannot be undone.';

  @override
  String accountDeleteSheetImpact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This account has $count linked transactions. Deleting it will archive that history too. This action cannot be undone.',
      one:
          'This account has 1 linked transaction. Deleting it will archive that history too. This action cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get accountArchiveSheetTitle => 'Archive this account?';

  @override
  String get accountArchiveSheetMessage =>
      'You can bring it back any time from “Archived accounts”.';

  @override
  String get accountChangeSheetMessage =>
      'Changing this account\'s type or currency can affect calculations and reports on its existing transactions. Do you want to continue?';

  @override
  String get accountChangeConfirm => 'Confirm';

  @override
  String get accountCurrencySheetTitle => 'Select the currency';

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
  String get categoryFormAppearanceEmptyLabel => 'Choose icon and color';

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
  String get categoryErrorNameRequired => 'Enter a name for the category.';

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
  String get categoryDeleteSubcategoryAction => 'Delete subcategory';

  @override
  String get categoryAppearancePickerTitle => 'Icon and color';

  @override
  String get categoryColorLockedSubcategory =>
      'The color is inherited from the parent category and can\'t be changed. Pick the icon you like.';

  @override
  String get categoryAppearanceIconSectionLabel => 'Icon';

  @override
  String get categoryAppearanceColorSectionLabel => 'Color';

  @override
  String get categoryParentPickerTitle => 'Parent category';

  @override
  String get categoryParentPickerHint =>
      'Only main Expense categories are shown. Subcategories can\'t be nested inside other subcategories.';

  @override
  String get categoryParentPickerEmpty => 'No categories available yet.';

  @override
  String get categoryDeleteSimpleTitle => 'Delete this category?';

  @override
  String get categoryDeleteSimpleMessage =>
      'This category will be removed from your list. You can recover it later from the trash, in Settings.';

  @override
  String categoryDeleteTransactionsMessage(String categoryName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '\"$categoryName\" has $count linked transactions. Choose what to do with them before deleting the category.',
      one:
          '\"$categoryName\" has 1 linked transaction. Choose what to do with it before deleting the category.',
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
  String categoryDeleteSubcategoriesMessage(String categoryName, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '\"$categoryName\" has $count active subcategories. You need to resolve them before deleting this root category.',
      one:
          '\"$categoryName\" has 1 active subcategory. You need to resolve it before deleting this root category.',
    );
    return '$_temp0';
  }

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
      'This deletes the category and all of its subcategories. You can undo this right after deleting.';

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
      'Your data is still saved on your device. Try again.';

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
  String get transactionsSortDateAsc => 'Oldest first';

  @override
  String get transactionsSortAmountDesc => 'High to low';

  @override
  String get transactionsSortAmountAsc => 'Low to high';

  @override
  String get transactionsSortSectionDate => 'DATE';

  @override
  String get transactionsSortSectionAmount => 'AMOUNT';

  @override
  String get transactionsSortActiveByDate => 'Sorted by date';

  @override
  String get transactionsSortActiveByAmount => 'Sorted by amount';

  @override
  String transactionsFilterAccountsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '1 account',
    );
    return '$_temp0';
  }

  @override
  String get transactionsBalanceTotalLabel => 'Total balance';

  @override
  String get transactionsBalanceCardBalanceLabel => 'Balance';

  @override
  String get transactionsBalanceCarouselCollapse => 'Hide balances';

  @override
  String get transactionsBalanceCarouselExpand => 'Show balances';

  @override
  String get transactionsGroupToday => 'Today';

  @override
  String get transactionsGroupYesterday => 'Yesterday';

  @override
  String transactionsGroupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

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
  String get transactionErrorAccount => 'Choose an account.';

  @override
  String get transactionErrorCategory => 'Choose a category.';

  @override
  String get transactionErrorAmount => 'Enter an amount greater than zero.';

  @override
  String get transactionErrorTransferAccount =>
      'Choose the destination account.';

  @override
  String get categorySelectTitle => 'Choose category';

  @override
  String get categorySelectSearchHint => 'Search category';

  @override
  String get categorySelectMore => 'See more';

  @override
  String get categorySelectEmpty =>
      'We couldn\'t find categories with that name';

  @override
  String get categorySelectExpand => 'Show subcategories';

  @override
  String get categorySelectCollapse => 'Hide subcategories';

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
  String get transactionFormTagNew => 'New';

  @override
  String get transactionFormTagsSheetTitle => 'Tags';

  @override
  String get transactionFormSourceLabel => 'Source';

  @override
  String get transactionFormTransferAmountLabel => 'Amount to transfer';

  @override
  String get transactionFormTransferFromLabel => 'From account';

  @override
  String get transactionFormTransferInfo =>
      'Transfers don\'t count as income or expense.';

  @override
  String get transactionFormSwapAccounts => 'Swap accounts';

  @override
  String get transactionFormDateToday => 'Today';

  @override
  String get transactionFormDateYesterday => 'Yesterday';

  @override
  String transactionFormDateValue(String prefix, String date) {
    return '$prefix, $date';
  }

  @override
  String get datePickerTitle => 'Choose date';

  @override
  String get datePickerPreviousMonth => 'Previous month';

  @override
  String get datePickerNextMonth => 'Next month';

  @override
  String get transactionFormExpandAmount => 'Edit amount';

  @override
  String get transactionFormCollapseAmount => 'Hide keypad';

  @override
  String get transactionFormKeypadAdd => 'Add';

  @override
  String get transactionFormKeypadSubtract => 'Subtract';

  @override
  String get transactionFormKeypadMultiply => 'Multiply';

  @override
  String get transactionFormKeypadDivide => 'Divide';

  @override
  String get transactionFormKeypadEquals => 'Calculate result';

  @override
  String get transactionFormKeypadConfirm => 'Confirm';

  @override
  String get transactionFormKeypadDecimal => 'Decimal point';

  @override
  String get transactionFormKeypadBackspace => 'Delete';

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
  String get transactionSourceScheduled => 'Scheduled';

  @override
  String transactionEditImpactMessage(String links) {
    return 'This transaction is linked to $links. If you change the amount, make sure it still matches.';
  }

  @override
  String get transactionEditImpactLinkScheduled => 'your scheduled payment';

  @override
  String get transactionEditImpactLinkGoal => 'your goal';

  @override
  String get transactionEditImpactLinkDebt => 'your debt';

  @override
  String get transactionDeleteTitle => 'Delete this transaction?';

  @override
  String get transactionDeleteMessage =>
      'You can undo this right after deleting.';

  @override
  String get transactionDetailTitleExpense => 'Expense detail';

  @override
  String get transactionDetailTitleIncome => 'Income detail';

  @override
  String get transactionDetailTitleTransfer => 'Transfer detail';

  @override
  String transactionDetailSource(String source) {
    return 'Recorded as $source';
  }

  @override
  String get transactionDetailAccountLabel => 'Account';

  @override
  String get transactionDetailAccountFromLabel => 'Source account';

  @override
  String get transactionDetailAccountToLabel => 'Destination account';

  @override
  String get transactionDetailCategoryLabel => 'Category';

  @override
  String get transactionDetailDateLabel => 'Date';

  @override
  String get transactionDetailNoteLabel => 'Note';

  @override
  String get transactionDetailNoNote => 'No note';

  @override
  String get transactionDetailSourceLabel => 'Source';

  @override
  String get transactionDetailTagsLabel => 'Tags';

  @override
  String get transactionDetailTransferSubtitle => 'Transfer';

  @override
  String get transactionDetailDeleteLink => 'Delete transaction';

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
  String get tagFilterSearchHint => 'Search tag';

  @override
  String get tagFilterEmpty => 'We couldn\'t find tags with that name';

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
  String get navScheduledPayments => 'Payments';

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
  String get homeSyncSyncing => 'Syncing…';

  @override
  String get homeSyncOffline => 'Offline';

  @override
  String get homeSyncSheetSyncedTitle => 'All backed up';

  @override
  String get homeSyncSheetSyncedMessage =>
      'Your information is safe and synced.';

  @override
  String get homeSyncSheetSyncingTitle => 'Syncing…';

  @override
  String get homeSyncSheetSyncingMessage =>
      'We\'re saving your changes to the cloud.';

  @override
  String get homeSyncSheetOfflineTitle => 'Offline';

  @override
  String get homeSyncSheetOfflineMessage =>
      'Your data is saved on this device. It\'ll sync as soon as the connection is back.';

  @override
  String get homeSyncSheetDismiss => 'Got it';

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
  String homeHeroBudgetProgress(int pct, String amount) {
    return '$pct% of $amount';
  }

  @override
  String homeHeroBudgetDaysLeft(int count) {
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
  String get homeQuickAccessTitle => 'Quick access';

  @override
  String get homeQuickAccessScheduledPayments => 'Scheduled payments';

  @override
  String get homeRecentTitle => 'Recent activity';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeBalancesTitle => 'My accounts';

  @override
  String get homeBalancesSeeAll => 'See all';

  @override
  String get homeEmptyMovements => 'You have not logged any movements yet';

  @override
  String get homeLoading => 'Loading home';

  @override
  String get homeMonthPickerTitle => 'Select month';

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
  String get homeExitConfirmTitle => 'Leave Billetudo?';

  @override
  String get homeExitConfirmMessage =>
      'You can come back anytime, your data stays saved.';

  @override
  String get homeExitConfirmAction => 'Exit';

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
  String get moreAccountsDescription => 'Manage your accounts and balances';

  @override
  String get moreCategoriesDescription => 'Organize your income and expenses';

  @override
  String get moreDebts => 'Debts';

  @override
  String get moreDebtsDescription => 'Track your debts and payments';

  @override
  String get debtsTitle => 'Debts';

  @override
  String get debtsAdd => 'Add debt';

  @override
  String get debtsLoading => 'Loading your debts';

  @override
  String get debtsSummaryTitle => 'Summary';

  @override
  String get debtsSectionTitle => 'Your debts';

  @override
  String get debtsEmptyMessage => 'You don\'t have any debts yet';

  @override
  String get debtsEmptyDescription =>
      'Track what you owe or what you\'re owed to follow your payoff progress in one place.';

  @override
  String get debtsErrorTitle => 'We couldn\'t load your debts';

  @override
  String get debtDetailErrorTitle => 'We couldn\'t load this debt';

  @override
  String get debtDirectionIOwe => 'I owe';

  @override
  String get debtDirectionOwedToMe => 'Owed to me';

  @override
  String debtProgressPaid(int pct) {
    return '$pct% paid';
  }

  @override
  String debtProgressCollected(int pct) {
    return '$pct% collected';
  }

  @override
  String debtAmountOf(String amount) {
    return 'of $amount';
  }

  @override
  String debtDueOn(String date) {
    return 'Due $date';
  }

  @override
  String debtPercentValue(int pct) {
    return '$pct%';
  }

  @override
  String get debtDetailBalanceLabel => 'Outstanding balance';

  @override
  String get debtDetailPaidLabel => 'paid';

  @override
  String get debtDetailCollectedLabel => 'collected';

  @override
  String debtDetailGrowth(String amount) {
    return 'Grows ~$amount/day';
  }

  @override
  String get debtDetailEstimated => 'estimated';

  @override
  String get debtDetailUpdateBalance => 'Update balance';

  @override
  String get debtDetailMovementsTitle => 'Movements';

  @override
  String get debtDetailRegisterPayment => 'Record payment';

  @override
  String get debtInstallmentTitle => 'Next installment';

  @override
  String debtInstallmentBadge(String date) {
    return 'Installment · $date';
  }

  @override
  String get debtInstallmentScheduledBadge => 'Scheduled payment';

  @override
  String get debtConfigureInstallmentTitle => 'Set up installment';

  @override
  String get debtConfigureInstallmentSubtitle =>
      'Schedule this debt\'s installment';

  @override
  String get debtLedgerOpening => 'Opening balance';

  @override
  String get debtLedgerDisbursement => 'Disbursement';

  @override
  String get debtLedgerPaymentOwe => 'Payment on the debt';

  @override
  String get debtLedgerPaymentOwed => 'Payment received';

  @override
  String get debtLedgerInterest => 'Interest';

  @override
  String get debtLedgerAdjustment => 'Balance updated';

  @override
  String debtLedgerRunning(String amount) {
    return 'Balance $amount';
  }

  @override
  String get debtLedgerTagEstimated => 'Estimated';

  @override
  String get debtLedgerTagNoAccount => 'Doesn\'t affect accounts';

  @override
  String get debtEditTooltip => 'Edit debt';

  @override
  String get debtFormNewTitle => 'New debt';

  @override
  String get debtFormEditTitle => 'Edit debt';

  @override
  String get debtFormDirectionLabel => 'Do you owe or are you owed?';

  @override
  String get debtFormOpeningBalanceLabel => 'Opening balance';

  @override
  String get debtFormNameLabel => 'Name';

  @override
  String get debtFormNameHint => 'Car loan, loan to Andrés…';

  @override
  String get debtFormNameRequired => 'Give the debt a name';

  @override
  String get debtFormCounterpartyLabel => 'Counterparty';

  @override
  String get debtFormCounterpartyHint => 'Bank, person…';

  @override
  String get debtFormDueDateLabel => 'Due date';

  @override
  String get debtFormDueDateHint => 'No date';

  @override
  String get debtFormInterestLabel => 'Annual interest (optional)';

  @override
  String get debtFormInterestHint => '0';

  @override
  String get debtFormInterestError => 'Check the interest rate';

  @override
  String get debtFormAccrualModeLabel => 'Interest mode';

  @override
  String get debtFormAccrualManual => 'Manual';

  @override
  String get debtFormAccrualAuto => 'Automatic';

  @override
  String get debtFormAccrualHint =>
      'Manual: you enter the bank\'s figure. Automatic estimates the daily growth (estimated).';

  @override
  String get debtFormCreateCta => 'Create debt';

  @override
  String get debtFormSaveCta => 'Save changes';

  @override
  String get debtFormDelete => 'Delete debt';

  @override
  String get debtCurrencySheetTitle => 'Currency';

  @override
  String debtCurrencyPill(String code, String name) {
    return '$code · $name';
  }

  @override
  String get debtDeleteSheetTitle => 'Delete this debt?';

  @override
  String get debtDeleteSheetMessage => 'You can restore it from the trash.';

  @override
  String debtContext(String name, String direction) {
    return '$name · $direction';
  }

  @override
  String debtDateToday(String date) {
    return 'Today, $date';
  }

  @override
  String get debtPaymentTitle => 'Register payment';

  @override
  String get debtPaymentAmountLabel => 'Payment';

  @override
  String get debtPaymentAddToAccountLabel => 'Add to an account?';

  @override
  String get debtPaymentAddToAccountHintYes =>
      'It will move the balance and count in your stats';

  @override
  String get debtPaymentAddToAccountHintNo =>
      'This payment lowers the debt but won\'t move any account.';

  @override
  String get debtPaymentLinkExisting => 'Already recorded it? Link a movement';

  @override
  String get debtPaymentDateLabel => 'Date';

  @override
  String get debtPaymentNoteLabel => 'Note (optional)';

  @override
  String get debtPaymentNoteHint => 'Add a note';

  @override
  String get debtPaymentCategoryLabel => 'Category (optional)';

  @override
  String get debtPaymentCategoryNone => 'No category';

  @override
  String get debtPaymentSelectAccount => 'Choose an account';

  @override
  String get debtPaymentAccountPickerTitle => 'Choose an account';

  @override
  String get debtPaymentCta => 'Register payment';

  @override
  String get debtPaymentError =>
      'We couldn\'t register the payment. Try again.';

  @override
  String get debtUpdateBalanceTitle => 'Update balance';

  @override
  String get debtUpdateBalanceNewLabel => 'New balance';

  @override
  String get debtUpdateBalanceEstimatedLabel => 'Estimated balance today';

  @override
  String get debtUpdateBalanceAdjustLabel => 'Adjustment recorded';

  @override
  String get debtUpdateBalanceHint =>
      'Records an adjustment on the debt to match the bank\'s figure. It moves no account.';

  @override
  String get debtUpdateBalanceDateLabel => 'Adjustment date';

  @override
  String get debtUpdateBalanceCta => 'Save balance';

  @override
  String get debtUpdateBalanceError =>
      'We couldn\'t update the balance. Try again.';

  @override
  String debtLinkBannerTitle(String debt) {
    return 'Link to $debt';
  }

  @override
  String get debtLinkBannerBody =>
      'Choose a movement you already recorded; we attribute it to this debt instead of creating a new one.';

  @override
  String get debtLinkCancelTooltip => 'Cancel link';

  @override
  String get debtLinkError => 'We couldn\'t link the movement. Try again.';

  @override
  String get moreScheduledPayments => 'Scheduled payments';

  @override
  String get moreScheduledPaymentsDescription =>
      'Automatic payments and income';

  @override
  String get moreReports => 'Charts and reports';

  @override
  String get moreReportsDescription => 'See your finances in charts';

  @override
  String get moreGoalsDescription => 'Save toward your goals';

  @override
  String get moreImportExport => 'Import and export';

  @override
  String get moreImportExportDescription => 'Back up or bring in your data';

  @override
  String get moreSettings => 'Settings';

  @override
  String get moreSettingsDescription => 'Preferences and your account';

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
      'Your accounts and transactions will stay saved on this phone. You\'ll stop syncing until you sign in again.';

  @override
  String get authSignOutSheetMessageDeleting =>
      'You\'ll stop syncing until you sign in again.';

  @override
  String get authSignOutCta => 'Sign out';

  @override
  String get authSignOutDeleteCta => 'Delete and sign out';

  @override
  String get authSignOutDeleteOptInTitle => 'Also delete this phone\'s data';

  @override
  String get authSignOutDeleteOptInSubtitle =>
      'Your cloud account stays untouched: sign in again and you get it all back.';

  @override
  String get authSignOutUnsyncedTitle =>
      'Some changes haven\'t been uploaded yet';

  @override
  String authSignOutUnsyncedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count changes are still saved only on this phone. If you delete now, those changes won\'t make it to the cloud.',
      one:
          '1 change is still saved only on this phone. If you delete now, that change won\'t make it to the cloud.',
    );
    return '$_temp0';
  }

  @override
  String get authSignOutWipeErrorMessage =>
      'We signed you out, but couldn\'t delete this phone\'s data. It\'s still here.';

  @override
  String get authSignOutFailedMessage =>
      'We couldn\'t sign you out, so nothing was deleted from this phone. Please try again.';

  @override
  String get authDeleteStep1Title => 'Delete your account';

  @override
  String get authDeleteStep1Message =>
      'This action is irreversible. All your cloud data will be permanently deleted: accounts, transactions, categories and everything else tied to your account.';

  @override
  String get authDeleteStep1Cta => 'Delete account';

  @override
  String get authDeleteStep1ErrorTitle => 'We couldn\'t delete your account';

  @override
  String get authDeleteStep1ErrorMessage =>
      'There was a problem connecting to the server and we couldn\'t complete the request. Your data is still safe on this device — try again.';

  @override
  String get authDeleteStep2Title =>
      'What should we do with your data on this phone?';

  @override
  String get authDeleteStep2Subtitle =>
      'Your cloud account has already been deleted. Choose what happens to what\'s still saved here, on this device.';

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
  String get settingsBudgetSection => 'Budget';

  @override
  String get settingsPreferencesSection => 'Preferences';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceLight => 'Light';

  @override
  String get settingsAppearanceDark => 'Dark';

  @override
  String get settingsAppearanceSystem => 'System';

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
  String get budgetsEmptyDescription =>
      'Create one to keep an effortless eye on your spending';

  @override
  String get budgetsLoading => 'Loading your budgets';

  @override
  String get budgetsErrorTitle => 'We couldn\'t load your budgets';

  @override
  String get budgetsMenuHistory => 'View history';

  @override
  String get budgetsMenuTooltip => 'More options';

  @override
  String get budgetRemainingLabel => 'You have left';

  @override
  String get budgetOverspentLabel => 'Over by';

  @override
  String get budgetAtRiskLabel => 'Could exceed by';

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
  String budgetEndsInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ends in $count days',
      one: 'Ends in $count day',
      zero: 'Last day',
    );
    return '$_temp0';
  }

  @override
  String budgetProgressBreakdown(String spent, String amount) {
    return '$spent of $amount';
  }

  @override
  String get budgetActivityTitle => 'This period\'s transactions';

  @override
  String budgetActivityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '$count transaction',
    );
    return '$_temp0';
  }

  @override
  String get budgetActivityEmpty => 'No transactions in this period';

  @override
  String get budgetScheduledLabel => 'Scheduled';

  @override
  String budgetScheduledEntrySub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upcoming payments',
      one: '$count upcoming payment',
    );
    return '$_temp0';
  }

  @override
  String budgetScheduledEntrySubRisk(String amount) {
    return 'Would go over budget by $amount';
  }

  @override
  String budgetScheduledCaption(String amount, int pct) {
    return '+ $amount scheduled (reaches $pct% if it goes through)';
  }

  @override
  String budgetScheduledCaptionRisk(String amount, String overage) {
    return '+ $amount scheduled — would go over budget by $overage';
  }

  @override
  String budgetScheduledFreeCaption(String amount) {
    return '$amount would be free if you approve the scheduled payments';
  }

  @override
  String get budgetScheduledSheetTitle => 'Scheduled payments for this period';

  @override
  String get budgetScheduledSheetSeeAll => 'See all scheduled payments';

  @override
  String budgetScheduledSheetHint(String amount) {
    return '$amount of what\'s set aside this period.';
  }

  @override
  String get budgetScheduledSheetEmpty =>
      'No scheduled payments in this period yet';

  @override
  String budgetScheduledRowSubtitle(String date, String accountName) {
    return 'Next: $date · $accountName';
  }

  @override
  String get budgetLoadMore => 'See more';

  @override
  String get budgetOneOffWindow => 'Single window';

  @override
  String get budgetPeriodPreviousTooltip => 'Previous period';

  @override
  String get budgetPeriodNextTooltip => 'Next period';

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
  String get budgetActionDeleteBudget => 'Delete budget';

  @override
  String get budgetActionAdjustAmount => 'Adjust amount — this period';

  @override
  String get budgetDetailActionsSubtitle => 'Budget actions';

  @override
  String get budgetDeleteConfirmMessage =>
      'This budget will be deleted. You can undo this right after deleting.';

  @override
  String get budgetFormNewTitle => 'New budget';

  @override
  String get budgetFormEditTitle => 'Edit budget';

  @override
  String get budgetFormNameLabel => 'Name';

  @override
  String get budgetFormIconNameLabel => 'Icon and name';

  @override
  String budgetFormRowValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get budgetFormScopeAllHint =>
      'Covers all your spending: every account and category.';

  @override
  String get budgetFormNameHint => 'e.g. Monthly groceries';

  @override
  String get budgetErrorName => 'Enter a name for the budget.';

  @override
  String get budgetErrorAmount => 'Enter an amount greater than zero.';

  @override
  String get budgetErrorEndDate => 'Choose an end date after the start date.';

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
  String get budgetFormEndHint => 'Pick a date';

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
  String get budgetThresholdTitle => 'Alert me when I\'ve spent…';

  @override
  String get budgetThresholdHint =>
      'We\'ll send you a local notice when you reach that % — free of charge.';

  @override
  String get budgetThresholdRecommended => 'Recommended';

  @override
  String get budgetThresholdCustom => 'Custom';

  @override
  String get budgetThresholdCustomSubtitle => 'Set your own %';

  @override
  String get budgetThresholdCustomTitle => 'Set your own %';

  @override
  String get budgetThresholdCustomHint =>
      'Adjust the percentage in steps of 5.';

  @override
  String get budgetThresholdOffSubtitle => 'Turns off this budget\'s alert';

  @override
  String get budgetThresholdDecrease => 'Lower the percentage';

  @override
  String get budgetThresholdIncrease => 'Raise the percentage';

  @override
  String get budgetIconSheetTitle => 'Choose icon';

  @override
  String get budgetIconSheetHint =>
      'The icon shows on a neutral background — no color per budget.';

  @override
  String get budgetsHistoryTitle => 'History';

  @override
  String get budgetsHistoryEmpty => 'You haven\'t closed any budgets';

  @override
  String get budgetsHistoryEmptyDescription =>
      'When you close one, you\'ll find it here to review or reactivate';

  @override
  String get budgetsHistoryLoading => 'Loading your history';

  @override
  String get budgetDetailLoading => 'Loading the budget';

  @override
  String get budgetFormLoading => 'Loading the form';

  @override
  String budgetClosedOn(String date) {
    return 'Closed $date';
  }

  @override
  String get budgetsHistorySubtitle => 'Closed budgets';

  @override
  String get budgetsHistoryHint =>
      'You keep them without deleting. Reactivate them whenever you want.';

  @override
  String get budgetsMenuOptions => 'Options';

  @override
  String get budgetsMenuHistorySubtitle => 'Closed budgets';

  @override
  String get budgetsMenuEnableEnvelope => 'Turn on envelope mode';

  @override
  String get budgetsMenuEnableEnvelopeSubtitle =>
      'Split all your income into envelopes';

  @override
  String get budgetsMenuDisableEnvelopeSubtitle => 'Back to the normal list';

  @override
  String get budgetsEnvelopeBadge => 'Envelope mode';

  @override
  String budgetsEnvelopeIncome(String income) {
    return 'Income $income';
  }

  @override
  String budgetsEnvelopeAssigned(String assigned) {
    return 'Assigned $assigned';
  }

  @override
  String budgetsEnvelopeNudge(String amount) {
    return 'Almost there: give the remaining $amount a job.';
  }

  @override
  String budgetsEnvelopeNudgeOver(String amount) {
    return 'You assigned $amount more than came in. Adjust an envelope whenever you like.';
  }

  @override
  String get budgetAssignedLabel => 'Assigned';

  @override
  String get budgetReactivate => 'Reactivate';

  @override
  String get budgetResultWithin => 'Ended within budget';

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
      'Split your entire income into envelopes';

  @override
  String get settingsEnvelopeWhatIs => 'What is it?';

  @override
  String get envelopeInfoTitle => 'What is envelope mode?';

  @override
  String get envelopeInfoBody =>
      'It\'s a way of budgeting where you give every cent a job. You split all of the month\'s income into \'envelopes\' — your budgets — until nothing is left unassigned.';

  @override
  String get envelopeInfoBulletJobs =>
      'That\'s how you decide where your money goes before you spend it: spend, save or pay off debt.';

  @override
  String get envelopeInfoBulletZero =>
      'When \'Unassigned\' reaches \$0, every cent has a purpose.';

  @override
  String get envelopeInfoReassure =>
      'It\'s optional and blocks nothing. Turn it on or off whenever you like.';

  @override
  String get envelopeInfoActivate => 'Turn on envelope mode';

  @override
  String get envelopeInfoGotIt => 'Got it';

  @override
  String get budgetsMenuDisableEnvelope => 'Turn off envelope mode';

  @override
  String get budgetsEnvelopeUnassignedLabel => 'Unassigned this month';

  @override
  String get budgetsEnvelopeOverLabel => 'Over-assigned';

  @override
  String get budgetsEnvelopeAllAssigned => 'Every cent has a job';

  @override
  String get firstLaunchOfflineTitle => 'Connect to continue';

  @override
  String get firstLaunchOfflineSubtitle =>
      'We need an internet connection to finish setting up your account. Try again once you have signal.';

  @override
  String get firstLaunchOfflineRetrying => 'Retrying...';

  @override
  String get splashLoadingCaption => 'Loading your finances...';

  @override
  String get brandWordmarkPrefix => 'b';

  @override
  String get brandWordmarkDotlessI => 'ı';

  @override
  String get brandWordmarkSuffix => 'lletudo';

  @override
  String get scheduledPaymentsTitle => 'Scheduled payments';

  @override
  String get scheduledPaymentsAdd => 'New scheduled payment';

  @override
  String get scheduledPaymentsLoading => 'Loading your scheduled payments';

  @override
  String get scheduledPaymentUntitled => 'Scheduled payment';

  @override
  String get scheduledPaymentsEmptyMessage =>
      'You have no scheduled payments yet';

  @override
  String get scheduledPaymentsErrorTitle =>
      'We couldn\'t load your scheduled payments';

  @override
  String get scheduledPaymentsErrorLocalFirst =>
      'Your data is still stored on your device. Try again.';

  @override
  String scheduledPaymentsActiveCount(int count) {
    return 'Active · $count';
  }

  @override
  String get scheduledPendingTitle => 'Pending confirmation';

  @override
  String get scheduledPendingEmpty =>
      'You don\'t have any payments to confirm.';

  @override
  String get scheduledReviewAll => 'Review all';

  @override
  String get scheduledPendingBadge => 'Pending confirmation';

  @override
  String get scheduledOnceBadge => 'One-time payment';

  @override
  String get scheduledInactiveBadge => 'Inactive';

  @override
  String get scheduledConfirmationSheetTitle => 'Confirm payment';

  @override
  String get scheduledConfirmationSheetConfirm => 'Confirm';

  @override
  String get scheduledConfirmationSheetSkip => 'Skip';

  @override
  String get scheduledConfirmationSheetSnooze => 'Snooze';

  @override
  String scheduledGuidedReviewPosition(int position, int total) {
    return 'Payment $position of $total';
  }

  @override
  String get scheduledUndoSkipMessage => 'Payment skipped';

  @override
  String get scheduledUndoSnoozeMessage => 'Payment snoozed';

  @override
  String get scheduledSnoozeSheetTitle => 'Snooze payment';

  @override
  String get scheduledSnoozeSheetSave => 'Snooze';

  @override
  String get scheduledDeleteSheetTitle => 'Delete this scheduled payment?';

  @override
  String get scheduledDeleteSheetMessage =>
      'Future payments stop being generated. The transactions it already generated stay in your history.';

  @override
  String get scheduledDeleteSheetTitleInstallment => 'Delete this installment?';

  @override
  String get scheduledDeleteSheetMessageInstallment =>
      'The installment stops being scheduled. The debt and the payments it already recorded stay in your history.';

  @override
  String get scheduledPaymentFormNewTitle => 'New scheduled payment';

  @override
  String get scheduledPaymentFormEditTitle => 'Edit scheduled payment';

  @override
  String get scheduledPaymentFormNextDateLabel => 'First payment';

  @override
  String get scheduledPaymentFormOnceDateLabel => 'Payment date';

  @override
  String get scheduledPaymentFormModeSectionLabel => 'When the date arrives';

  @override
  String get scheduledPaymentFormTagNew => 'Tag';

  @override
  String get scheduledPaymentFormFrequencyLabel => 'Frequency';

  @override
  String get scheduledPaymentFormCategoryMoreLabel => 'Other';

  @override
  String get scheduledPaymentErrorAccount => 'Choose an account.';

  @override
  String get scheduledPaymentErrorAmount =>
      'Enter an amount greater than zero.';

  @override
  String get scheduledPaymentErrorTransferAccount =>
      'Choose the destination account.';

  @override
  String get scheduledPaymentErrorCategory => 'Choose a category.';

  @override
  String get scheduledPaymentInstallmentAmountExceedsError =>
      'The installment can\'t be larger than the debt balance.';

  @override
  String get scheduledPaymentFormIntervalStepperLabel => 'Repeat every';

  @override
  String get scheduledPaymentFormEndDateLabel => 'Ends';

  @override
  String get scheduledPaymentFormEndDateNone => 'Forever';

  @override
  String get scheduledPaymentFormModeAutomaticTitle => 'Automatic';

  @override
  String get scheduledPaymentFormModeAutomaticSubtitle =>
      'Records itself when the date arrives';

  @override
  String get scheduledPaymentFormModeManualTitle => 'Manual';

  @override
  String get scheduledPaymentFormModeManualSubtitle =>
      'For now, you\'ll need to confirm it yourself';

  @override
  String get scheduledPaymentFormDeleteAction => 'Delete scheduled payment';

  @override
  String get scheduledPaymentInstallmentTitle => 'Set up installment';

  @override
  String get scheduledPaymentInstallmentEditTitle => 'Edit installment';

  @override
  String get scheduledPaymentInstallmentDeleteAction => 'Delete installment';

  @override
  String get scheduledPaymentInstallmentBanner =>
      'This creates a scheduled payment linked to this debt. Confirm or postpone it in Scheduled payments.';

  @override
  String get scheduledPaymentDetailLinkedDebtLabel => 'Installment of';

  @override
  String get scheduledDebtChipLabel => 'Debt';

  @override
  String get scheduledFrequencyOnce => 'Once only';

  @override
  String get scheduledFrequencyDaily => 'every day';

  @override
  String get scheduledFrequencyWeekly => 'every week';

  @override
  String get scheduledFrequencyMonthly => 'every month';

  @override
  String get scheduledFrequencyYearly => 'every year';

  @override
  String get scheduledFrequencyChipOnce => 'Once';

  @override
  String get scheduledFrequencyChipDaily => 'Day';

  @override
  String get scheduledFrequencyChipWeekly => 'Week';

  @override
  String get scheduledFrequencyChipMonthly => 'Month';

  @override
  String get scheduledFrequencyChipYearly => 'Year';

  @override
  String get scheduledPaymentDetailTitle => 'Detail';

  @override
  String scheduledPaymentDetailNextPayment(String date) {
    return 'Next payment: $date';
  }

  @override
  String get scheduledPaymentDetailHistoryTitle => 'History';

  @override
  String get scheduledPaymentDetailHistoryEmpty =>
      'No transaction has been generated for this scheduled payment yet.';

  @override
  String scheduledPaymentDetailHistorySeeAll(int count) {
    return 'See full history ($count)';
  }

  @override
  String get scheduledSkippedBadge => 'Skipped';

  @override
  String get scheduledRecoverAction => 'Recover';

  @override
  String get scheduledRecoverMessage => 'Payment recovered';

  @override
  String get scheduledPaymentDetailHeroLabel => 'NEXT PAYMENT';

  @override
  String scheduledPaymentDetailRecurrenceOnce(String date) {
    return 'Just once on $date';
  }

  @override
  String scheduledPaymentDetailRecurrenceForever(String unit, String date) {
    return 'Repeats $unit from $date, forever';
  }

  @override
  String scheduledPaymentDetailRecurrenceUntil(
      String unit, String date, String endDate) {
    return 'Repeats $unit from $date, until $endDate';
  }

  @override
  String get scheduledRecurrenceUnitDaily => 'every day';

  @override
  String scheduledRecurrenceUnitDailyInterval(int interval) {
    return 'every $interval days';
  }

  @override
  String get scheduledRecurrenceUnitWeekly => 'every week';

  @override
  String scheduledRecurrenceUnitWeeklyInterval(int interval) {
    return 'every $interval weeks';
  }

  @override
  String get scheduledRecurrenceUnitMonthly => 'every month';

  @override
  String scheduledRecurrenceUnitMonthlyInterval(int interval) {
    return 'every $interval months';
  }

  @override
  String get scheduledRecurrenceUnitYearly => 'every year';

  @override
  String scheduledRecurrenceUnitYearlyInterval(int interval) {
    return 'every $interval years';
  }

  @override
  String get scheduledPaymentDetailModeLabel => 'Recording mode';

  @override
  String get scheduledPaymentDetailModeAutomatic => 'Automatic';

  @override
  String get scheduledPaymentDetailModeManual => 'Manual';

  @override
  String get scheduledPaymentDetailAccountLabel => 'Account';

  @override
  String get scheduledPaymentDetailStatusLabel => 'Status';

  @override
  String get scheduledPaymentDetailStatusActive => 'Active';

  @override
  String get scheduledPaymentDetailStatusFinished => 'Finished';

  @override
  String get scheduledPaymentDetailHeroLabelExecuted => 'PAYMENT MADE';

  @override
  String get scheduledPaymentDetailConfirmNowCta => 'Confirm now';

  @override
  String get scheduledPaymentDetailConfirmNowError =>
      'We couldn\'t confirm this payment now. Please try again.';

  @override
  String get scheduledPaymentDetailTagsLabel => 'Tags';

  @override
  String get scheduledPaymentDetailTagsEmpty => 'No tags';

  @override
  String get scheduledPaymentBridgeTitle => 'Is this a scheduled payment?';

  @override
  String get scheduledPaymentBridgeMessage =>
      'You picked a future date. A future-dated movement is saved as a scheduled payment, so it only applies once the day arrives.';

  @override
  String get scheduledPaymentBridgeAccept => 'Yes, schedule it';

  @override
  String get scheduledPaymentBridgeDecline => 'Change the date';

  @override
  String scheduledFinishedCount(int count) {
    return 'Finished · $count';
  }

  @override
  String get scheduledFinishedCaption =>
      'They no longer create transactions. The ones they already created stay in your accounts.';

  @override
  String get scheduledFinishedCardChip => 'Finished';

  @override
  String get scheduledFinishedErrorTitle =>
      'We couldn\'t load your finished payments';

  @override
  String scheduledFinishedLastPayment(String date) {
    return 'Last payment · $date';
  }

  @override
  String get scheduledPaymentsNoActiveMessage =>
      'You don\'t have any active scheduled payments right now';

  @override
  String scheduledPaymentsNoActiveDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Your $count finished payments are still available under \"Finished\".',
      one: 'Your finished payment is still available under \"Finished\".',
    );
    return '$_temp0';
  }

  @override
  String scheduledPendingCardOverflow(int count) {
    return 'See the other $count pending';
  }

  @override
  String scheduledPendingCardTitle(int count) {
    return 'Pending confirmation $count';
  }

  @override
  String get scheduledPendingCardCaption =>
      'They haven\'t affected your balance yet';

  @override
  String get scheduledPaymentsEmptyCta => 'Schedule a payment';

  @override
  String get scheduledManualNotifyChip => 'We\'ll remind you';

  @override
  String get scheduledDueToday => 'Due today';

  @override
  String get scheduledDueOneDayAgo => '1 day ago';

  @override
  String scheduledDueDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String scheduledDueInDays(int count) {
    return 'in $count days';
  }

  @override
  String get scheduledDueInOneDay => 'in 1 day';

  @override
  String scheduledConfirmationSheetScopeNote(String amount) {
    return 'What you edit applies to this payment only. The template stays the same and next month it will propose $amount again.';
  }

  @override
  String scheduledConfirmationSheetAccumulatedTitle(
      int count, String template) {
    return 'You have $count unconfirmed payments for $template';
  }

  @override
  String scheduledConfirmationSheetAccumulatedSub(String date, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: 'The other $others stay on your list.',
      one: 'The other one stays on your list.',
    );
    return 'You\'re now confirming the oldest one, from $date. $_temp0';
  }

  @override
  String get scheduledConfirmationSheetAmountLabel => 'Amount to record';

  @override
  String get scheduledConfirmationSheetTransferAmountLabel =>
      'Amount to transfer';

  @override
  String get scheduledConfirmationSheetSourceAccountLabel => 'From account';

  @override
  String get scheduledConfirmationSheetTargetAccountLabel => 'To account';

  @override
  String get scheduledDetailActionsSheetSubtitle => 'Scheduled payment actions';

  @override
  String get scheduledDetailActionsSnooze => 'Snooze this payment';

  @override
  String get scheduledDetailActionsDelete => 'Delete scheduled payment';

  @override
  String get scheduledDetailActionsDeleteInstallment => 'Delete installment';

  @override
  String get scheduledSnoozeSheetSectionTitle => 'Pick the new date';

  @override
  String get scheduledConfirmationSheetEditTooltip => 'Edit template';

  @override
  String get scheduledGuidedReviewExit => 'Exit';

  @override
  String get scheduledGuidedReviewConfirmNext => 'Confirm and next';

  @override
  String scheduledSnoozeContextLine(String date) {
    return 'Was due on $date · move it forward';
  }

  @override
  String get budgetAdjustSheetTitle => 'Adjust amount';

  @override
  String budgetAdjustCurrentAmountInline(String amount) {
    return 'Current $amount';
  }

  @override
  String budgetAdjustNewAmountLabel(String range) {
    return 'New amount · $range';
  }

  @override
  String budgetAdjustExplainer(String resumeDate, String originalAmount) {
    return 'On $resumeDate it goes back to $originalAmount automatically.';
  }

  @override
  String get budgetAdjustApplyCta => 'Apply changes';

  @override
  String get budgetAdjustRemoveCta => 'Revert adjustment';

  @override
  String get budgetAdjustBannerLabel => 'Amount adjustment';

  @override
  String budgetAdjustBannerSub(String amount, String range) {
    return '$amount · $range';
  }

  @override
  String get budgetAdjustScheduledSnackbar =>
      'Adjustment scheduled for the selected period.';

  @override
  String get budgetAdjustUpdatedSnackbar => 'Adjustment updated.';

  @override
  String get budgetAdjustCancelledSnackbar =>
      'Adjustment reverted — the period goes back to the usual amount.';
}
