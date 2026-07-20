import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/month_calendar.dart';
import '../../../domain/entities/scheduled_payment_occurrence.dart';
import '../../cubit/snooze_sheet_cubit.dart';
import '../../cubit/snooze_sheet_state.dart';
import 'scheduled_sheet_icon_header.dart';

/// HU-07's Posponer sheet: moves a single occurrence to a later date, floor
/// `max(fecha original, hoy)` (criterion 10). Reuses the app's own
/// [MonthCalendar] (`w4yuu`) directly — the sheet's job is only to pick the
/// date within the allowed floor and save.
class SnoozeSheet extends StatelessWidget {
  const SnoozeSheet({
    required this.scheduledPaymentId,
    required this.occurrenceDate,
    required this.templateName,
    required this.isTransfer,
    this.categoryIcon,
    this.categoryColor,
    super.key,
  });

  final String scheduledPaymentId;
  final DateTime occurrenceDate;

  /// The template's display name (`ScheduledPaymentFormat.templateName`),
  /// shown in the sheet's icon header so the user knows exactly which payment
  /// they are moving.
  final String templateName;

  final bool isTransfer;
  final String? categoryIcon;
  final String? categoryColor;

  /// Returns the resulting occurrence on success (so the caller can offer
  /// "Deshacer"), or `null` when dismissed/failed.
  static Future<ScheduledPaymentOccurrence?> show(
    BuildContext context, {
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    required String templateName,
    required bool isTransfer,
    String? categoryIcon,
    String? categoryColor,
  }) =>
      // Not `BottomSheetBase.show`: the body below already builds its own
      // `BottomSheetBase` wrapper directly, so this keeps
      // `showModalBottomSheet` as-is and just opts into the root navigator.
      showModalBottomSheet<ScheduledPaymentOccurrence>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (context) => SnoozeSheet(
          scheduledPaymentId: scheduledPaymentId,
          occurrenceDate: occurrenceDate,
          templateName: templateName,
          isTransfer: isTransfer,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SnoozeSheetCubit>()
        ..start(
            scheduledPaymentId: scheduledPaymentId,
            occurrenceDate: occurrenceDate),
      child: SnoozeSheetBody(
        templateName: templateName,
        occurrenceDate: occurrenceDate,
        isTransfer: isTransfer,
        categoryIcon: categoryIcon,
        categoryColor: categoryColor,
      ),
    );
  }
}

class SnoozeSheetBody extends StatelessWidget {
  const SnoozeSheetBody({
    required this.templateName,
    required this.occurrenceDate,
    required this.isTransfer,
    this.categoryIcon,
    this.categoryColor,
    super.key,
  });

  final String templateName;
  final DateTime occurrenceDate;
  final bool isTransfer;
  final String? categoryIcon;
  final String? categoryColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return BlocConsumer<SnoozeSheetCubit, SnoozeSheetState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SnoozeSheetStatus.saved) {
          Navigator.of(context).pop(state.saved);
        }
      },
      builder: (context, state) {
        final cubit = context.read<SnoozeSheetCubit>();
        return BottomSheetBase(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScheduledSheetIconHeader(
                title: templateName,
                subtitle: l10n.scheduledSnoozeContextLine(
                  DateFormat.yMMMd(Localizations.localeOf(context).toString())
                      .format(occurrenceDate),
                ),
                isTransfer: isTransfer,
                categoryIcon: categoryIcon,
                categoryColor: categoryColor,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.scheduledSnoozeSheetSectionTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              MonthCalendarBridge(
                minDate: state.minDate,
                selectedDate: state.selectedDate,
                onSelected: cubit.dateSelected,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isSaving ? null : cubit.save,
                  child: Text(l10n.scheduledSnoozeSheetSave),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bridges the app's own [MonthCalendar] with a hard floor: days before
/// [minDate] render disabled, as `max(fecha original, hoy)` demands
/// (criterion 10). `MonthCalendar` has no built-in floor, so this wraps it
/// with an `IgnorePointer` per out-of-range day via a filtered `onDaySelected`.
class MonthCalendarBridge extends StatefulWidget {
  const MonthCalendarBridge({
    required this.minDate,
    required this.selectedDate,
    required this.onSelected,
    super.key,
  });

  final DateTime minDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  State<MonthCalendarBridge> createState() => _MonthCalendarBridgeState();
}

class _MonthCalendarBridgeState extends State<MonthCalendarBridge> {
  late DateTime _visibleMonth =
      DateTime(widget.selectedDate.year, widget.selectedDate.month);

  @override
  Widget build(BuildContext context) {
    return MonthCalendar(
      visibleMonth: _visibleMonth,
      selected: widget.selectedDate,
      disabledBefore: widget.minDate,
      onDaySelected: (date) {
        if (date.isBefore(widget.minDate)) {
          return;
        }
        widget.onSelected(date);
      },
      onPreviousMonth: () => setState(
        () => _visibleMonth =
            DateTime(_visibleMonth.year, _visibleMonth.month - 1),
      ),
      onNextMonth: () => setState(
        () => _visibleMonth =
            DateTime(_visibleMonth.year, _visibleMonth.month + 1),
      ),
    );
  }
}
