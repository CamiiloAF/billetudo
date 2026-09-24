package com.billetudo.app.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ReminderChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    private val alarmManager = context.getSystemService(AlarmManager::class.java)

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, BilletudoScheduledReminderReceiver.CHANNEL)
            .setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "schedule" -> {
                schedule(call)
                result.success(null)
            }
            "cancel" -> {
                cancel(call.argument<Int>("id") ?: 0)
                result.success(null)
            }
            "pendingIds" -> result.success(pendingIds())
            else -> result.notImplemented()
        }
    }

    private fun schedule(call: MethodCall) {
        val id = call.argument<Int>("id") ?: return
        val fireAt = call.argument<Long>("fireAt") ?: return
        val intent = Intent(context, BilletudoScheduledReminderReceiver::class.java).apply {
            putExtra(BilletudoScheduledReminderReceiver.EXTRA_ID, id)
            putExtra(BilletudoScheduledReminderReceiver.EXTRA_CHANNEL_ID, call.argument<String>("channelId"))
            putExtra(BilletudoScheduledReminderReceiver.EXTRA_CHANNEL_NAME, call.argument<String>("channelName"))
            putExtra(BilletudoScheduledReminderReceiver.EXTRA_CHANNEL_DESCRIPTION, call.argument<String>("channelDescription"))
            putExtra(BilletudoScheduledReminderReceiver.EXTRA_TITLE, call.argument<String>("title"))
            putExtra(BilletudoScheduledReminderReceiver.EXTRA_BODY, call.argument<String>("body"))
            putExtra(BilletudoScheduledReminderReceiver.EXTRA_PAYLOAD, call.argument<String>("payload"))
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, fireAt, pendingIntent)
        val ids = pendingIds().toMutableSet()
        ids.add(id)
        savePendingIds(ids)
    }

    private fun cancel(id: Int) {
        if (id == 0) return
        val intent = Intent(context, BilletudoScheduledReminderReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
        val ids = pendingIds().toMutableSet()
        ids.remove(id)
        savePendingIds(ids)
    }

    private fun pendingIds(): List<Int> = context
        .getSharedPreferences(BilletudoScheduledReminderReceiver.PREFERENCES, Context.MODE_PRIVATE)
        .getStringSet(BilletudoScheduledReminderReceiver.KEY_IDS, emptySet())
        .orEmpty()
        .mapNotNull(String::toIntOrNull)

    private fun savePendingIds(ids: Set<Int>) {
        context.getSharedPreferences(BilletudoScheduledReminderReceiver.PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(
                BilletudoScheduledReminderReceiver.KEY_IDS,
                ids.map(Int::toString).toSet(),
            )
            .apply()
    }
}
