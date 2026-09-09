import 'package:flutter/foundation.dart';

import '../../../../core/l10n/gen/app_localizations.dart';

/// Who actually transcribes the audio when this phone cannot do it itself.
///
/// Naming the third party is not a nicety — it is what makes the consent
/// informed, and both stores require it. `kJG43` is drawn as the Android
/// variant and its own note says the iOS copy differs in this single word, so
/// the sheet is one design resolved per platform rather than two sheets that
/// would drift apart.
abstract final class CloudTranscriptionVendor {
  /// The vendor's name for [platform], already localized (it is a proper
  /// noun, but it travels through `AppLocalizations` so the strings stay in
  /// one place and translators see the sentence it lands in).
  static String nameFor(AppLocalizations l10n, TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => l10n.captureVoiceVendorApple,
        // Android is the case the design was drawn for, and it is also the
        // honest default for the desktop/web targets the app does not ship
        // to: naming Google is the wider claim of the two.
        _ => l10n.captureVoiceVendorGoogle,
      };
}
