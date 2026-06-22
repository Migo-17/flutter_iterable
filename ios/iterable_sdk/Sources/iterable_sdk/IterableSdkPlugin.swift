import Flutter
import UIKit
import UserNotifications
import IterableSDK

public class IterableSdkPlugin: NSObject, FlutterPlugin {
    private static let channelName = "iterable_sdk/method"
    private static var shared: IterableSdkPlugin?

    private var channel: FlutterMethodChannel
    private var autoDisplayPaused = false

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = IterableSdkPlugin(channel: channel)
        shared = instance
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    // MARK: - Method dispatch

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "initialize":
            initialize(args: args, result: result)

        case "setEmail":
            IterableAPI.setEmail(args["email"] as? String, args["authToken"] as? String)
            result(nil)

        case "setUserId":
            IterableAPI.setUserId(args["userId"] as? String, args["authToken"] as? String)
            result(nil)

        case "getEmail":
            result(IterableAPI.email)

        case "getUserId":
            result(IterableAPI.userId)

        case "updateEmail":
            let newEmail = args["newEmail"] as? String ?? ""
            IterableAPI.updateEmail(newEmail,
                                    withToken: args["authToken"] as? String,
                                    onSuccess: nil,
                                    onFailure: nil)
            result(nil)

        case "updateUser":
            let dataFields = args["dataFields"] as? [AnyHashable: Any] ?? [:]
            IterableAPI.updateUser(dataFields, mergeNestedObjects: args["mergeNestedObjects"] as? Bool ?? false)
            result(nil)

        case "updateSubscriptions":
            updateSubscriptions(args: args)
            result(nil)

        case "logout":
            IterableAPI.logoutUser()
            result(nil)

        case "trackEvent":
            IterableAPI.track(event: args["name"] as? String ?? "",
                              dataFields: args["dataFields"] as? [AnyHashable: Any])
            result(nil)

        case "trackPurchase":
            let total = NSNumber(value: args["total"] as? Double ?? 0)
            IterableAPI.track(purchase: total,
                              items: commerceItems(from: args["items"]),
                              dataFields: args["dataFields"] as? [AnyHashable: Any])
            result(nil)

        case "updateCart":
            IterableAPI.updateCart(items: commerceItems(from: args["items"]))
            result(nil)

        case "trackPushOpen":
            if let messageId = args["messageId"] as? String {
                IterableAPI.track(pushOpen: NSNumber(value: args["campaignId"] as? Int ?? 0),
                                  templateId: NSNumber(value: args["templateId"] as? Int ?? 0),
                                  messageId: messageId,
                                  appAlreadyRunning: args["appAlreadyRunning"] as? Bool ?? false,
                                  dataFields: args["dataFields"] as? [AnyHashable: Any])
            }
            result(nil)

        case "getAttributionInfo":
            result(attributionMap(IterableAPI.attributionInfo))

        case "setAttributionInfo":
            if let info = args["attributionInfo"] as? [String: Any] {
                IterableAPI.attributionInfo = IterableAttributionInfo(
                    campaignId: NSNumber(value: info["campaignId"] as? Int ?? 0),
                    templateId: NSNumber(value: info["templateId"] as? Int ?? 0),
                    messageId: info["messageId"] as? String ?? "")
            } else {
                IterableAPI.attributionInfo = nil
            }
            result(nil)

        case "registerForPush":
            registerForPush()
            result(nil)

        case "registerDeviceToken":
            if let token = args["token"] as? String, let data = Self.dataFromHexToken(token) {
                IterableAPI.register(token: data)
                result(nil)
            } else {
                result(FlutterError(code: "iterable_error",
                                    message: "Device token is null or not a valid APNs hex token",
                                    details: nil))
            }

        case "disablePush":
            IterableAPI.disableDeviceForCurrentUser()
            result(nil)

        case "getLastPushPayload":
            result(IterableAPI.lastPushPayload as? [String: Any])

        case "setAutoDisplayPaused":
            autoDisplayPaused = args["paused"] as? Bool ?? false
            IterableAPI.inAppManager.isAutoDisplayPaused = autoDisplayPaused
            result(nil)

        // In-app
        case "inApp.getMessages":
            result(IterableAPI.inAppManager.getMessages().map { inAppMessageMap($0) })

        case "inApp.getInboxMessages":
            result(IterableAPI.inAppManager.getInboxMessages().map { inAppMessageMap($0) })

        case "inApp.getUnreadInboxMessagesCount":
            result(IterableAPI.inAppManager.getUnreadInboxMessagesCount())

