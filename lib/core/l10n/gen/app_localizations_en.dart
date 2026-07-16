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
}
