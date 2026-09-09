package com.billetudo.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import com.billetudo.app.MainActivity
import com.billetudo.app.R

/**
 * Home-screen widget: a row of shortcuts into the capture screens
 * (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
 *
 * Built with [RemoteViews], not Glance. Glance would drag Jetpack Compose and
 * its compiler plugin into a Gradle build that today has no Compose at all,
 * for a UI that is four buttons in a row; RemoteViews needs no dependency and
 * no Kotlin/Compose version pinning to keep matching. If the widget ever
 * grows real interactive content, that trade-off is worth revisiting.
 *
 * It never reads nor writes app data, never touches the network and declares
 * no periodic refresh (`updatePeriodMillis="0"`): with nothing to display,
 * there is nothing that could go stale (HU-05).
 */
class QuickCaptureWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id -> updateWidget(context, appWidgetManager, id) }
    }

    /** Re-lays out after a resize: which shortcuts fit depends on the width. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val views = RemoteViews(context.packageName, R.layout.widget_quick_capture)

        // Android resizes widgets on a continuous range, so the layout drops
        // shortcuts as the width shrinks instead of squeezing four of them
        // below a comfortable touch target (HU-06).
        val visibleCount = when {
            minWidthDp >= WIDTH_FOR_FOUR_DP -> 4
            minWidthDp >= WIDTH_FOR_THREE_DP -> 3
            minWidthDp >= WIDTH_FOR_TWO_DP -> 2
            else -> 1
        }

        SHORTCUT_VIEWS.forEachIndexed { index, (viewId, shortcut) ->
            val visible = index < visibleCount
            views.setViewVisibility(
                viewId,
                if (visible) android.view.View.VISIBLE else android.view.View.GONE,
            )
            if (visible) {
                views.setOnClickPendingIntent(viewId, pendingIntentFor(context, shortcut))
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /**
     * Opens the app on [shortcut]'s capture screen. An explicit intent (never
     * an `ACTION_VIEW` deep link) so the tap cannot be picked up by another
     * app and so the `.dev` flavor's suffixed application id resolves on its
     * own; the shortcut id travels as an extra, which also keeps Flutter's
     * automatic deep-link handling out of the way.
     *
     * Tapping never writes anything — it only navigates. The transaction the
     * user may end up saving is `source = manual`, exactly as if they had
     * used the in-app FAB.
     */
    private fun pendingIntentFor(context: Context, shortcut: QuickCaptureShortcut): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = QuickCaptureWidgetBridge.ACTION_OPEN_SHORTCUT
            putExtra(QuickCaptureWidgetBridge.EXTRA_SHORTCUT, shortcut.id)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        return PendingIntent.getActivity(
            context,
            shortcut.ordinal,
            intent,
            // IMMUTABLE is required from API 31 and correct here: nothing may
            // rewrite which shortcut was tapped.
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private companion object {
        /** Shortcut order, most used first — the first to survive a resize. */
        val SHORTCUT_VIEWS = listOf(
            R.id.widget_shortcut_expense to QuickCaptureShortcut.EXPENSE,
            R.id.widget_shortcut_income to QuickCaptureShortcut.INCOME,
            R.id.widget_shortcut_voice to QuickCaptureShortcut.VOICE,
            R.id.widget_shortcut_inbox to QuickCaptureShortcut.BANK_INBOX,
        )

        const val WIDTH_FOR_TWO_DP = 130
        const val WIDTH_FOR_THREE_DP = 200
        const val WIDTH_FOR_FOUR_DP = 270
    }
}
