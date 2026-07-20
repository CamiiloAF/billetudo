import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../domain/entities/scheduled_payment.dart';
import '../../domain/entities/scheduled_payment_draft.dart';
import '../../domain/usecases/create_scheduled_payment.dart';
import '../../domain/usecases/delete_scheduled_payment.dart';
import '../../domain/usecases/get_scheduled_payment_detail.dart';
import '../../domain/usecases/set_scheduled_payment_tags.dart';
import '../../domain/usecases/update_scheduled_payment.dart';
import 'scheduled_payment_form_state.dart';

/// Drives the create/edit template form (HU-01/HU-05), including the puente
/// from Transacciones (HU-06, criterion 14): [loadFromBridge] prefills a new
/// template from a future-dated movement without either feature's domain
/// depending on the other — the bridge only ever hands this cubit plain
/// values.
@injectable
class ScheduledPaymentFormCubit extends Cubit<ScheduledPaymentFormState> {
  ScheduledPaymentFormCubit(
    this._createScheduledPayment,
    this._updateScheduledPayment,
    this._getScheduledPaymentDetail,
    this._setScheduledPaymentTags,
    this._deleteScheduledPayment,
  ) : super(ScheduledPaymentFormState());

  final CreateScheduledPayment _createScheduledPayment;
  final UpdateScheduledPayment _updateScheduledPayment;
  final GetScheduledPaymentDetail _getScheduledPaymentDetail;
  final SetScheduledPaymentTags _setScheduledPaymentTags;
  final DeleteScheduledPayment _deleteScheduledPayment;

