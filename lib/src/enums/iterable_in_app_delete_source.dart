/// Describes how an in-app message was removed.
enum IterableInAppDeleteSource {
  inboxSwipe(0),
  deleteButton(1),
  unknown(100);

  const IterableInAppDeleteSource(this.value);

  /// Wire value sent across the method channel.
  final int value;

  static IterableInAppDeleteSource fromValue(int? value) {
    switch (value) {
      case 0:
        return IterableInAppDeleteSource.inboxSwipe;
      case 1:
        return IterableInAppDeleteSource.deleteButton;
      default:
        return IterableInAppDeleteSource.unknown;
    }
  }
}
