import 'package:flutter/widgets.dart';

/// Drops the system keyboard before a selector sheet/picker opens.
///
/// Unfocusing the primary focus itself (not `FocusScope.of(context)`) removes
/// the field from every enclosing scope's focus history, so the modal route has
/// nothing to restore on close. `FocusScope.of(context).unfocus()` only clears
/// the nearest scope and leaves the field registered in a nested scope, so the
/// route re-focuses it on close and the keyboard springs back up — verified in
/// the deudas form, whose fields sit under a nested scope.
///
/// The focus change is applied on a microtask, so awaiting one tick here lets
/// the field lose focus BEFORE the sheet route is pushed; otherwise the route
/// captures the still-focused field. Callers must re-check `context.mounted`
/// before using the context again.
Future<void> dismissSystemKeyboard(BuildContext context) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(Duration.zero);
}
