# iterable_sdk

A Flutter plugin that wraps Iterable's official native
[Android](https://github.com/Iterable/iterable-android-sdk) and
[iOS](https://github.com/Iterable/iterable-swift-sdk) SDKs.

It exposes a single, idiomatic Dart API for user identity, event &
commerce tracking, push notifications, in-app messages, embedded messages,
deep-link / custom-action handling and JWT (token-based) authentication.

| Area | Android SDK | iOS SDK |
|------|-------------|---------|
| Native dependency | `com.iterable:iterableapi:3.10.1` | `iterable-swift-sdk` from `6.7.5` |
| Dependency manager | Gradle | Swift Package Manager (no CocoaPods) |
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
      ref: v0.1.0
```

Pin `ref` to a release tag (e.g. `v0.1.0`). Tags match `pubspec.yaml` `version` with a `v` prefix.

### iOS setup

**This plugin is Swift Package Manager only — it ships no podspec.** Flutter
resolves `iterable-swift-sdk` through SPM automatically; there is nothing to add
to a `Podfile`.

Swift Package Manager is on by default from Flutter 3.44. On an older Flutter,
or in a project where it was turned off, enable it once:

```bash
flutter config --enable-swift-package-manager
```

Your app's Xcode project needs Xcode 15+, and Flutter migrates it to Swift
Package Manager on the next `flutter build ios` / `flutter run`. If the build
stops with *"The following plugin(s) are only compatible with Swift Package
Manager"*, that is this step — run the command above and build again.

If your app still uses CocoaPods for other plugins, that keeps working: the two
coexist, and Iterable simply arrives through SPM instead.

Set your deployment target to iOS 13 or later.

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

// Returns false if the native SDK did not come up (e.g. an empty API key).
await IterableAPI.initialize('YOUR_MOBILE_API_KEY', config);

// Ask the native SDK whether it is initialized, at any point later on.
await IterableAPI.isInitialized();

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

### Push tap actions (open URL / custom action)

When a user taps a push notification, the plugin forwards the action to your
`urlHandler` and `customActionHandler` callbacks in `IterableConfig`:

- **iOS**: notification taps are forwarded through `IterableAppIntegration`. This
  requires the app's `UNUserNotificationCenter` delegate to be the
  `FlutterAppDelegate` (the default if no other plugin claims it, e.g.
  `firebase_messaging`); otherwise set it yourself in `AppDelegate`.
- **Android**: pending push actions are processed when the SDK initializes and when
  the Flutter activity receives the Iterable intent (`onNewIntent` is handled by the plugin).

These handlers run on the platform's main thread, where the plugin cannot block
waiting for an async Dart answer. So if you register a `urlHandler` /
`customActionHandler`, the action is forwarded to Dart and the native SDK is told
the **app handled it** — it will not open the URL in a browser. Perform any
navigation inside your Dart handler. If you do not register a handler, the native
SDK handles the URL itself (opens it). The handler's return value is reserved for
future use and is currently not round-tripped to the native SDK.

`IterableAPI.onPushOpened` also emits the push payload when an action is processed.

When a push tap launches the app from a terminated state, the native SDK reports the
open before app code has had a chance to subscribe. `onPushOpened` buffers those
payloads and replays them to the first subscriber, so listening during startup is
enough — there is no need to race the native callback. `IterableAPI.getLastPushPayload()`
returns the same payload on demand.

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

## Development

```bash
flutter analyze
flutter test
cd example && flutter build ios --simulator   # iOS smoke build (SPM)
cd example && flutter build apk --debug        # Android smoke build
```

The example app carries no CocoaPods integration. Its Xcode project gains the
Swift Package Manager integration the first time `flutter build ios` /
`flutter run` is executed on macOS — Flutter writes the package reference into
`example/ios/Runner.xcodeproj/project.pbxproj`. That is a one-off generated
diff; commit it.
