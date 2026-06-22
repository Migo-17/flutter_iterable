/// Describes how an in-app message was closed.
enum IterableInAppCloseSource {
  back(0),
  link(1),
  unknown(100);

  const IterableInAppCloseSource(this.value);

  /// Wire value sent across the method channel.
  final int value;

  static IterableInAppCloseSource fromValue(int? value) {
    switch (value) {
      case 0:
        return IterableInAppCloseSource.back;
      case 1:
        return IterableInAppCloseSource.link;
      default:
        return IterableInAppCloseSource.unknown;
    }
  }
}
