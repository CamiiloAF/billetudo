import 'package:billetudo/features/scheduled_payments/presentation/utils/pending_occurrence_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scheduled_payment_fixtures.dart';

void main() {
  test('collapses occurrences of the same template into one counted group', () {
    final items = [
      buildPendingOccurrence(
        occurrence: buildOccurrence(),
        scheduledPayment: buildScheduledPayment(),
      ),
      buildPendingOccurrence(
        occurrence: buildOccurrence(id: 'occ-2'),
        scheduledPayment: buildScheduledPayment(id: 'sp-2'),
      ),
      buildPendingOccurrence(
        occurrence: buildOccurrence(id: 'occ-3'),
        scheduledPayment: buildScheduledPayment(),
      ),
    ];

    final groups = PendingOccurrenceGroup.groupByTemplate(items);

    expect(groups.length, 2);
    // Order is preserved and the kept entry is the oldest of its template.
    expect(groups.first.entry.occurrence.id, 'occ-1');
    expect(groups.first.count, 2);
    expect(groups.last.entry.occurrence.id, 'occ-2');
    expect(groups.last.count, 1);
  });

  test('an empty list produces no groups', () {
    expect(PendingOccurrenceGroup.groupByTemplate(const []), isEmpty);
  });
}