        case "inApp.showMessage":
            if let message = findInApp(args) {
                IterableAPI.inAppManager.show(message: message,
                                              consume: args["consume"] as? Bool ?? true) { url in
                    result(url?.absoluteString)
                }
            } else {
                result(nil)
            }

        case "inApp.removeMessage":
            if let message = findInApp(args) {
                IterableAPI.inAppManager.remove(message: message,
                                                location: inAppLocation(args["location"]),
                                                source: deleteSource(args["source"]))
            }
            result(nil)

        case "inApp.setReadForMessage":
            if let message = findInApp(args) {
                IterableAPI.inAppManager.set(read: args["read"] as? Bool ?? false, forMessage: message)
            }
            result(nil)

        case "inApp.trackInAppOpen":
            if let message = findInApp(args) {
                IterableAPI.track(inAppOpen: message, location: inAppLocation(args["location"]))
            }
            result(nil)

        case "inApp.trackInAppClick":
            if let message = findInApp(args) {
                IterableAPI.track(inAppClick: message,
                                  location: inAppLocation(args["location"]),
                                  clickedUrl: args["clickedUrl"] as? String ?? "")
            }
            result(nil)

        case "inApp.trackInAppClose":
            if let message = findInApp(args) {
                IterableAPI.track(inAppClose: message,
                                  location: inAppLocation(args["location"]),
                                  source: closeSource(args["source"]),
                                  clickedUrl: args["clickedUrl"] as? String)
            }
            result(nil)

        case "inApp.inAppConsume":
            if let message = findInApp(args) {
                IterableAPI.inAppConsume(message: message,
                                         location: inAppLocation(args["location"]),
                                         source: deleteSource(args["source"]))
            }
            result(nil)

        // Embedded
        case "embedded.syncMessages":
            IterableAPI.embeddedManager.syncMessages { }
            result(nil)

        case "embedded.getMessages":
            let placementId = args["placementId"] as? Int ?? 0
            result(IterableAPI.embeddedManager.getMessages(for: placementId).map { embeddedMap($0) })

        case "embedded.trackClick":
            if let message = findEmbedded(args) {
                IterableAPI.embeddedManager.handleEmbeddedClick(
                    message: message,
                    buttonIdentifier: args["buttonIdentifier"] as? String,
                    clickedUrl: args["clickedUrl"] as? String ?? "")
            }
            result(nil)

        case "embedded.trackReceived":
            if let message = findEmbedded(args) {
                IterableAPI.track(embeddedMessageReceived: message)
            }
            result(nil)

        case "embedded.trackImpression", "embedded.trackSession":
            // Impression/session tracking is handled by the native session manager.
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Initialization

    private func initialize(args: [String: Any], result: @escaping FlutterResult) {
        let apiKey = args["apiKey"] as? String ?? ""
        let configMap = args["config"] as? [String: Any] ?? [:]
        let config = buildConfig(configMap)
        let version = args["version"] as? String

        DispatchQueue.main.async {
            IterableAPI.initialize(apiKey: apiKey, launchOptions: nil, config: config)
            if configMap["enableEmbeddedMessaging"] as? Bool == true {
                IterableAPI.embeddedManager.addUpdateListener(self)
            }
            result(true)
        }
    }

    private func buildConfig(_ map: [String: Any]) -> IterableConfig {
        let config = IterableConfig()
        config.pushIntegrationName = map["pushIntegrationName"] as? String
        config.autoPushRegistration = map["autoPushRegistration"] as? Bool ?? true
        config.inAppDisplayInterval = map["inAppDisplayInterval"] as? Double ?? 30.0
        config.expiringAuthTokenRefreshPeriod = map["expiringAuthTokenRefreshPeriod"] as? Double ?? 60.0
        config.allowedProtocols = map["allowedProtocols"] as? [String] ?? []
        config.useInMemoryStorageForInApps = map["useInMemoryStorageForInApps"] as? Bool ?? false
        config.dataRegion = (map["dataRegion"] as? String) == "EU" ? IterableDataRegion.EU : IterableDataRegion.US
        config.enableEmbeddedMessaging = map["enableEmbeddedMessaging"] as? Bool ?? false
        config.mobileFrameworkInfo = IterableAPIMobileFrameworkInfo(
            frameworkType: .flutter,
            iterableSdkVersion: map["version"] as? String)

        let maxRetry = map["authRetryMaxRetries"] as? Int ?? 1
        let retryInterval = map["authRetryIntervalSeconds"] as? Double ?? 3.0
        config.retryPolicy = RetryPolicy(maxRetry: maxRetry, retryInterval: retryInterval, retryBackoff: .linear)

        config.inAppDelegate = self
        if map["hasUrlHandler"] as? Bool == true {
            config.urlDelegate = self
        }
        if map["hasCustomActionHandler"] as? Bool == true {
            config.customActionDelegate = self
        }
        if map["hasAuthHandler"] as? Bool == true {
            config.authDelegate = self
        }
        return config
    }

