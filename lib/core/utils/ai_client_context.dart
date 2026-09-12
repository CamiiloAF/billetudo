import 'dart:ui' as ui;

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The three pieces of device context every `AiTurnRequest` needs on the
/// wire: BCP-47 locale (drives the language the model answers in), IANA
/// timezone (the only way it can resolve "este mes"), and `version+build`
/// (what makes an "actualiza la app" answer on a protocol bump possible).
class AiClientContext {
  const AiClientContext({
    required this.locale,
    required this.timezone,
    required this.clientVersion,
  });

  final String locale;
  final String timezone;
  final String clientVersion;
}

/// Resolves [AiClientContext] once and caches it: none of the three values
/// changes while the app is running, and two of them cross a platform
/// channel.
@lazySingleton
class AiClientContextProvider {
  AiClientContext? _cached;

  Future<AiClientContext> resolve() async {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }
    final context = AiClientContext(
      locale: ui.PlatformDispatcher.instance.locale.toLanguageTag(),
      timezone: await _timezone(),
      clientVersion: await _clientVersion(),
    );
    _cached = context;
    return context;
  }

  /// Falls back to UTC on a platform/channel the plugin cannot read — the
  /// turn still goes out; the model just resolves relative dates against
  /// UTC instead of the user's own zone.
  Future<String> _timezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return info.identifier;
    } on Object {
      return 'UTC';
    }
  }

  Future<String> _clientVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } on Object {
      return 'unknown';
    }
  }
}
