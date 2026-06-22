import 'dart:async';

import 'package:flutter/services.dart';

import 'iterable_config.dart';
import 'iterable_embedded_manager.dart';
import 'iterable_in_app_manager.dart';
import 'enums/iterable_in_app_show_response.dart';
import 'models/iterable_action.dart';
import 'models/iterable_action_context.dart';
import 'models/iterable_attribution_info.dart';
import 'models/iterable_auth_request.dart';
import 'models/iterable_commerce_item.dart';
import 'models/iterable_embedded_message.dart';
import 'models/iterable_in_app_message.dart';

/// Entry point for the Iterable Flutter SDK.
///
/// All methods are static. Call [initialize] once during app startup before
/// invoking any other method.
class IterableAPI {
  IterableAPI._();

  /// Imperative channel used for both Flutter -> native calls and native ->
  /// Flutter callbacks (handlers that must return a value to the native SDK).
  static const MethodChannel _channel = MethodChannel('iterable_sdk/method');

  static IterableConfig? _config;

  static final StreamController<Map<String, dynamic>> _pushOpenedController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<IterableInAppMessage> _inAppReceivedController =
      StreamController<IterableInAppMessage>.broadcast();
  static final StreamController<void> _inAppInboxChangedController =
      StreamController<void>.broadcast();
  static final StreamController<List<IterableEmbeddedMessage>>
      _embeddedUpdatedController =
      StreamController<List<IterableEmbeddedMessage>>.broadcast();

  /// In-app message manager.
  static final IterableInAppManager inAppManager =
      IterableInAppManager(_channel);

  /// Embedded message manager.
  static final IterableEmbeddedManager embeddedManager =
      IterableEmbeddedManager(_channel);

  /// Emits the notification payload each time a push is opened.
  static Stream<Map<String, dynamic>> get onPushOpened =>
      _pushOpenedController.stream;

  /// Emits whenever a new in-app message is received.
  static Stream<IterableInAppMessage> get onInAppReceived =>
      _inAppReceivedController.stream;

  /// Emits whenever the in-app inbox contents change.
  static Stream<void> get onInboxChanged => _inAppInboxChangedController.stream;

  /// Emits the latest embedded messages whenever the native cache updates.
  static Stream<List<IterableEmbeddedMessage>> get onEmbeddedMessagesUpdated =>
      _embeddedUpdatedController.stream;

  // --------------------------------------------------------------------------
  // Initialization & identity
  // --------------------------------------------------------------------------

  /// Initializes the SDK. Returns `true` on success.
  static Future<bool> initialize(
    String apiKey,
    IterableConfig config,
  ) async {
    _config = config;
    _channel.setMethodCallHandler(_handleNativeCall);
    final bool? result = await _channel.invokeMethod<bool>('initialize', {
      'apiKey': apiKey,
      'config': config.toMap(),
      'version': '0.0.1',
    });
    return result ?? false;
  }

  static Future<void> setEmail(String? email, {String? authToken}) {
    return _channel.invokeMethod('setEmail', {
      'email': email,
      'authToken': authToken,
    });
  }

  static Future<void> setUserId(String? userId, {String? authToken}) {
    return _channel.invokeMethod('setUserId', {
      'userId': userId,
      'authToken': authToken,
    });
  }

  static Future<String?> getEmail() {
    return _channel.invokeMethod<String?>('getEmail');
  }

  static Future<String?> getUserId() {
    return _channel.invokeMethod<String?>('getUserId');
  }

  static Future<void> updateEmail(String newEmail, {String? authToken}) {
    return _channel.invokeMethod('updateEmail', {
      'newEmail': newEmail,
      'authToken': authToken,
    });
  }

  static Future<void> updateUser(
    Map<String, dynamic> dataFields, {
    bool mergeNestedObjects = false,
  }) {
    return _channel.invokeMethod('updateUser', {
      'dataFields': dataFields,
      'mergeNestedObjects': mergeNestedObjects,
    });
  }

  static Future<void> updateSubscriptions({
    List<int>? emailListIds,
    List<int>? unsubscribedChannelIds,
    List<int>? unsubscribedMessageTypeIds,
    List<int>? subscribedMessageTypeIds,
    int? campaignId,
    int? templateId,
  }) {
    return _channel.invokeMethod('updateSubscriptions', {
      'emailListIds': emailListIds,
      'unsubscribedChannelIds': unsubscribedChannelIds,
      'unsubscribedMessageTypeIds': unsubscribedMessageTypeIds,
      'subscribedMessageTypeIds': subscribedMessageTypeIds,
      'campaignId': campaignId,
      'templateId': templateId,
    });
  }

  /// Clears the current user and disables push for the previous user.
  static Future<void> logout() {
    return _channel.invokeMethod('logout');
  }

  // --------------------------------------------------------------------------
  // Event tracking & commerce
  // --------------------------------------------------------------------------