    private func updateSubscriptions(args: [String: Any]) {
        func numbers(_ key: String) -> [NSNumber]? {
            (args[key] as? [Int])?.map { NSNumber(value: $0) }
        }
        IterableAPI.updateSubscriptions(numbers("emailListIds"),
                                        unsubscribedChannelIds: numbers("unsubscribedChannelIds"),
                                        unsubscribedMessageTypeIds: numbers("unsubscribedMessageTypeIds"),
                                        subscribedMessageTypeIds: numbers("subscribedMessageTypeIds"),
                                        campaignId: (args["campaignId"] as? Int).map { NSNumber(value: $0) },
                                        templateId: (args["templateId"] as? Int).map { NSNumber(value: $0) },
                                        onSuccess: nil,
                                        onFailure: nil)
    }

    private func registerForPush() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    // MARK: - AppDelegate forwarding helpers

    public static func register(deviceToken: Data) {
        IterableAPI.register(token: deviceToken)
    }

    @objc(setDeviceToken:)
    public static func setDeviceToken(_ deviceToken: Data) {
        IterableAPI.register(token: deviceToken)
    }

    /// Converts an APNs device token expressed as a hex string (as returned by
    /// `FirebaseMessaging.getAPNSToken()`) into the `Data` the Iterable SDK expects.
    private static func dataFromHexToken(_ token: String) -> Data? {
        let cleaned = token
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty, cleaned.count % 2 == 0 else { return nil }

        var data = Data(capacity: cleaned.count / 2)
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let next = cleaned.index(index, offsetBy: 2)
            guard let byte = UInt8(cleaned[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }

    // MARK: - FlutterApplicationLifeCycleDelegate

    public func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        IterableAPI.register(token: deviceToken)
    }

    public func application(_ application: UIApplication,
                            didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        IterableAppIntegration.application(application,
                                          didReceiveRemoteNotification: userInfo,
                                          fetchCompletionHandler: completionHandler)
        return true
    }

    // MARK: - Lookups

    private func findInApp(_ args: [String: Any]) -> IterableInAppMessage? {
        guard let id = args["messageId"] as? String else { return nil }
        return IterableAPI.inAppManager.getMessage(withId: id)
    }

    private func findEmbedded(_ args: [String: Any]) -> IterableEmbeddedMessage? {
        guard let id = args["messageId"] as? String else { return nil }
        return IterableAPI.embeddedManager.getMessages().first { $0.metadata.messageId == id }
    }

    // MARK: - Serialization

    private func commerceItems(from value: Any?) -> [CommerceItem] {
        guard let list = value as? [[String: Any]] else { return [] }
        return list.map { item in
            CommerceItem(id: item["id"] as? String ?? "",
                         name: item["name"] as? String ?? "",
                         price: NSNumber(value: item["price"] as? Double ?? 0),
                         quantity: UInt(item["quantity"] as? Int ?? 0),
                         sku: item["sku"] as? String,
                         description: item["description"] as? String,
                         url: item["url"] as? String,
                         imageUrl: item["imageUrl"] as? String,
                         categories: item["categories"] as? [String],
                         dataFields: item["dataFields"] as? [AnyHashable: Any])
        }
    }

    private func attributionMap(_ info: IterableAttributionInfo?) -> [String: Any]? {
        guard let info = info else { return nil }
        return [
            "campaignId": info.campaignId.intValue,
            "templateId": info.templateId.intValue,
            "messageId": info.messageId
        ]
    }

    private func inAppMessageMap(_ message: IterableInAppMessage) -> [String: Any] {
        var map: [String: Any] = [
            "messageId": message.messageId,
            "saveToInbox": message.saveToInbox,
            "read": message.read,
            "priorityLevel": message.priorityLevel
        ]
        if let campaignId = message.campaignId { map["campaignId"] = campaignId.intValue }
        if let createdAt = message.createdAt { map["createdAt"] = Int(createdAt.timeIntervalSince1970 * 1000) }
        if let expiresAt = message.expiresAt { map["expiresAt"] = Int(expiresAt.timeIntervalSince1970 * 1000) }
        if let payload = message.customPayload as? [String: Any] { map["customPayload"] = payload }
        if let inbox = message.inboxMetadata {
            map["inboxTitle"] = inbox.title
            map["inboxSubtitle"] = inbox.subtitle
            map["inboxIconUrl"] = inbox.icon
        }
        return map
    }

    private func embeddedMap(_ message: IterableEmbeddedMessage) -> [String: Any] {
        var metadata: [String: Any] = ["messageId": message.metadata.messageId]
        if let campaignId = message.metadata.campaignId { metadata["campaignId"] = campaignId }
        if let placementId = message.metadata.placementId { metadata["placementId"] = placementId }
        if let isProof = message.metadata.isProof { metadata["isProof"] = isProof }

        var map: [String: Any] = ["metadata": metadata]
        if let elements = message.elements {
            var el: [String: Any] = [:]
            el["title"] = elements.title
            el["body"] = elements.body
            el["mediaUrl"] = elements.mediaUrl
            el["mediaUrlCaption"] = elements.mediaUrlCaption
            if let defaultAction = elements.defaultAction {
                el["defaultAction"] = ["type": defaultAction.type, "data": defaultAction.data as Any]
            }
            if let buttons = elements.buttons {
                el["buttons"] = buttons.map { button -> [String: Any] in
                    var b: [String: Any] = ["id": button.id]
                    b["title"] = button.title
                    if let action = button.action {
                        b["action"] = ["type": action.type, "data": action.data as Any]
                    }
                    return b
                }
            }
            if let text = elements.text {
                el["text"] = text.map { ["id": $0.id, "text": $0.text as Any] }
            }
            map["elements"] = el.compactMapValues { $0 }
        }
        if let payload = message.payload as? [String: Any] { map["payload"] = payload }
        return map
    }

    // MARK: - Enum mapping

    private func inAppLocation(_ value: Any?) -> InAppLocation {
        return (value as? Int) == 1 ? .inbox : .inApp
    }

    private func closeSource(_ value: Any?) -> InAppCloseSource {
        return (value as? Int) == 1 ? .link : .back
    }

    private func deleteSource(_ value: Any?) -> InAppDeleteSource {
        return (value as? Int) == 1 ? .deleteButton : .inboxSwipe
    }

    private func actionMap(_ action: IterableAction?) -> [String: Any] {
        return [
            "type": action?.type as Any,
            "data": action?.data as Any,
            "userInput": action?.userInput as Any
        ]
    }

    private func actionContextMap(_ context: IterableActionContext) -> [String: Any] {
        let source: Int
        switch context.source {
        case .universalLink: source = 1
        case .inApp: source = 2
        case .embedded: source = 3
        default: source = 0
        }
        return ["action": actionMap(context.action), "source": source]
    }

    private func invokeFlutter(_ method: String, _ arguments: [String: Any?]) {
        DispatchQueue.main.async {
            self.channel.invokeMethod(method, arguments: arguments)
        }
    }
}

// MARK: - Iterable delegates

extension IterableSdkPlugin: IterableURLDelegate {
    public func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
        invokeFlutter("urlHandler", ["url": url.absoluteString, "context": actionContextMap(context)])
        return true
    }
}

