package com.beyondmenu.iterable_sdk

import android.app.Activity
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.iterable.iterableapi.IterableAction
import com.iterable.iterableapi.IterableActionContext
import com.iterable.iterableapi.IterableApi
import com.iterable.iterableapi.IterableAuthHandler
import com.iterable.iterableapi.IterableConfig
import com.iterable.iterableapi.IterableCustomActionHandler
import com.iterable.iterableapi.IterableDataRegion
import com.iterable.iterableapi.IterableHelper
import com.iterable.iterableapi.IterableInAppCloseAction
import com.iterable.iterableapi.IterableInAppDeleteActionType
import com.iterable.iterableapi.IterableInAppHandler
import com.iterable.iterableapi.IterableInAppLocation
import com.iterable.iterableapi.IterableInAppMessage
import com.iterable.iterableapi.IterableUrlHandler
import com.iterable.iterableapi.RetryPolicy
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/** Flutter plugin bridging the Iterable Android SDK. */
class IterableSdkPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var autoDisplayPaused = false

    companion object {
        private const val TAG = "IterableFlutter"
        private const val CHANNEL = "iterable_sdk/method"
        private const val AUTH_TIMEOUT_SECONDS = 30L
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "initialize" -> initialize(call, result)
                "setEmail" -> {
                    IterableApi.getInstance().setEmail(
                        call.argument("email"),
                        call.argument<String?>("authToken")
                    )
                    result.success(null)
                }
                "setUserId" -> {
                    IterableApi.getInstance().setUserId(
                        call.argument("userId"),
                        call.argument<String?>("authToken")
                    )
                    result.success(null)
                }
                "getEmail" -> result.success(IterableApi.getInstance().email)
                "getUserId" -> result.success(IterableApi.getInstance().userId)
                "updateEmail" -> {
                    val token = call.argument<String?>("authToken")
                    val newEmail = call.argument<String>("newEmail")!!
                    if (token != null) {
                        IterableApi.getInstance().updateEmail(newEmail, token)
                    } else {
                        IterableApi.getInstance().updateEmail(newEmail)
                    }
                    result.success(null)
                }
                "updateUser" -> {
                    val data = IterableSerialization.mapToJson(
                        call.argument("dataFields")
                    ) ?: JSONObject()
                    IterableApi.getInstance().updateUser(
                        data,
                        call.argument<Boolean>("mergeNestedObjects") ?: false
                    )
                    result.success(null)
                }
                "updateSubscriptions" -> updateSubscriptions(call, result)
                "logout" -> {
                    IterableApi.getInstance().setEmail(null)
                    IterableApi.getInstance().setUserId(null)
                    result.success(null)
                }
                "trackEvent" -> {
                    IterableApi.getInstance().track(
                        call.argument<String>("name")!!,
                        IterableSerialization.mapToJson(call.argument("dataFields"))
                    )
                    result.success(null)
                }
                "trackPurchase" -> {
                    val items = IterableSerialization.commerceItemsFromList(
                        call.argument("items")
                    )
                    IterableApi.getInstance().trackPurchase(
                        call.argument<Number>("total")?.toDouble() ?: 0.0,
                        items,
                        IterableSerialization.mapToJson(call.argument("dataFields"))
                    )
                    result.success(null)
                }
                "updateCart" -> {
                    IterableApi.getInstance().updateCart(
                        IterableSerialization.commerceItemsFromList(call.argument("items"))
                    )
                    result.success(null)
                }
                "trackPushOpen" -> {
                    val messageId = call.argument<String?>("messageId")
                    if (messageId != null) {
                        IterableApi.getInstance().trackPushOpen(
                            call.argument<Number>("campaignId")?.toInt() ?: 0,
                            call.argument<Number>("templateId")?.toInt() ?: 0,
                            messageId,
                            IterableSerialization.mapToJson(call.argument("dataFields"))
                        )
                    }
                    result.success(null)
                }
                "getAttributionInfo" ->
                    result.success(
                        IterableSerialization.attributionInfoToMap(
                            IterableApi.getInstance().attributionInfo
                        )
                    )
                "setAttributionInfo" -> {
                    // setAttributionInfo is not part of the public Android API.
                    Log.w(TAG, "setAttributionInfo is not supported on Android")
                    result.success(null)
                }
                "registerForPush" -> {
                    IterableApi.getInstance().registerForPush()
                    result.success(null)
                }
                "registerDeviceToken" -> {
                    val token = call.argument<String>("token")
                    if (token.isNullOrEmpty()) {
                        result.error("iterable_error", "Device token is null or empty", null)
                    } else {
                        IterableApi.getInstance().registerDeviceToken(token)
                        result.success(null)
                    }
                }
                "disablePush" -> {
                    IterableApi.getInstance().disablePush()
                    result.success(null)
                }
                "getLastPushPayload" -> result.success(bundleToMap(IterableApi.getInstance().payloadData))
                "setAutoDisplayPaused" -> {
                    autoDisplayPaused = call.argument<Boolean>("paused") ?: false
                    result.success(null)
                }
                // In-app
                "inApp.getMessages" ->
                    result.success(
                        IterableSerialization.inAppMessagesToList(
                            IterableApi.getInstance().inAppManager.messages
                        )
                    )
                "inApp.getInboxMessages" ->
                    result.success(
                        IterableSerialization.inAppMessagesToList(
                            IterableApi.getInstance().inAppManager.inboxMessages
                        )
                    )
                "inApp.getUnreadInboxMessagesCount" ->
                    result.success(IterableApi.getInstance().inAppManager.unreadInboxMessagesCount)
                "inApp.showMessage" -> showInAppMessage(call, result)
                "inApp.removeMessage" -> {
                    findInApp(call)?.let {
                        IterableApi.getInstance().inAppManager.removeMessage(
                            it,
                            deleteSource(call.argument<Number>("source")?.toInt()),
                            inAppLocation(call.argument<Number>("location")?.toInt())
                        )
                    }
                    result.success(null)
                }
                "inApp.setReadForMessage" -> {
                    findInApp(call)?.let {
                        IterableApi.getInstance().inAppManager.setRead(
                            it,
                            call.argument<Boolean>("read") ?: false
                        )
                    }
                    result.success(null)
                }
                "inApp.trackInAppOpen" -> {
                    findInApp(call)?.let {
                        IterableApi.getInstance().trackInAppOpen(
                            it,
                            inAppLocation(call.argument<Number>("location")?.toInt())
                        )
                    }
                    result.success(null)
                }
                "inApp.trackInAppClick" -> {
                    findInApp(call)?.let {
                        IterableApi.getInstance().trackInAppClick(
                            it,
                            call.argument<String>("clickedUrl") ?: "",
                            inAppLocation(call.argument<Number>("location")?.toInt())
                        )
                    }
                    result.success(null)
                }
                "inApp.trackInAppClose" -> {
                    findInApp(call)?.let {
                        IterableApi.getInstance().trackInAppClose(
                            it,
                            call.argument<String?>("clickedUrl"),
                            closeAction(call.argument<Number>("source")?.toInt()),
                            inAppLocation(call.argument<Number>("location")?.toInt())
                        )
                    }
                    result.success(null)
                }
                "inApp.inAppConsume" -> {
                    findInApp(call)?.let {
                        IterableApi.getInstance().inAppManager.removeMessage(
                            it,
                            deleteSource(call.argument<Number>("source")?.toInt()),
                            inAppLocation(call.argument<Number>("location")?.toInt())
                        )
                    }
                    result.success(null)
                }
                // Embedded
                "embedded.syncMessages" -> {
                    IterableApi.getInstance().embeddedManager.syncMessages()
                    result.success(null)
                }
                "embedded.getMessages" -> {
                    val placementId = call.argument<Number>("placementId")?.toLong() ?: 0L
                    val messages = IterableApi.getInstance().embeddedManager
                        .getMessages(placementId) ?: emptyList()
                    result.success(messages.map { embeddedToMap(it) })
                }
                "embedded.trackClick" -> {
                    findEmbedded(call)?.let {
                        IterableApi.getInstance().trackEmbeddedClick(
                            it,
                            call.argument<String?>("buttonIdentifier"),
                            call.argument<String?>("clickedUrl")
                        )
                    }
                    result.success(null)
                }
                "embedded.trackReceived", "embedded.trackImpression",
                "embedded.trackSession" -> {
                    // Impression/session tracking is handled automatically by the
                    // native EmbeddedSessionManager; received has no public API.
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling ${call.method}", e)
            result.error("iterable_error", e.message, null)
        }
    }

    private fun initialize(call: MethodCall, result: Result) {
        val apiKey = call.argument<String>("apiKey")!!
        val configMap = call.argument<Map<String, Any?>>("config") ?: emptyMap()
        val config = buildConfig(configMap)
        IterableApi.initialize(applicationContext, apiKey, config)

        if (configMap["enableEmbeddedMessaging"] as? Boolean == true) {
            IterableApi.getInstance().embeddedManager.addUpdateListener(
                object : com.iterable.iterableapi.IterableEmbeddedUpdateHandler {
                    override fun onMessagesUpdated() {
                        emitEmbeddedUpdate()
                    }

                    override fun onEmbeddedMessagingDisabled() {}
                }
            )
        }
        result.success(true)
    }

    private fun buildConfig(map: Map<String, Any?>): IterableConfig {
        val builder = IterableConfig.Builder()
        (map["pushIntegrationName"] as? String)?.let { builder.setPushIntegrationName(it) }
        builder.setAutoPushRegistration(map["autoPushRegistration"] as? Boolean ?: true)
        (map["inAppDisplayInterval"] as? Number)?.let {
            builder.setInAppDisplayInterval(it.toDouble())
        }
        builder.setLogLevel(toAndroidLogLevel((map["logLevel"] as? Number)?.toInt()))
        (map["allowedProtocols"] as? List<*>)?.let { list ->
            builder.setAllowedProtocols(list.map { it.toString() }.toTypedArray())
        }
        builder.setUseInMemoryStorageForInApps(
            map["useInMemoryStorageForInApps"] as? Boolean ?: false
        )
        (map["expiringAuthTokenRefreshPeriod"] as? Number)?.let {
            builder.setExpiringAuthTokenRefreshPeriod(it.toLong())
        }
        builder.setDataRegion(
            if ((map["dataRegion"] as? String) == "EU") {
                IterableDataRegion.EU
            } else {
                IterableDataRegion.US
            }
        )
        if (map["enableEmbeddedMessaging"] as? Boolean == true) {
            builder.setEnableEmbeddedMessaging(true)
        }

        val maxRetry = (map["authRetryMaxRetries"] as? Number)?.toInt() ?: 1
        val retryInterval = (map["authRetryIntervalSeconds"] as? Number)?.toLong() ?: 3L
        builder.setAuthRetryPolicy(
            RetryPolicy(maxRetry, retryInterval, RetryPolicy.Type.LINEAR)
        )

        if (map["hasUrlHandler"] as? Boolean == true) {
            builder.setUrlHandler(urlHandler)
        }
        if (map["hasCustomActionHandler"] as? Boolean == true) {
            builder.setCustomActionHandler(customActionHandler)
        }
        if (map["hasInAppHandler"] as? Boolean == true || true) {
            builder.setInAppHandler(inAppHandler)
        }
        if (map["hasAuthHandler"] as? Boolean == true) {
            builder.setAuthHandler(authHandler)
        }
        return builder.build()
    }

    private fun updateSubscriptions(call: MethodCall, result: Result) {
        fun intArray(key: String): Array<Int>? =
            (call.argument<List<*>>(key))?.map { (it as Number).toInt() }?.toTypedArray()

        IterableApi.getInstance().updateSubscriptions(
            intArray("emailListIds"),
            intArray("unsubscribedChannelIds"),
            intArray("unsubscribedMessageTypeIds"),
            intArray("subscribedMessageTypeIds"),
            call.argument<Number>("campaignId")?.toInt(),
            call.argument<Number>("templateId")?.toInt()
        )
        result.success(null)
    }

    private fun showInAppMessage(call: MethodCall, result: Result) {
        val message = findInApp(call)
        if (message == null) {
            result.success(null)
            return
        }
        IterableApi.getInstance().inAppManager.showMessage(
            message,
            call.argument<Boolean>("consume") ?: true,
            IterableHelper.IterableUrlCallback { url ->
                result.success(url?.toString())
            }
        )
    }

    // ----- Handlers (native -> Flutter) -----

    private val urlHandler = IterableUrlHandler { uri, context ->
        invokeOnMain(
            "urlHandler",
            mapOf(
                "url" to uri.toString(),
                "context" to actionContextToMap(context)
            )
        )
        // App registered a handler; let it manage navigation.
        true
    }

    private val customActionHandler = IterableCustomActionHandler { action, context ->
        invokeOnMain(
            "customActionHandler",
            mapOf(
                "action" to actionToMap(action),
                "context" to actionContextToMap(context)
            )
        )
        true
    }

    private val inAppHandler = IterableInAppHandler { message ->
        invokeOnMain(
            "inAppHandler",
            mapOf("message" to IterableSerialization.inAppMessageToMap(message))
        )
        if (autoDisplayPaused) {
            IterableInAppHandler.InAppResponse.SKIP
        } else {
            IterableInAppHandler.InAppResponse.SHOW
        }
    }

    private val authHandler = object : IterableAuthHandler {
        override fun onAuthTokenRequested(): String? {
            // Called on a background thread, so blocking is safe here.
            val latch = CountDownLatch(1)
            val tokenRef = AtomicReference<String?>(null)
            mainHandler.post {
                channel.invokeMethod(
                    "authHandler",
                    mapOf(
                        "email" to IterableApi.getInstance().email,
                        "userId" to IterableApi.getInstance().userId
                    ),
                    object : Result {
                        override fun success(value: Any?) {
                            tokenRef.set(value as? String)
                            latch.countDown()
                        }

                        override fun error(code: String, message: String?, details: Any?) {
                            latch.countDown()
                        }

                        override fun notImplemented() {
                            latch.countDown()
                        }
                    }
                )
            }
            return try {
                latch.await(AUTH_TIMEOUT_SECONDS, TimeUnit.SECONDS)
                tokenRef.get()
            } catch (e: InterruptedException) {
                null
            }
        }

        override fun onTokenRegistrationSuccessful(authToken: String?) {}

        override fun onAuthFailure(authFailure: com.iterable.iterableapi.AuthFailure) {
            invokeOnMain(
                "authFailure",
                mapOf("reason" to authFailure.failureReason?.toString())
            )
        }
    }

    // ----- Helpers -----

    private fun emitEmbeddedUpdate() {
        try {
            val manager = IterableApi.getInstance().embeddedManager
            val all = ArrayList<Map<String, Any?>>()
            for (placementId in manager.getPlacementIds()) {
                manager.getMessages(placementId)?.forEach { all.add(embeddedToMap(it)) }
            }
            invokeOnMain("handleEmbeddedMessagesUpdated", mapOf("messages" to all))
        } catch (e: Exception) {
            Log.e(TAG, "emitEmbeddedUpdate failed", e)
        }
    }

    private fun embeddedToMap(message: com.iterable.iterableapi.IterableEmbeddedMessage): Map<String, Any?> {
        val json = com.iterable.iterableapi.IterableEmbeddedMessage.toJSONObject(message)
        return IterableSerialization.jsonToMap(json) ?: emptyMap()
    }

    private fun findInApp(call: MethodCall): IterableInAppMessage? {
        val id = call.argument<String>("messageId") ?: return null
        return IterableApi.getInstance().inAppManager.messages
            .firstOrNull { it.messageId == id }
    }

    private fun findEmbedded(call: MethodCall): com.iterable.iterableapi.IterableEmbeddedMessage? {
        val id = call.argument<String>("messageId") ?: return null
        val manager = IterableApi.getInstance().embeddedManager
        for (placementId in manager.getPlacementIds()) {
            manager.getMessages(placementId)?.firstOrNull { it.metadata.messageId == id }
                ?.let { return it }
        }
        return null
    }

    private fun invokeOnMain(method: String, args: Map<String, Any?>) {
        mainHandler.post { channel.invokeMethod(method, args) }
    }

    private fun actionToMap(action: IterableAction?): Map<String, Any?> {
        return mapOf(
            "type" to action?.type,
            "data" to action?.data,
            "userInput" to action?.userInput
        )
    }

    private fun actionContextToMap(context: IterableActionContext?): Map<String, Any?> {
        return mapOf(
            "action" to actionToMap(context?.action),
            "source" to when (context?.source) {
                com.iterable.iterableapi.IterableActionSource.APP_LINK -> 1
                com.iterable.iterableapi.IterableActionSource.IN_APP -> 2
                else -> 0
            }
        )
    }

    private fun bundleToMap(bundle: Bundle?): Map<String, Any?>? {
        if (bundle == null) return null
        val map = HashMap<String, Any?>()
        for (key in bundle.keySet()) {
            @Suppress("DEPRECATION")
            map[key] = bundle.get(key)?.toString()
        }
        return map
    }

    private fun toAndroidLogLevel(value: Int?): Int {
        return when (value) {
            1 -> Log.DEBUG
            3 -> Log.ERROR
            else -> Log.INFO
        }
    }

    private fun inAppLocation(value: Int?): IterableInAppLocation {
        return if (value == 1) IterableInAppLocation.INBOX else IterableInAppLocation.IN_APP
    }

    private fun deleteSource(value: Int?): IterableInAppDeleteActionType {
        return when (value) {
            0 -> IterableInAppDeleteActionType.INBOX_SWIPE
            1 -> IterableInAppDeleteActionType.DELETE_BUTTON
            else -> IterableInAppDeleteActionType.OTHER
        }
    }

    private fun closeAction(value: Int?): IterableInAppCloseAction {
        return when (value) {
            0 -> IterableInAppCloseAction.BACK
            else -> IterableInAppCloseAction.LINK
        }
    }
}
