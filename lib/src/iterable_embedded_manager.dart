import 'package:flutter/services.dart';

import 'models/iterable_embedded_message.dart';

/// Wraps the native embedded message manager.
class IterableEmbeddedManager {
  IterableEmbeddedManager(this._channel);

  final MethodChannel _channel;

  /// Triggers a sync of embedded messages from the server.
  Future<void> syncMessages() {
    return _channel.invokeMethod('embedded.syncMessages');
  }

  /// Returns the cached embedded messages for a placement.
  Future<List<IterableEmbeddedMessage>> getMessages(int placementId) async {
    final List<dynamic>? raw = await _channel.invokeMethod<List<dynamic>>(
      'embedded.getMessages',
      {'placementId': placementId},
    );
    if (raw == null) return <IterableEmbeddedMessage>[];
    return raw
        .map((dynamic e) =>
            IterableEmbeddedMessage.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> trackEmbeddedClick(
    IterableEmbeddedMessage message, {
    String? buttonIdentifier,
    String? clickedUrl,
  }) {
    return _channel.invokeMethod('embedded.trackClick', {
      'messageId': message.metadata.messageId,
      'buttonIdentifier': buttonIdentifier,
      'clickedUrl': clickedUrl,
    });
  }

  Future<void> trackEmbeddedReceived(IterableEmbeddedMessage message) {
    return _channel.invokeMethod('embedded.trackReceived', {
      'messageId': message.metadata.messageId,
    });
  }

  Future<void> trackEmbeddedImpression(IterableEmbeddedMessage message) {
    return _channel.invokeMethod('embedded.trackImpression', {
      'messageId': message.metadata.messageId,
    });
  }

  Future<void> trackEmbeddedSession(
    Map<String, dynamic> session, {
    List<Map<String, dynamic>>? impressions,
  }) {
    return _channel.invokeMethod('embedded.trackSession', {
      'session': session,
      'impressions': impressions,
    });
  }
}
