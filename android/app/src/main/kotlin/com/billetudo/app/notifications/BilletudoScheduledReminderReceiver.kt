package com.billetudo.app.notifications

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
class BilletudoScheduledReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val notificationId = intent.getIntExtra(EXTRA_ID, 0)
        val channelId = intent.getStringExtra(EXTRA_CHANNEL_ID) ?: return
        val channelName = intent.getStringExtra(EXTRA_CHANNEL_NAME) ?: return
        val channelDescription = intent.getStringExtra(EXTRA_CHANNEL_DESCRIPTION).orEmpty()
        val title = intent.getStringExtra(EXTRA_TITLE).orEmpty()
        val body = intent.getStringExtra(EXTRA_BODY).orEmpty()
        val payload = intent.getStringExtra(EXTRA_PAYLOAD)
        if (notificationId == 0 || title.isEmpty() || body.isEmpty()) return

        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = channelDescription
            },
        )

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val contentIntent = launchIntent?.let {
            PendingIntent.getActivity(
                context,
                notificationId,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
        if (contentIntent != null) builder.setContentIntent(contentIntent)
        if (payload != null) builder.setShortcutId(payload)

        manager.notify(notificationId, builder.build())
        removePendingId(context, notificationId)
    }

    private fun removePendingId(context: Context, id: Int) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val current = preferences.getStringSet(KEY_IDS, emptySet()).orEmpty().toMutableSet()
        current.remove(id.toString())
        preferences.edit().putStringSet(KEY_IDS, current).apply()
    }

    companion object {
        const val CHANNEL = "com.billetudo.app/reminders"
        const val EXTRA_ID = "id"
        const val EXTRA_CHANNEL_ID = "channelId"
        const val EXTRA_CHANNEL_NAME = "channelName"
        const val EXTRA_CHANNEL_DESCRIPTION = "channelDescription"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_PAYLOAD = "payload"
        const val PREFERENCES = "billetudo_reminders"
        const val KEY_IDS = "pending_ids"
    }
}
