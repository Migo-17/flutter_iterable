## 0.1.0

### Changed

* Upgraded the native SDKs: `com.iterable:iterableapi` `3.5.13` -> `3.10.1` on
  Android, `Iterable-iOS-SDK` `~> 6.7` -> `~> 6.7.5` on iOS (Swift Package
  Manager: `from: "6.7.5"`).
* Android now reports the plugin to Iterable as the Flutter mobile framework,
  matching iOS.
* `IterableAPI.initialize` returns `false` instead of `true` when the native SDK
  was not initialized (for example, an empty API key), and reports the plugin
  version correctly to Iterable (it was previously read from the wrong place on
  iOS and never sent on Android).

### Added

* `IterableAPI.isInitialized()`, which asks the native SDK whether it is
  initialized rather than remembering whether `initialize` was called. It stays
  correct after a Flutter engine restart and when the host app initializes
  Iterable natively.
* `IterableAPI.version`, the plugin version reported to Iterable.

### Fixed

* **iOS crash when a push opened the app from a terminated state.** The plugin
  handed the system's notification completion handler to
  `IterableAppIntegration`, which drops it while the SDK is not yet initialized
  — exactly the cold-start case, since `initialize()` cannot run before the
  Flutter engine is up. iOS terminates an app whose notification completion
  handler is never called. The plugin now always calls the completion handler
  itself; Iterable still replays the stashed tap once the SDK is initialized.
* iOS: in-app and embedded method calls made before initialization no longer
  reach `IterableAPI.inAppManager` / `embeddedManager`, which trip an
  `assertionFailure` (a crash in debug builds) when the SDK is not initialized.
* `onPushOpened` no longer drops a push open that arrives before app code
  subscribes; such payloads are buffered and replayed to the first subscriber.
* Android: `setAutoDisplayPaused` is now forwarded to the native in-app manager
  instead of only being recorded in the plugin.
* Android: `trackPushOpen` now passes `appAlreadyRunning` through to the native
  SDK, and `IterableActionSource.EMBEDDED` maps to the embedded action source
  rather than falling back to push.

## 0.0.1

Initial release wrapping the native Iterable SDKs
(`com.iterable:iterableapi:3.5.13` on Android, `Iterable-iOS-SDK ~> 6.6` on iOS).

* User identity: set/update email & user id, update user fields, update
  subscriptions, logout.
* Event & commerce tracking: custom events, purchases, cart updates, push opens,
  attribution info.
* Push notifications: registration, disable, last push payload, push-opened stream.
* In-app messages: queue/inbox access, show/remove/consume, read state,
  impression & click tracking, receive stream.
* Embedded messages: sync, fetch by placement, click tracking, update stream.
* Deep-link and custom-action handlers.
* JWT (token-based) authentication via an async auth handler.
