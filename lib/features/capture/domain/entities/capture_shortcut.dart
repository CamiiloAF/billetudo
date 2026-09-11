/// A shortcut fired from the home-screen widget
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// The widget is a **pure shortcut**: it never reads nor writes business
/// data, it only asks the app to open a capture surface. Every value here
/// maps 1:1 to an id the native side sends over the platform channel, so the
/// [id] strings are part of that contract — renaming one means renaming it in
/// `android/.../widget/QuickCaptureWidgetProvider.kt` and in
/// `ios/QuickCaptureWidget/QuickCaptureShortcut.swift` too.
enum CaptureShortcut {
  /// New movement form with `type = expense` preselected (HU-01).
  expense('expense'),

  /// New movement form with `type = income` preselected (HU-02).
  income('income'),

  /// Voice capture (HU-02). Its screen is built by `feat/capture-voice`.
  voice('voice'),

  /// Bank-notification inbox (HU-02). Android only: reading other apps'
  /// notifications is impossible on iOS, so the shortcut does not exist
  /// there — it is never shown disabled.
  bankInbox('bank_inbox');

  const CaptureShortcut(this.id);

  /// The id exchanged with the native widget over the platform channel.
  final String id;

  /// The shortcut for [id], or `null` when the native side sends something
  /// this build does not know about (older app, newer widget).
  static CaptureShortcut? fromId(String id) {
    for (final shortcut in CaptureShortcut.values) {
      if (shortcut.id == id) {
        return shortcut;
      }
    }
    return null;
  }
}