extension IterableSdkPlugin: IterableCustomActionDelegate {
    public func handle(iterableCustomAction action: IterableAction, inContext context: IterableActionContext) -> Bool {
        invokeFlutter("customActionHandler", ["action": actionMap(action), "context": actionContextMap(context)])
        return true
    }
}

extension IterableSdkPlugin: IterableInAppDelegate {
    public func onNew(message: IterableInAppMessage) -> InAppShowResponse {
        invokeFlutter("handleInAppReceived", ["message": inAppMessageMap(message)])
        return autoDisplayPaused ? .skip : .show
    }
}

extension IterableSdkPlugin: IterableAuthDelegate {
    public func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
        DispatchQueue.main.async {
            self.channel.invokeMethod("authHandler",
                                      arguments: ["email": IterableAPI.email, "userId": IterableAPI.userId]) { value in
                completion(value as? String)
            }
        }
    }

    public func onAuthFailure(_ authFailure: AuthFailure) {
        invokeFlutter("authFailure", ["reason": "\(authFailure.failureReason)"])
    }
}

extension IterableSdkPlugin: IterableEmbeddedUpdateDelegate {
    public func onMessagesUpdated() {
        let messages = IterableAPI.embeddedManager.getMessages().map { embeddedMap($0) }
        invokeFlutter("handleEmbeddedMessagesUpdated", ["messages": messages])
    }

    public func onEmbeddedMessagingDisabled() {}
}