  static Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? dataFields,
  }) {
    return _channel.invokeMethod('trackEvent', {
      'name': name,
      'dataFields': dataFields,
    });
  }

  static Future<void> trackPurchase(
    double total,
    List<IterableCommerceItem> items, {
    Map<String, dynamic>? dataFields,
  }) {
    return _channel.invokeMethod('trackPurchase', {
      'total': total,
      'items': items.map((IterableCommerceItem e) => e.toMap()).toList(),
      'dataFields': dataFields,
    });
  }

  static Future<void> updateCart(List<IterableCommerceItem> items) {
    return _channel.invokeMethod('updateCart', {
      'items': items.map((IterableCommerceItem e) => e.toMap()).toList(),
    });
  }

  static Future<void> trackPushOpen(
    int campaignId,
    int templateId,
    String? messageId, {
    bool appAlreadyRunning = false,
    Map<String, dynamic>? dataFields,
  }) {
    return _channel.invokeMethod('trackPushOpen', {
      'campaignId': campaignId,
      'templateId': templateId,
      'messageId': messageId,
      'appAlreadyRunning': appAlreadyRunning,
      'dataFields': dataFields,
    });
  }

  static Future<IterableAttributionInfo?> getAttributionInfo() async {
    final Map<dynamic, dynamic>? map =
        await _channel.invokeMethod<Map<dynamic, dynamic>?>(
      'getAttributionInfo',
    );
    if (map == null) return null;
    return IterableAttributionInfo.fromMap(map.cast<String, dynamic>());
  }

  static Future<void> setAttributionInfo(IterableAttributionInfo? info) {
    return _channel.invokeMethod('setAttributionInfo', {
      'attributionInfo': info?.toMap(),
    });
  }

  // --------------------------------------------------------------------------
  // Push notifications
  // --------------------------------------------------------------------------

  /// Registers the current device for push notifications.
  ///
  /// On iOS this requests notification authorization and registers with APNs;
  /// the resulting token is forwarded to Iterable automatically. On Android the
  /// native SDK fetches and registers the FCM token itself.
  ///
  /// If your app manages push tokens itself (for example through
  /// `firebase_messaging`), call [registerDeviceToken] with the token instead
  /// of, or in addition to, this method.
  static Future<void> registerForPush() {
    return _channel.invokeMethod('registerForPush');
  }

  /// Registers an externally obtained push token with Iterable.
  ///
  /// Pass the FCM registration token on Android and the APNs device token
  /// (the hex string returned by `FirebaseMessaging.getAPNSToken()`) on iOS.
  static Future<void> registerDeviceToken(String token) {
    return _channel.invokeMethod('registerDeviceToken', {'token': token});
  }

  /// Disables push notifications for the current device.
  static Future<void> disablePush() {
    return _channel.invokeMethod('disablePush');
  }

  /// Returns the payload of the most recent push, if any.
  static Future<Map<String, dynamic>?> getLastPushPayload() async {
    final Map<dynamic, dynamic>? map =
        await _channel.invokeMethod<Map<dynamic, dynamic>?>(
      'getLastPushPayload',
    );
    return map?.cast<String, dynamic>();
  }

  // --------------------------------------------------------------------------
  // In-app auto-display control
  // --------------------------------------------------------------------------

  /// Pauses or resumes automatic display of incoming in-app messages.
  static Future<void> setAutoDisplayPaused(bool paused) {
    return _channel.invokeMethod('setAutoDisplayPaused', {'paused': paused});
  }

  // --------------------------------------------------------------------------
  // Native -> Flutter dispatch
  // --------------------------------------------------------------------------

  static Future<dynamic> _handleNativeCall(MethodCall call) async {
    final Map<String, dynamic> args =
        (call.arguments as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    switch (call.method) {
      case 'urlHandler':
        final handler = _config?.urlHandler;
        if (handler == null) return false;
        return handler(
          args['url'] as String? ?? '',
          IterableActionContext.fromMap(
            (args['context'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{},
          ),
        );

      case 'customActionHandler':
        final handler = _config?.customActionHandler;
        if (handler == null) return false;
        return handler(
          IterableAction.fromMap(
            (args['action'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{},
          ),
          IterableActionContext.fromMap(
            (args['context'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{},
          ),
        );

      case 'authHandler':
        final handler = _config?.authHandler;
        if (handler == null) return null;
        return handler(IterableAuthRequest.fromMap(args));

      case 'inAppHandler':
        final handler = _config?.inAppHandler;
        if (handler == null) return IterableInAppShowResponse.show.value;
        final response = handler(
          IterableInAppMessage.fromMap(
            (args['message'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{},
          ),
        );
        return response.value;

      case 'handlePushOpened':
        _pushOpenedController.add(args);
        return null;

      case 'handleInAppReceived':
        _inAppReceivedController.add(
          IterableInAppMessage.fromMap(
            (args['message'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{},
          ),
        );
        return null;

      case 'handleInboxChanged':
        _inAppInboxChangedController.add(null);
        return null;

      case 'handleEmbeddedMessagesUpdated':
        final List<dynamic> messages =
            (args['messages'] as List?) ?? <dynamic>[];
        _embeddedUpdatedController.add(
          messages
              .map((dynamic e) => IterableEmbeddedMessage.fromMap(
                    (e as Map).cast<String, dynamic>(),
                  ))
              .toList(),
        );
        return null;

      default:
        return null;
    }
  }
}
