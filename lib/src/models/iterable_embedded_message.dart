/// Metadata identifying an embedded message and its placement.
class IterableEmbeddedMessageMetadata {
  IterableEmbeddedMessageMetadata({
    required this.messageId,
    this.campaignId,
    this.placementId,
    this.isProof = false,
  });

  final String messageId;
  final int? campaignId;
  final int? placementId;
  final bool isProof;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'messageId': messageId,
      if (campaignId != null) 'campaignId': campaignId,
      if (placementId != null) 'placementId': placementId,
      'isProof': isProof,
    };
  }

  factory IterableEmbeddedMessageMetadata.fromMap(Map<String, dynamic> map) {
    return IterableEmbeddedMessageMetadata(
      messageId: map['messageId'] as String,
      campaignId: (map['campaignId'] as num?)?.toInt(),
      placementId: (map['placementId'] as num?)?.toInt(),
      isProof: (map['isProof'] as bool?) ?? false,
    );
  }
}

/// A button defined on an embedded message.
class IterableEmbeddedMessageButton {
  IterableEmbeddedMessageButton({
    required this.id,
    this.title,
    this.action,
  });

  final String id;
  final String? title;
  final IterableEmbeddedMessageAction? action;

  factory IterableEmbeddedMessageButton.fromMap(Map<String, dynamic> map) {
    return IterableEmbeddedMessageButton(
      id: (map['id'] as String?) ?? '',
      title: map['title'] as String?,
      action: map['action'] == null
          ? null
          : IterableEmbeddedMessageAction.fromMap(
              (map['action'] as Map).cast<String, dynamic>(),
            ),
    );
  }
}

/// An action attached to an embedded message element or button.
class IterableEmbeddedMessageAction {
  IterableEmbeddedMessageAction({this.type, this.data});

  final String? type;
  final String? data;

  factory IterableEmbeddedMessageAction.fromMap(Map<String, dynamic> map) {
    return IterableEmbeddedMessageAction(
      type: map['type'] as String?,
      data: map['data'] as String?,
    );
  }
}

/// Display content of an embedded message.
class IterableEmbeddedMessageElements {
  IterableEmbeddedMessageElements({
    this.title,
    this.body,
    this.mediaUrl,
    this.mediaUrlCaption,
    this.defaultAction,
    this.buttons,
    this.text,
  });

  final String? title;
  final String? body;
  final String? mediaUrl;
  final String? mediaUrlCaption;
  final IterableEmbeddedMessageAction? defaultAction;
  final List<IterableEmbeddedMessageButton>? buttons;
  final List<Map<String, dynamic>>? text;

  factory IterableEmbeddedMessageElements.fromMap(Map<String, dynamic> map) {
    return IterableEmbeddedMessageElements(
      title: map['title'] as String?,
      body: map['body'] as String?,
      mediaUrl: map['mediaUrl'] as String?,
      mediaUrlCaption: map['mediaUrlCaption'] as String?,
      defaultAction: map['defaultAction'] == null
          ? null
          : IterableEmbeddedMessageAction.fromMap(
              (map['defaultAction'] as Map).cast<String, dynamic>(),
            ),
      buttons: (map['buttons'] as List?)
          ?.map((dynamic e) => IterableEmbeddedMessageButton.fromMap(
                (e as Map).cast<String, dynamic>(),
              ))
          .toList(),
      text: (map['text'] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
    );
  }
}

/// A complete embedded message.
class IterableEmbeddedMessage {
  IterableEmbeddedMessage({
    required this.metadata,
    this.elements,
    this.payload,
  });

  final IterableEmbeddedMessageMetadata metadata;
  final IterableEmbeddedMessageElements? elements;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'metadata': metadata.toMap(),
      if (payload != null) 'payload': payload,
    };
  }

  factory IterableEmbeddedMessage.fromMap(Map<String, dynamic> map) {
    return IterableEmbeddedMessage(
      metadata: IterableEmbeddedMessageMetadata.fromMap(
        (map['metadata'] as Map).cast<String, dynamic>(),
      ),
      elements: map['elements'] == null
          ? null
          : IterableEmbeddedMessageElements.fromMap(
              (map['elements'] as Map).cast<String, dynamic>(),
            ),
      payload: (map['payload'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
