package com.beyondmenu.iterable_sdk

import android.content.Context
import android.content.Intent
import android.util.Log
import com.iterable.iterableapi.IterableApi

/**
 * Bridges package-private Iterable push utilities so push taps execute their
 * openUrl / customAction handlers after the Flutter activity is ready.
 */
internal object IterablePushBridge {
    private const val TAG = "IterablePushBridge"

    fun processPendingPushAction(context: Context): Boolean {
        return try {
            val clazz = Class.forName("com.iterable.iterableapi.IterablePushNotificationUtil")
            val method = clazz.getDeclaredMethod(
                "processPendingAction",
                Context::class.java
            )
            method.isAccessible = true
            method.invoke(null, context) as? Boolean ?: false
        } catch (e: Exception) {
            Log.w(TAG, "processPendingPushAction failed", e)
            false
        }
    }

    fun handlePushAction(context: Context, intent: Intent) {
        try {
            val clazz = Class.forName("com.iterable.iterableapi.IterablePushNotificationUtil")
            val method = clazz.getDeclaredMethod(
                "handlePushAction",
                Context::class.java,
                Intent::class.java
            )
            method.isAccessible = true
            method.invoke(null, context, intent)
        } catch (e: Exception) {
            Log.w(TAG, "handlePushAction failed", e)
        }
    }

    /**
     * Processes a push notification tap delivered to the host activity.
     * Safe to call from [onCreate]/[onNewIntent] intent handling and after SDK init.
     */
    fun handleIntent(context: Context, intent: Intent?) {
        if (intent == null) return
        if (!IterableApi.getInstance().isIterableIntent(intent)) return

        // Pending action may have been queued before the activity existed.
        if (processPendingPushAction(context)) return

        // Cold start via launcher intent: extras present but no pending action yet.
        handlePushAction(context, intent)
        processPendingPushAction(context)
    }
}
