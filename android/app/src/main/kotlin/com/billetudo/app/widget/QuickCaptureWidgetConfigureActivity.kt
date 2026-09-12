package com.billetudo.app.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.CheckBox
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import com.billetudo.app.R

/**
 * Configuration activity for the quick-capture widget (HU-03,
 * `docs/requirements/fase-2/20-widget-captura-rapida.md`). The system opens
 * it the moment the widget is added (`android:configure` in
 * `quick_capture_widget_info.xml`); the user can reopen it later from the
 * launcher's own "edit widget" affordance — same activity either way.
 *
 * Deliberately simple: a fixed 4-row list (one per [QuickCaptureShortcut]),
 * each with a checkbox — shown or not — and up/down buttons for its place in
 * the row. No drag-and-drop, no `RecyclerView`: a widget with at most four
 * slots does not justify that machinery.
 */
class QuickCaptureWidgetConfigureActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    /** Current row order; reordering swaps entries here, then re-renders. */
    private val order = ALL_SHORTCUTS.toMutableList()
    private val enabled = mutableMapOf<QuickCaptureShortcut, Boolean>()
    private lateinit var rows: List<Row>

    private data class Row(
        val checkbox: CheckBox,
        val label: TextView,
        val up: ImageButton,
        val down: ImageButton,
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // A cancel result until the user explicitly saves: closing without
        // saving (back button, home) must not add a half-configured widget.
        setResult(Activity.RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.activity_widget_configure)

        val current = WidgetConfigStore.getShortcuts(this, appWidgetId)
        order.clear()
        order.addAll(current)
        ALL_SHORTCUTS.forEach { shortcut -> if (shortcut !in order) order.add(shortcut) }
        ALL_SHORTCUTS.forEach { shortcut -> enabled[shortcut] = current.contains(shortcut) }

        rows = listOf(
            Row(
                findViewById(R.id.configure_checkbox_0),
                findViewById(R.id.configure_label_0),
                findViewById(R.id.configure_up_0),
                findViewById(R.id.configure_down_0),
            ),
            Row(
                findViewById(R.id.configure_checkbox_1),
                findViewById(R.id.configure_label_1),
                findViewById(R.id.configure_up_1),
                findViewById(R.id.configure_down_1),
            ),
            Row(
                findViewById(R.id.configure_checkbox_2),
                findViewById(R.id.configure_label_2),
                findViewById(R.id.configure_up_2),
                findViewById(R.id.configure_down_2),
            ),
            Row(
                findViewById(R.id.configure_checkbox_3),
                findViewById(R.id.configure_label_3),
                findViewById(R.id.configure_up_3),
                findViewById(R.id.configure_down_3),
            ),
        )

        rows.forEachIndexed { index, row ->
            row.up.setOnClickListener { move(index, -1) }
            row.down.setOnClickListener { move(index, 1) }
        }

        findViewById<Button>(R.id.configure_save).setOnClickListener { save() }

        renderRows()
    }

    private fun move(index: Int, delta: Int) {
        val target = index + delta
        if (target !in order.indices) {
            return
        }
        val moved = order.removeAt(index)
        order.add(target, moved)
        renderRows()
    }

    private fun renderRows() {
        rows.forEachIndexed { index, row ->
            val shortcut = order[index]
            row.checkbox.setOnCheckedChangeListener(null)
            row.checkbox.isChecked = enabled[shortcut] == true
            row.checkbox.setOnCheckedChangeListener { _, isChecked -> enabled[shortcut] = isChecked }
            row.label.text = getString(shortcut.labelRes)
            row.up.isEnabled = index > 0
            row.up.visibility = if (index > 0) View.VISIBLE else View.INVISIBLE
            row.down.isEnabled = index < rows.size - 1
            row.down.visibility = if (index < rows.size - 1) View.VISIBLE else View.INVISIBLE
        }
    }

    private fun save() {
        val selected = order.filter { enabled[it] == true }
        if (selected.isEmpty()) {
            Toast.makeText(this, getString(R.string.widget_configure_error_empty), Toast.LENGTH_SHORT).show()
            return
        }

        WidgetConfigStore.saveShortcuts(this, appWidgetId, selected)
        QuickCaptureWidgetProvider.refresh(this, AppWidgetManager.getInstance(this), appWidgetId)

        val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(Activity.RESULT_OK, resultValue)
        finish()
    }

    private companion object {
        /**
         * Canonical order offered by this screen. Bank inbox is included —
         * Android is the only platform where it exists — even though it is
         * not part of [QuickCaptureShortcut.DEFAULT].
         */
        val ALL_SHORTCUTS = QuickCaptureShortcut.ALL
    }
}
