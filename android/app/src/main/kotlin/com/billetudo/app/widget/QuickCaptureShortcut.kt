package com.billetudo.app.widget

/**
 * The shortcuts the home-screen widget can offer
 * (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
 *
 * The widget is a pure shortcut: it shows no financial data, so there is
 * nothing here to keep in sync with the app's database and nothing that can
 * go stale. Every [id] must match the one in the Dart enum
 * `lib/features/capture/domain/entities/capture_shortcut.dart` — that string
 * is the whole contract between the two processes.
 */
enum class QuickCaptureShortcut(val id: String) {
    EXPENSE("expense"),
    INCOME("income"),
    VOICE("voice"),

    /**
     * Bank-notification inbox. Android only, and not by omission: iOS cannot
     * read other apps' notifications, so the shortcut does not exist there
     * rather than showing up disabled behind a padlock.
     */
    BANK_INBOX("bank_inbox");

    companion object {
        fun fromId(id: String?): QuickCaptureShortcut? =
            values().firstOrNull { it.id == id }
    }
}
