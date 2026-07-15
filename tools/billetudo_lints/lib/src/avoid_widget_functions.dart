import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'widget_type.dart';

/// Flags named functions and methods that return a `Widget`.
///
/// A widget-returning helper is invisible to the framework: it has no element
/// in the tree, so Flutter cannot mark it dirty on its own, skip its rebuild
/// via `const`, or show it in the inspector. Extracting a `StatelessWidget`
/// costs a few more lines and restores all three.
///
/// `build` overrides are allowed, as is any anonymous closure — a `builder:`
/// callback is the framework's own extension point, not this anti-pattern.
class AvoidWidgetFunctions extends DartLintRule {
  const AvoidWidgetFunctions() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_widget_functions',
    problemMessage:
        'Functions must not return a Widget. Extract a StatelessWidget or '
        'StatefulWidget subclass instead.',
    correctionMessage:
        'Turn this into a widget class so it gets its own element, const '
        'rebuild skipping and an entry in the widget inspector.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (!isAppSource(resolver.path)) return;

    context.registry.addFunctionDeclaration((node) {
      if (!isWidgetType(node.returnType?.type)) return;
      reporter.atToken(node.name, code);
    });

    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme == 'build') return;
      if (!isWidgetType(node.returnType?.type)) return;
      reporter.atToken(node.name, code);
    });
  }
}
