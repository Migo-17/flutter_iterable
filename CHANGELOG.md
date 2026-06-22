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
