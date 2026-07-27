import '../../domain/entities/pending_scheduled_occurrence.dart';

/// One "por confirmar" row: the oldest pending occurrence of a template plus
/// how many occurrences of that same template are pending.
///
/// The design shows a template once, with a "×N" chip, instead of repeating
/// the row per occurrence (page spec, "Casos cubiertos en el canvas"), and
/// confirming resolves the oldest one first — so [entry] is the oldest.
class PendingOccurrenceGroup {
  const PendingOccurrenceGroup({required this.entry, required this.count});

  final PendingScheduledOccurrence entry;
  final int count;

  /// Collapses [items] (already ordered by effective date ascending) into one
  /// group per template, preserving that order.
  static List<PendingOccurrenceGroup> groupByTemplate(
    List<PendingScheduledOccurrence> items,
  ) {
    final order = <String>[];
    final firstByTemplate = <String, PendingScheduledOccurrence>{};
    final counts = <String, int>{};
    for (final item in items) {
      final id = item.scheduledPayment.id;
      if (!firstByTemplate.containsKey(id)) {
        order.add(id);
        firstByTemplate[id] = item;
      }
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return [
      for (final id in order)
        PendingOccurrenceGroup(
          entry: firstByTemplate[id]!,
          count: counts[id]!,
        ),
    ];
  }
}
