import 'package:flutter/services.dart';

import 'enums/iterable_in_app_close_source.dart';
import 'enums/iterable_in_app_delete_source.dart';
import 'enums/iterable_in_app_location.dart';
import 'models/iterable_in_app_message.dart';

/// Wraps the native in-app message manager.
class IterableInAppManager {
  IterableInAppManager(this._channel);

  final MethodChannel _channel;

  /// Returns the in-app messages currently in the local queue.
  Future<List<IterableInAppMessage>> getMessages() async {
    final List<dynamic>? raw =
        await _channel.invokeMethod<List<dynamic>>('inApp.getMessages');
    return _decode(raw);
  }

  /// Returns only the in-app messages flagged to be saved to the inbox.
  Future<List<IterableInAppMessage>> getInboxMessages() async {
    final List<dynamic>? raw =
        await _channel.invokeMethod<List<dynamic>>('inApp.getInboxMessages');
    return _decode(raw);
  }

  /// Displays an in-app message. Returns the URL of a clicked button, if any.
  Future<String?> showMessage(
    IterableInAppMessage message, {
    bool consume = true,
  }) {
    return _channel.invokeMethod<String?>('inApp.showMessage', {
      'messageId': message.messageId,
      'consume': consume,
    });
  }

  /// Removes a message from the queue.
  Future<void> removeMessage(
    IterableInAppMessage message,
    IterableInAppLocation location,
    IterableInAppDeleteSource source,
  ) {
    return _channel.invokeMethod('inApp.removeMessage', {
      'messageId': message.messageId,
      'location': location.value,
      'source': source.value,
    });
  }

  /// Sets the read state of a message.
  Future<void> setRead(IterableInAppMessage message, bool read) {
    return _channel.invokeMethod('inApp.setReadForMessage', {
      'messageId': message.messageId,
      'read': read,
    });
  }

  /// Returns the count of unread inbox messages.
  Future<int> getUnreadInboxMessagesCount() async {
    final int? count =
        await _channel.invokeMethod<int>('inApp.getUnreadInboxMessagesCount');
    return count ?? 0;
  }

  Future<void> trackInAppOpen(
    IterableInAppMessage message,
    IterableInAppLocation location,
  ) {
    return _channel.invokeMethod('inApp.trackInAppOpen', {
      'messageId': message.messageId,
      'location': location.value,
    });
  }

  Future<void> trackInAppClick(
    IterableInAppMessage message,
    IterableInAppLocation location,
    String clickedUrl,
  ) {
    return _channel.invokeMethod('inApp.trackInAppClick', {
      'messageId': message.messageId,
      'location': location.value,
      'clickedUrl': clickedUrl,
    });
  }

  Future<void> trackInAppClose(
    IterableInAppMessage message,
    IterableInAppLocation location,
    IterableInAppCloseSource source, {
    String? clickedUrl,
  }) {
    return _channel.invokeMethod('inApp.trackInAppClose', {
      'messageId': message.messageId,
      'location': location.value,
      'source': source.value,
      'clickedUrl': clickedUrl,
    });
  }

  /// Consumes a message, removing it from the queue.
  Future<void> inAppConsume(
    IterableInAppMessage message,
    IterableInAppLocation location,
    IterableInAppDeleteSource source,
  ) {
    return _channel.invokeMethod('inApp.inAppConsume', {
      'messageId': message.messageId,
      'location': location.value,
      'source': source.value,
    });
  }

  List<IterableInAppMessage> _decode(List<dynamic>? raw) {
    if (raw == null) return <IterableInAppMessage>[];
    return raw
        .map((dynamic e) =>
            IterableInAppMessage.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
