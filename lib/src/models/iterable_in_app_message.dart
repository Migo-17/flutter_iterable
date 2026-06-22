/// Represents an in-app message returned by the native SDK.
class IterableInAppMessage {
  IterableInAppMessage({
    required this.messageId,
    required this.campaignId,
    this.trigger,
    this.createdAt,
    this.expiresAt,
    this.saveToInbox = false,
    this.read = false,
    this.customPayload,
    this.priorityLevel,
    this.inboxTitle,
    this.inboxSubtitle,
    this.inboxIconUrl,
  });

  final String messageId;
  final int? campaignId;

  /// Trigger type, e.g. `immediate`, `event`, `never`.
  final String? trigger;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool saveToInbox;
  final bool read;
  final Map<String, dynamic>? customPayload;
  final double? priorityLevel;
  final String? inboxTitle;
  final String? inboxSubtitle;
  final String? inboxIconUrl;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'messageId': messageId,
      if (campaignId != null) 'campaignId': campaignId,
      if (trigger != null) 'trigger': trigger,
      if (createdAt != null) 'createdAt': createdAt!.millisecondsSinceEpoch,
      if (expiresAt != null) 'expiresAt': expiresAt!.millisecondsSinceEpoch,
      'saveToInbox': saveToInbox,
      'read': read,
      if (customPayload != null) 'customPayload': customPayload,
      if (priorityLevel != null) 'priorityLevel': priorityLevel,
      if (inboxTitle != null) 'inboxTitle': inboxTitle,
      if (inboxSubtitle != null) 'inboxSubtitle': inboxSubtitle,
      if (inboxIconUrl != null) 'inboxIconUrl': inboxIconUrl,
    };
  }

  factory IterableInAppMessage.fromMap(Map<String, dynamic> map) {
    return IterableInAppMessage(
      messageId: map['messageId'] as String,
      campaignId: (map['campaignId'] as num?)?.toInt(),
      trigger: map['trigger'] as String?,
      createdAt: _dateFromMillis(map['createdAt']),
      expiresAt: _dateFromMillis(map['expiresAt']),
      saveToInbox: (map['saveToInbox'] as bool?) ?? false,
      read: (map['read'] as bool?) ?? false,
      customPayload: (map['customPayload'] as Map?)?.cast<String, dynamic>(),
      priorityLevel: (map['priorityLevel'] as num?)?.toDouble(),
      inboxTitle: map['inboxTitle'] as String?,
      inboxSubtitle: map['inboxSubtitle'] as String?,
      inboxIconUrl: map['inboxIconUrl'] as String?,
    );
  }

  static DateTime? _dateFromMillis(Object? value) {
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch((value as num).toInt());
  }
}
