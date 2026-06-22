/// Attribution metadata describing the campaign that drove a session.
class IterableAttributionInfo {
  IterableAttributionInfo({
    required this.campaignId,
    required this.templateId,
    required this.messageId,
  });

  final int campaignId;
  final int templateId;
  final String messageId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'campaignId': campaignId,
      'templateId': templateId,
      'messageId': messageId,
    };
  }

  factory IterableAttributionInfo.fromMap(Map<String, dynamic> map) {
    return IterableAttributionInfo(
      campaignId: (map['campaignId'] as num).toInt(),
      templateId: (map['templateId'] as num).toInt(),
      messageId: map['messageId'] as String,
    );
  }
}
