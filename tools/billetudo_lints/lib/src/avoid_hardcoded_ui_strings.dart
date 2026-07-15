import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'widget_type.dart';

/// Constructor arguments that take a string but never reach the user's eyes,
/// so they are exempt from localization.
const _technicalParameters = <String>{
  'name', // Image.asset(name), FontFeature(name)
  'src', // Image.network(src)
  'package',
  'fontFamily',
  'restorationId',
  'debugLabel',
  'routeName',
  'initialRoute',
};

/// Flags string literals passed to a widget constructor.
///
/// Billetudo ships in `es` and `en`, so any text the user reads must come from
/// `AppLocalizations` (`lib/core/l10n`). A literal there is a string that can
/// only ever exist in one language.
///
/// The rule deliberately looks only at widget arguments: an exception message
/// or a log line is a technical string in English by convention and is not
/// something the user reads.
class AvoidHardcodedUiStrings extends DartLintRule {
  const AvoidHardcodedUiStrings() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_hardcoded_ui_strings',
    problemMessage:
        'User-facing text must come from AppLocalizations, not a literal.',
    correctionMessage:
        'Add the key to lib/core/l10n/arb/app_es.arb and app_en.arb, then read '
        'it with AppLocalizations.of(context).',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (!isAppSource(resolver.path)) return;

    void check(StringLiteral node) {
      if (!_isUserFacing(node)) return;
      reporter.atNode(node, code);
    }

    context.registry.addSimpleStringLiteral(check);
    context.registry.addStringInterpolation(check);
    context.registry.addAdjacentStrings(check);
  }

  bool _isUserFacing(StringLiteral node) {
    if (node is SimpleStringLiteral && node.value.trim().isEmpty) return false;

    // The literal must be the argument itself, not part of a larger
    // expression we cannot reason about.
    final Expression argument;
    final AstNode? argumentList;
    final parent = node.parent;
    if (parent is NamedExpression) {
      argument = parent;
      argumentList = parent.parent;
    } else {
      argument = node;
      argumentList = parent;
    }
    if (argumentList is! ArgumentList) return false;

    // Only widget constructors: `Text('hi')`, `Tooltip(message: 'hi')`.
    final invocation = argumentList.parent;
    if (invocation is! InstanceCreationExpression) return false;
    if (!isWidgetType(invocation.staticType)) return false;

    final parameterName = argument is NamedExpression
        ? argument.name.label.name
        : node.correspondingParameter?.name;
    return !_technicalParameters.contains(parameterName);
  }
}
