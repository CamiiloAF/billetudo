import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'widget_type.dart';

/// Flags widget classes whose name starts with `_`.
///
/// A private widget cannot be widget-tested or reused from another file, and
/// it hides growing UI inside a file that already has an owner. Public widgets
/// in their own file under `presentation/widgets/` stay testable and movable.
///
/// `State` subclasses are untouched: `_FooState` is private by convention and
/// is not a `Widget`.
class AvoidPrivateWidgets extends DartLintRule {
  const AvoidPrivateWidgets() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_private_widgets',
    problemMessage:
        'Widget classes must be public so they can be widget-tested and '
        'reused.',
    correctionMessage:
        'Drop the leading underscore and move the widget to its own file '
        'under presentation/widgets/.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (!isAppSource(resolver.path)) return;

    context.registry.addClassDeclaration((node) {
      if (!node.name.lexeme.startsWith('_')) return;
      if (!isWidgetType(node.extendsClause?.superclass.type)) return;
      reporter.atToken(node.name, code);
    });
  }
}
