import 'package:analyzer/dart/element/type.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Matches `Widget` and every subtype of it.
const widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');

/// Whether [type] is a `Widget` or any subtype of it.
bool isWidgetType(DartType? type) =>
    type != null && widgetChecker.isAssignableFromType(type);

/// Whether [path] belongs to the app's production sources. Rules that only
/// make sense for shipped UI code skip tests, tooling and generated output.
bool isAppSource(String path) =>
    path.contains('/lib/') &&
    !path.endsWith('.g.dart') &&
    !path.endsWith('.freezed.dart') &&
    !path.contains('/l10n/gen/');
