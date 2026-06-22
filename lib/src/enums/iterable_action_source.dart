/// Identifies what triggered an [IterableAction].
enum IterableActionSource {
  push(0),
  appLink(1),
  inApp(2);

  const IterableActionSource(this.value);

  /// Wire value received from the native bridge.
  final int value;

  static IterableActionSource fromValue(int? value) {
    switch (value) {
      case 1:
        return IterableActionSource.appLink;
      case 2:
        return IterableActionSource.inApp;
      default:
        return IterableActionSource.push;
    }
  }
}
