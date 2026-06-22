import '../enums/iterable_action_source.dart';
import 'iterable_action.dart';

/// Context describing where an [IterableAction] was triggered from.
class IterableActionContext {
  IterableActionContext({
    required this.action,
    required this.source,
  });

  final IterableAction action;
  final IterableActionSource source;

  factory IterableActionContext.fromMap(Map<String, dynamic> map) {
    return IterableActionContext(
      action: IterableAction.fromMap(
        (map['action'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
      source: IterableActionSource.fromValue((map['source'] as num?)?.toInt()),
    );
  }
}
