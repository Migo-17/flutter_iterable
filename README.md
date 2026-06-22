# iterable_sdk

A Flutter plugin that wraps Iterable's official native
[Android](https://github.com/Iterable/iterable-android-sdk) and
[iOS](https://github.com/Iterable/iterable-swift-sdk) SDKs.

It exposes a single, idiomatic Dart API for user identity, event &
commerce tracking, push notifications, in-app messages, embedded messages,
deep-link / custom-action handling and JWT (token-based) authentication.

| Area | Android SDK | iOS SDK |
|------|-------------|---------|
| Native dependency | `com.iterable:iterableapi:3.5.13` | `Iterable-iOS-SDK ~> 6.6` |
| Min platform | `minSdk 24` | iOS 13 |

## Features

- User identity: `setEmail`, `setUserId`, `updateEmail`, `updateUser`, `updateSubscriptions`, `logout`
- Event & commerce tracking: `trackEvent`, `trackPurchase`, `updateCart`, `trackPushOpen`, attribution info
- Push notifications: registration, disable, last push payload, push-opened stream
- In-app messages: queue/inbox access, show/remove/consume, read state, impression & click tracking, receive stream
- Embedded messages: sync, fetch by placement, click tracking, update stream
- Deep links & custom actions via `urlHandler` / `customActionHandler`
- JWT auth via an async `authHandler`

## Installation

Add the dependency to your app's `pubspec.yaml`:

```yaml
dependencies:
  iterable_sdk:
    git:
      url: https://github.com/Migo-17/flutter_iterable.git
```

### iOS setup

The plugin pulls in `Iterable-iOS-SDK` through CocoaPods automatically. Iterable
requires dynamic frameworks, so make sure your `ios/Podfile` uses:

```ruby
use_frameworks!
platform :ios, '13.0'
```

Push token forwarding and silent-push handling are wired automatically as long
as your `AppDelegate` extends `FlutterAppDelegate` (the default). If you use a
custom `AppDelegate`, forward the relevant callbacks:

```swift
import iterable_sdk

func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    IterableSdkPlugin.register(deviceToken: deviceToken)
}
```

Enable the **Push Notifications** capability and **Background Modes → Remote
notifications** in Xcode.

### Android setup

The plugin initializes Iterable using the application context, so no manual
`Application.onCreate` call is required. For push notifications you must add
Firebase Cloud Messaging to your app (Iterable uses FCM):

1. Add `google-services.json` to `android/app/`.
2. Apply the Google Services Gradle plugin in your app.

See Iterable's [FCM setup guide](https://support.iterable.com/hc/en-us/articles/115000331943)
for details.

## Usage

```dart
import 'package:iterable_sdk/iterable_sdk.dart';

final config = IterableConfig(
  pushIntegrationName: 'your.bundle.id',
  autoPushRegistration: true,
  logLevel: IterableLogLevel.info,
  enableEmbeddedMessaging: true,
  urlHandler: (url, context) {
    // Return true if your app handled the deep link.
    return false;
  },
  customActionHandler: (action, context) {
    return true;
  },
  authHandler: (request) async {
    // Return a signed JWT for request.email / request.userId.
    return await myBackend.fetchIterableJwt(request.email);
  },
);

await IterableAPI.initialize('YOUR_MOBILE_API_KEY', config);

// Identity
await IterableAPI.setEmail('user@example.com');

// Events & commerce
await IterableAPI.trackEvent('viewed_product', dataFields: {'id': 'sku-1'});
await IterableAPI.trackPurchase(19.99, [
  IterableCommerceItem(id: 'sku-1', name: 'Coffee', price: 19.99, quantity: 1),
]);

// Push
await IterableAPI.registerForPush();
IterableAPI.onPushOpened.listen((payload) => print('opened: $payload'));

// In-app
final messages = await IterableAPI.inAppManager.getMessages();
if (messages.isNotEmpty) {
  await IterableAPI.inAppManager.showMessage(messages.first);
}

// Embedded
await IterableAPI.embeddedManager.syncMessages();
IterableAPI.onEmbeddedMessagesUpdated.listen((msgs) => print(msgs.length));
```

### Registering push tokens

`registerForPush()` requests authorization and lets the native SDK obtain and
register the token (APNs on iOS, FCM on Android). If your app already manages
push tokens through `firebase_messaging`, hand the token to Iterable directly
with `registerDeviceToken`:

```dart
Future<void> registerForPush() async {
  try {
    await IterableAPI.registerForPush();

    final String? token = Platform.isIOS
        ? await FirebaseMessaging.instance.getAPNSToken()
        : await FirebaseMessaging.instance.getToken();

    if (token != null && token.isNotEmpty) {
      await IterableAPI.registerDeviceToken(token);
    }
  } catch (e) {
    debugPrint('[Iterable] Register for push failed: $e');
  }
}
```

On iOS, `registerDeviceToken` expects the APNs device token (the hex string from
`getAPNSToken()`); the plugin converts it to the `Data` the native SDK requires.
On Android it expects the FCM registration token.

## Architecture

The plugin uses a single bidirectional `MethodChannel` (`iterable_sdk/method`):

- **Dart → native** for all imperative calls.
- **native → Dart** for callbacks and notifications (push opened, in-app
  received, embedded updates, URL / custom-action / auth handlers).

Native callbacks that the Iterable SDK invokes synchronously on the main thread
(`urlHandler`, `customActionHandler`, in-app display) cannot block waiting for an
async Dart answer, so they return immediately and forward the event to Dart. The
in-app display decision is controlled with `IterableAPI.setAutoDisplayPaused`.
The JWT `authHandler` is fully asynchronous on both platforms.

## Platform notes & limitations

- `setAttributionInfo` is a no-op on Android (not part of the public Android API).
- Individual embedded impression/session tracking is handled automatically by the
  native session managers.
- CocoaPods publishes Iterable up to `6.6.x`; Swift Package Manager can use `6.7.x`.

## Development

```bash
flutter analyze
flutter test
cd example && flutter build ios --simulator   # iOS smoke build
cd example && flutter build apk --debug        # Android smoke build
```
