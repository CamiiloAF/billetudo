import 'package:url_launcher/url_launcher.dart';

/// Opens [url] outside the app. Returns `false` when no handler could take it,
/// so the caller can tell the user instead of failing silently.
typedef ExternalUrlOpener = Future<bool> Function(Uri url);

/// The real opener, backed by `url_launcher`. Injected as a parameter by the
/// widgets that use it so widget tests can pass a fake and never touch the
/// platform channel.
Future<bool> openExternalUrl(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);
