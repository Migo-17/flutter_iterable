/// An action defined on an Iterable button or link.
class IterableAction {
  IterableAction({
    required this.type,
    this.data,
    this.userInput,
  });

  /// Action type, e.g. `openUrl` or a custom action name.
  final String type;

  /// Additional data associated with the action.
  final String? data;

  /// Text the user provided, when the action came from a text input.
  final String? userInput;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type,
      if (data != null) 'data': data,
      if (userInput != null) 'userInput': userInput,
    };
  }

  factory IterableAction.fromMap(Map<String, dynamic> map) {
    return IterableAction(
      type: (map['type'] as String?) ?? '',
      data: map['data'] as String?,
      userInput: map['userInput'] as String?,
    );
  }
}
