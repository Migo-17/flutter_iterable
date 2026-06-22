/// Where an in-app message is being displayed from.
enum IterableInAppLocation {
  inApp(0),
  inbox(1);

  const IterableInAppLocation(this.value);

  /// Wire value sent across the method channel.
  final int value;

  static IterableInAppLocation fromValue(int? value) {
    switch (value) {
      case 1:
        return IterableInAppLocation.inbox;
      default:
        return IterableInAppLocation.inApp;
    }
  }
}
