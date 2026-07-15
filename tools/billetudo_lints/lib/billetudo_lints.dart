import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/avoid_hardcoded_ui_strings.dart';
import 'src/avoid_private_widgets.dart';
import 'src/avoid_widget_functions.dart';

/// Entry point read by custom_lint. The rules encode the conventions in
/// `docs/convenciones-de-codigo.md` that no official Dart lint covers.
PluginBase createPlugin() => _BilletudoLints();

class _BilletudoLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
        AvoidWidgetFunctions(),
        AvoidPrivateWidgets(),
        AvoidHardcodedUiStrings(),
      ];
}
