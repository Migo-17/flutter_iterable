package com.beyondmenu.iterable_sdk

import com.iterable.iterableapi.CommerceItem
import com.iterable.iterableapi.IterableAttributionInfo
import com.iterable.iterableapi.IterableInAppMessage
import org.json.JSONArray
import org.json.JSONObject

/** Helpers that translate between Flutter maps and the native Iterable types. */
internal object IterableSerialization {

    fun mapToJson(map: Map<String, Any?>?): JSONObject? {
        if (map == null) return null
        val json = JSONObject()
        for ((key, value) in map) {
            json.put(key, wrap(value))
        }
        return json
    }

    private fun wrap(value: Any?): Any {
        return when (value) {
            null -> JSONObject.NULL
            is Map<*, *> -> {
                val obj = JSONObject()
                for ((k, v) in value) {
                    obj.put(k.toString(), wrap(v))
                }
                obj
            }
            is List<*> -> {
                val arr = JSONArray()
                for (item in value) {
                    arr.put(wrap(item))
                }
                arr
            }
            else -> value
        }
    }

    fun jsonToMap(json: JSONObject?): Map<String, Any?>? {
        if (json == null) return null
        val map = HashMap<String, Any?>()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            map[key] = unwrap(json.get(key))
        }
        return map
    }

    private fun jsonArrayToList(array: JSONArray): List<Any?> {
        val list = ArrayList<Any?>()
        for (i in 0 until array.length()) {
            list.add(unwrap(array.get(i)))
        }
        return list
    }

    private fun unwrap(value: Any?): Any? {
        return when (value) {
            null, JSONObject.NULL -> null
            is JSONObject -> jsonToMap(value)
            is JSONArray -> jsonArrayToList(value)
            else -> value
        }
    }

    fun commerceItemsFromList(items: List<Map<String, Any?>>?): List<CommerceItem> {
        if (items == null) return emptyList()
        return items.map { item ->
            val categories = (item["categories"] as? List<*>)
                ?.map { it.toString() }
                ?.toTypedArray()
            @Suppress("UNCHECKED_CAST")
            CommerceItem(
                item["id"].toString(),
                item["name"].toString(),
                (item["price"] as? Number)?.toDouble() ?: 0.0,
                (item["quantity"] as? Number)?.toInt() ?: 0,
                item["sku"] as? String,
                item["description"] as? String,
                item["url"] as? String,
                item["imageUrl"] as? String,
                categories,
                mapToJson(item["dataFields"] as? Map<String, Any?>)
            )
        }
    }

    fun attributionInfoToMap(info: IterableAttributionInfo?): Map<String, Any?>? {
        if (info == null) return null
        return mapOf(
            "campaignId" to info.campaignId,
            "templateId" to info.templateId,
            "messageId" to info.messageId
        )
    }

    fun inAppMessageToMap(message: IterableInAppMessage): Map<String, Any?> {
        val map = HashMap<String, Any?>()
        map["messageId"] = message.messageId
        map["campaignId"] = message.campaignId
        map["createdAt"] = message.createdAt?.time
        map["expiresAt"] = message.expiresAt?.time
        map["saveToInbox"] = message.isInboxMessage
        map["read"] = message.isRead
        map["priorityLevel"] = message.priorityLevel
        map["customPayload"] = jsonToMap(message.customPayload)
        message.inboxMetadata?.let { meta ->
            map["inboxTitle"] = meta.title
            map["inboxSubtitle"] = meta.subtitle
            map["inboxIconUrl"] = meta.icon
        }
        return map
    }

    fun inAppMessagesToList(messages: List<IterableInAppMessage>): List<Map<String, Any?>> {
        return messages.map { inAppMessageToMap(it) }
    }
}
