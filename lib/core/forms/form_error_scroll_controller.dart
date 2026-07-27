import 'dart:async';

import 'package:flutter/widgets.dart';

/// Registry of per-field keys that scrolls the first invalid field into view.
///
/// A form registers a key for each field that can fail validation via
/// [keyFor], attaching it to the widget that wraps the field (typically with a
/// [KeyedSubtree]). When validation fails, the page calls [scrollToField] with
/// the offending field name — usually from a bloc listener watching the
/// state's `failedField` — and that field is brought into view.
///
/// Fields with no registered key (e.g. an amount pinned outside the scroll
/// area) are ignored, so the same call is safe to make from every form even
/// when the failing field is not scrollable.
///
/// The controller must outlive rebuilds — own it in a [State], never recreate
/// it inside `build`, so the keys stay attached to the same elements.
class FormErrorScrollController {
  final Map<String, GlobalKey> _keys = <String, GlobalKey>{};

  /// A stable key for [field], created on first use and reused afterwards.
  ///
  /// Attach it to the field's wrapper, e.g.
  /// `KeyedSubtree(key: controller.keyFor(field), child: ...)`.
  GlobalKey keyFor(String field) => _keys.putIfAbsent(field, GlobalKey.new);

  /// Brings the widget registered for [field] into view on the next frame.
  ///
  /// A no-op when [field] is null or has no mounted key. Scheduled after the
  /// frame so it runs once the failing state has been laid out (the error text
  /// that appears can change a field's height).
  void scrollToField(String? field) {
    if (field == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? context = _keys[field]?.currentContext;
      if (context == null) {
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          context,
          alignment: 0.1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
        ),
      );
    });
  }
}
