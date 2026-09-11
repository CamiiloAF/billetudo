package com.billetudo.app.widget

import com.billetudo.app.R

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

    /**
     * Slot content the widget provider and the configuration activity both
     * need: which icon, which label, which accessibility description. Kept
     * here (rather than duplicated in the provider) so the two never drift.
     */
    val iconRes: Int
        get() = when (this) {
            EXPENSE -> R.drawable.ic_widget_expense
            INCOME -> R.drawable.ic_widget_income
            VOICE -> R.drawable.ic_widget_voice
            BANK_INBOX -> R.drawable.ic_widget_inbox
        }

    val labelRes: Int
        get() = when (this) {
            EXPENSE -> R.string.widget_shortcut_expense
            INCOME -> R.string.widget_shortcut_income
            VOICE -> R.string.widget_shortcut_voice
            BANK_INBOX -> R.string.widget_shortcut_inbox
        }

    val accessibilityLabelRes: Int
        get() = when (this) {
            EXPENSE -> R.string.widget_shortcut_expense_a11y
            INCOME -> R.string.widget_shortcut_income_a11y
            VOICE -> R.string.widget_shortcut_voice_a11y
            BANK_INBOX -> R.string.widget_shortcut_inbox_a11y
        }

    companion object {
        /** Every shortcut, in the canonical order offered by the configuration
         * activity (HU-03) — not necessarily the order shown on any given
         * widget instance, which the user can reorder. */
        val ALL: List<QuickCaptureShortcut> = listOf(EXPENSE, INCOME, VOICE, BANK_INBOX)

        /**
         * Default subset and order for a widget nobody has configured yet
         * (HU-03, decisión: sin conjunto por defecto el widget no sirve el
         * primer día). Gasto e ingreso son el par más simple y universal —
         * ninguno pide un permiso adicional ni depende de que voz/OCR estén
         * disponibles en el dispositivo.
         */
        val DEFAULT: List<QuickCaptureShortcut> = listOf(EXPENSE, INCOME)

        fun fromId(id: String?): QuickCaptureShortcut? =
            values().firstOrNull { it.id == id }
    }
}
