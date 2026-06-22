/// Return value for an in-app message handler controlling auto display.
enum IterableInAppShowResponse {
  show(0),
  skip(1);

  const IterableInAppShowResponse(this.value);

  /// Wire value sent back to the native bridge.
  final int value;
}