  /// Loads the template to edit, or prepares an empty form when [id] is null.
  Future<void> load(String? id) async {
    if (id == null) {
      emit(
        ScheduledPaymentFormState(
          status: ScheduledPaymentFormStatus.ready,
          nextDate: DateTime.now(),
        ),
      );
      return;
    }

    emit(ScheduledPaymentFormState());
    final result = await _getScheduledPaymentDetail(id).first;
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          ScheduledPaymentFormState(
            status: ScheduledPaymentFormStatus.failure,
            failure: failure,
          ),
        );
      case Right(value: final detail):
        final payment = detail.scheduledPayment;
        emit(
          ScheduledPaymentFormState(
            status: ScheduledPaymentFormStatus.ready,
            id: payment.id,
            accountId: payment.accountId,
            accountName: detail.accountName,
            categoryId: payment.categoryId,
            categoryName: detail.categoryName,
            amountText: const MoneyFormatter().formatAmount(
              payment.amountMinor,
              decimalDigits: MoneyFormatter.currencyDecimals(payment.currency),
            ),
            currency: payment.currency,
            type: payment.type,
            note: payment.note ?? '',
            transferAccountId: payment.transferAccountId,
            transferAccountName: detail.transferAccountName,
            frequency: payment.frequency,
            interval: payment.interval,
            // `firstPaymentDate` (immutable), never the live `nextDate`
            // cursor — showing the cursor here made "Primer pago" appear to
            // change on its own as the catch-up generator advanced it.
            nextDate: payment.firstPaymentDate,
            originalNextDate: payment.nextDate,
            endDate: payment.endDate,
            requiresConfirmation: payment.requiresConfirmation,
            tagIds: {for (final tag in detail.tags) tag.id},
          ),
        );
    }
  }

  /// HU-06/criterion 14: prefills a brand-new `once` template from a
  /// future-dated transaction the user accepted turning into a scheduled
  /// payment.
  void loadFromBridge({
    required String accountId,
    required String accountName,
    required int amountMinor,
    required String currency,
    required ScheduledPaymentType type,
    required DateTime nextDate,
    String? categoryId,
    CategoryKind? categoryKind,
    String? categoryName,
    String? note,
    Set<String> tagIds = const <String>{},
  }) {
    emit(
      ScheduledPaymentFormState(
        status: ScheduledPaymentFormStatus.ready,
        accountId: accountId,
        accountName: accountName,
        categoryId: categoryId,
        categoryKind: categoryKind,
        categoryName: categoryName,
        amountText: const MoneyFormatter().formatAmount(
          amountMinor,
          decimalDigits: MoneyFormatter.currencyDecimals(currency),
        ),
        currency: currency,
        type: type,
        note: note ?? '',
        frequency: ScheduledPaymentFrequency.once,
        nextDate: nextDate,
        tagIds: tagIds,
      ),
    );
  }

  void typeSelected(ScheduledPaymentType type) => emit(
        state.copyWith(
          type: type,
          clearCategory: type == ScheduledPaymentType.transfer,
          clearTransferAccount: type != ScheduledPaymentType.transfer,
        ),
      );

  void accountSelected(String id, String name) =>
      emit(state.copyWith(accountId: id, accountName: name));

  void transferAccountSelected(String id, String name) =>
      emit(state.copyWith(transferAccountId: id, transferAccountName: name));

  void categorySelected(String? id, CategoryKind? kind, String? name) => emit(
        id == null
            ? state.copyWith(clearCategory: true)
            : state.copyWith(
                categoryId: id, categoryKind: kind, categoryName: name),
      );

  void amountTextChanged(String value) =>
      emit(state.copyWith(amountText: value));

  /// Same as [amountTextChanged], but for the anchored "Zona Fija" amount
  /// field (`ScheduledPaymentEditableAmountField`, shared with the
  /// confirmation sheet), which reports whole cents instead of raw text.
  void amountChanged(int amountMinor) => emit(
        state.copyWith(
          amountText: const MoneyFormatter().formatAmount(
            amountMinor,
            decimalDigits: MoneyFormatter.currencyDecimals(state.currency),
          ),
        ),
      );

  void currencyChanged(String value) => emit(state.copyWith(currency: value));

  void noteChanged(String value) => emit(state.copyWith(note: value));

  void frequencyChanged(ScheduledPaymentFrequency frequency) => emit(
        state.copyWith(
          frequency: frequency,
          interval:
              frequency == ScheduledPaymentFrequency.once ? 1 : state.interval,
        ),
      );

  void intervalChanged(int interval) =>
      emit(state.copyWith(interval: interval));

  void nextDateChanged(DateTime date) => emit(
        state.copyWith(nextDate: date, nextDateEdited: true),
      );

  void endDateChanged(DateTime? date) => date == null
      ? emit(state.copyWith(clearEndDate: true))
      : emit(state.copyWith(endDate: date));

  // ignore: avoid_positional_boolean_parameters
  void requiresConfirmationChanged(bool value) =>
      emit(state.copyWith(requiresConfirmation: value));

  void tagsChanged(Set<String> tagIds) => emit(state.copyWith(tagIds: tagIds));

  /// Deletes the template being edited (HU-05), reachable from the form's
  /// `Delete Link` — same tombstone as the detail page's own delete flow
  /// (`ScheduledPaymentDetailCubit.confirmDelete`), just triggered from one
  /// step further in. Only valid while editing; a brand-new, unsaved
  /// template has nothing to delete yet.
  Future<void> delete() async {
    final id = state.id;
    if (id == null) {
      return;
    }
    emit(state.copyWith(status: ScheduledPaymentFormStatus.saving));
    final result = await _deleteScheduledPayment(id);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: ScheduledPaymentFormStatus.ready,
            failure: failure,
          ),
        );
      case Right():
        emit(state.copyWith(status: ScheduledPaymentFormStatus.deleted));
    }
  }

  Future<void> submit() async {
    final Result<ScheduledPaymentDraft> validated = _buildDraft();
    final ScheduledPaymentDraft draft;
    switch (validated) {
      case Left(value: final failure):
        emit(state.copyWith(failure: failure));
        return;
      case Right(value: final built):
        draft = built;
    }

    emit(state.copyWith(status: ScheduledPaymentFormStatus.saving));
    final result = state.isEditing
        ? await _updateScheduledPayment(draft)
        : await _createScheduledPayment(draft);
    if (isClosed) {
      return;
    }

    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: ScheduledPaymentFormStatus.ready,
            failure: failure,
          ),
        );
      case Right(value: final saved):
        final tagsResult = await _setScheduledPaymentTags(
          saved.id,
          state.tagIds.toList(),
        );
        if (isClosed) {
          return;
        }
        if (tagsResult case Left(value: final failure)) {
          emit(
            state.copyWith(
              status: ScheduledPaymentFormStatus.ready,
              failure: failure,
            ),
          );
          return;
        }
        emit(state.copyWith(status: ScheduledPaymentFormStatus.saved));
    }
  }

  Result<ScheduledPaymentDraft> _buildDraft() {
    final accountId = state.accountId;
    if (accountId == null) {
      return const Left(
        ValidationFailure(
          'an account is required',
          field: ScheduledPaymentDraft.fieldAccountId,
        ),
      );
    }
    final amountMinor = MoneyFormatter.parseMinor(state.amountText) ?? 0;

    // While editing, the date field displays `firstPaymentDate` (see
    // `load()`), not the live `nextDate` cursor — so an edit-and-save that
    // never touches the date must resubmit the cursor untouched instead of
    // resetting it back to the first payment date. Only an explicit edit
    // (`nextDateChanged`, HU-05's "modificar ... la fecha") overrides it.
    final effectiveNextDate = state.isEditing &&
            !state.nextDateEdited &&
            state.originalNextDate != null
        ? state.originalNextDate!
        : state.nextDate;

    return ScheduledPaymentDraft(
      id: state.id,
      accountId: accountId,
      categoryId: state.categoryId,
      categoryKind: state.categoryKind,
      amountMinor: amountMinor,
      currency: state.currency,
      type: state.type,
      note: state.note,
      transferAccountId: state.transferAccountId,
      frequency: state.frequency,
      interval: state.interval,
      nextDate: effectiveNextDate,
      endDate: state.endDate,
      requiresConfirmation: state.requiresConfirmation,
      tagIds: state.tagIds.toList(),
    ).validated();
  }
}
