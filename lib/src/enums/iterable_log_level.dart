/// Controls how verbose the native Iterable SDKs are.
///
/// The integer values match the convention used by Iterable's React Native
/// SDK so the native bridges can translate them directly.
enum IterableLogLevel {
  debug(1),
  info(2),
  error(3);

  const IterableLogLevel(this.value);

  /// Wire value sent across the method channel.
  final int value;
}
