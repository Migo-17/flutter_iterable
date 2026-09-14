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

  /// Push-opened payloads that arrived before anything listened to
  /// [onPushOpened]. A push that launches the app from a terminated state is
  /// delivered by the native SDK while Flutter is still starting up, so the
  /// event would otherwise be dropped by the broadcast controller.
  static final List<Map<String, dynamic>> _pendingPushOpened =
      <Map<String, dynamic>>[];
  static const int _maxPendingPushOpened = 5;

  static final StreamController<Map<String, dynamic>> _pushOpenedController =
      StreamController<Map<String, dynamic>>.broadcast(
    onListen: _flushPendingPushOpened,
  );
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

  /// Version of this plugin. Reported to Iterable as the mobile framework
  /// version, and kept in sync with `pubspec.yaml`.
  static const String version = '0.1.0';

  /// Initializes the SDK. Returns `true` once the native Iterable SDK has
  /// actually been initialized, `false` otherwise (for example when [apiKey]
  /// is empty).
  static Future<bool> initialize(
    String apiKey,
    IterableConfig config,
  ) async {
    if (apiKey.isEmpty) {
      return false;
    }
    _config = config;
    _channel.setMethodCallHandler(_handleNativeCall);
    final bool? result = await _channel.invokeMethod<bool>('initialize', {
      'apiKey': apiKey,
      'config': config.toMap(),
      'version': version,
    });
    return result ?? false;
  }

  /// Whether the native Iterable SDK is initialized.
  ///
  /// Answered by the native side, so it reports `false` when [initialize]
  /// failed and stays `true` when the Flutter engine restarted while the
  /// process — and with it the native SDK — lived on.
  ///
  /// Android asks the SDK directly, so it also reports `true` when the host app
  /// initialized Iterable in native code. iOS exposes no public API for that,
  /// so there it covers initialization performed through this plugin.
  static Future<bool> isInitialized() async {
    final bool? result = await _channel.invokeMethod<bool>('isInitialized');
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

  /// Replays push-opened payloads buffered before the first [onPushOpened]
  /// subscription. Scheduled as a microtask so the subscription that triggered
  /// this is fully installed before the events are delivered.
  static void _flushPendingPushOpened() {
    if (_pendingPushOpened.isEmpty) return;
    final List<Map<String, dynamic>> pending =
        List<Map<String, dynamic>>.of(_pendingPushOpened);
    _pendingPushOpened.clear();
    scheduleMicrotask(() {
      for (final Map<String, dynamic> payload in pending) {
        _pushOpenedController.add(payload);
      }
    });
  }

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
        if (_pushOpenedController.hasListener) {
          _pushOpenedController.add(args);
        } else {
          if (_pendingPushOpened.length >= _maxPendingPushOpened) {
            _pendingPushOpened.removeAt(0);
          }
          _pendingPushOpened.add(args);
        }
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
