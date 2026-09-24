package com.billetudo.app.capture

import android.app.Notification
import android.content.ComponentName
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Reads the notifications of the bank apps the user explicitly enabled, turns
 * them into capture candidates and parks them for Flutter.
 *
 * ## Read this before changing anything here
 *
 * Android hands this service EVERY notification of the device — chats, mail,
 * SMS with one-time codes, health apps. There is no way to subscribe to a
 * subset; filtering is entirely the app's responsibility (HU-08). The class is
 * therefore written around two rules that are not negotiable:
 *
 * 1. **`packageName` is checked FIRST.** [onNotificationPosted] does not touch
 *    `notification.extras` until [IssuerFilter] has returned an enabled,
 *    catalogued issuer. A notification from any other app is dropped without
 *    being read, logged or counted.
 * 2. **The text is never persisted.** It lives in local variables during
 *    parsing and dies with the method. What survives is what a rule
 *    identified: amount, merchant, last 4, type, timestamp, rule id.
 *
 * There are, deliberately, **no log statements at all** in this file or in any
 * other class of this package — no `Log.d`, not even behind a debug flag. Do
 * not add one "just for debugging": a logcat line or a crash report carrying
 * the text of a notification makes the app's central privacy promise false on
 * day one. `sourceRuleId` on the capture exists precisely so a broken parser
 * can be diagnosed without keeping the message.
 *
 * The service is also entirely additive: removing it, its manifest entry and
 * its permission must leave the rest of the app working (a requirement of the
 * Google Play policy risk, not a nicety).
 */
class BilletudoNotificationListenerService : NotificationListenerService() {

    private val settings: CaptureSettings by lazy { CaptureSettings(this) }
    private val ruleSet: IssuerRuleSet by lazy { IssuerRulesLoader.load(this) }
    private val filter: IssuerFilter by lazy { IssuerFilter(ruleSet, settings) }
    private val engine: NotificationRuleEngine by lazy { NotificationRuleEngine(ruleSet) }
    private val buffer: PendingCaptureBuffer by lazy { PendingCaptureBuffer(settings) }

    override fun onListenerConnected() {
        super.onListenerConnected()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        requestRebind(
            ComponentName(this, BilletudoNotificationListenerService::class.java),
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val statusBarNotification = sbn ?: return

        // ---- STEP 1: issuer filter. Nothing above this line reads content.
        val issuer = filter.resolveEnabledIssuer(statusBarNotification.packageName) ?: return

        // ---- STEP 2: only now may the extras be opened.
        val notification = statusBarNotification.notification ?: return
        val extras = notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        // EXTRA_BIG_TEXT holds the full body; EXTRA_TEXT is what the collapsed
        // row shows and the system truncates it with an ellipsis. Rules are
        // written against the full text, so the big one wins when present.
        val text = (
            extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_TEXT)
            )?.toString().orEmpty()

        if (title.isEmpty() && text.isEmpty()) return

        // ---- STEP 3: parse and forget.
        val capture = engine.parse(
            issuer = issuer,
            packageName = statusBarNotification.packageName,
            title = title,
            text = text,
            postedAtEpochMs = statusBarNotification.postTime,
        ) ?: return

        buffer.add(capture)
    }

    /**
     * Nothing to do: a dismissed notification says nothing about the movement
     * it announced, and a capture already parked stays parked.
     */
    override fun onNotificationRemoved(sbn: StatusBarNotification?) = Unit

}
