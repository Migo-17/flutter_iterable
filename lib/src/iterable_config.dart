import 'enums/iterable_log_level.dart';
import 'enums/iterable_in_app_show_response.dart';
import 'models/iterable_action.dart';
import 'models/iterable_action_context.dart';
import 'models/iterable_auth_request.dart';
import 'models/iterable_in_app_message.dart';

/// Synchronous URL handler. Return `true` if your app handled the URL itself
/// and Iterable should not open it.
typedef IterableUrlHandler = bool Function(
  String url,
  IterableActionContext context,
);

/// Synchronous custom action handler. Return `true` if handled.
typedef IterableCustomActionHandler = bool Function(
  IterableAction action,
  IterableActionContext context,
);

/// Asynchronous JWT provider. Return the signed token, or `null` to fail auth.
typedef IterableAuthHandler = Future<String?> Function(
  IterableAuthRequest request,
);

/// Called when a new in-app message arrives. Return whether to show it now.
typedef IterableInAppHandler = IterableInAppShowResponse Function(
  IterableInAppMessage message,
);

/// Configuration passed to [IterableAPI.initialize].
class IterableConfig {
  IterableConfig({
    this.pushIntegrationName,
    this.autoPushRegistration = true,
    this.inAppDisplayInterval = 30.0,
    this.logLevel = IterableLogLevel.info,
    this.allowedProtocols = const <String>[],
    this.useInMemoryStorageForInApps = false,
    this.expiringAuthTokenRefreshPeriod = 60.0,
    this.authRetryMaxRetries = 1,
    this.authRetryIntervalSeconds = 3.0,
    this.dataRegion = IterableDataRegion.us,
    this.enableEmbeddedMessaging = false,
    this.urlHandler,
    this.customActionHandler,
    this.authHandler,
    this.inAppHandler,
  });

  /// Name of the push integration configured in Iterable.
  final String? pushIntegrationName;

  /// Whether the SDK automatically registers the device for push when a user
  /// is set. Defaults to `true`.
  final bool autoPushRegistration;

  /// Minimum gap (seconds) between automatically displayed in-app messages.
  final double inAppDisplayInterval;

  /// Native log verbosity.
  final IterableLogLevel logLevel;

  /// URL schemes the SDK is allowed to open.
  final List<String> allowedProtocols;

  /// Keep in-app messages in memory only (do not persist to disk).
  final bool useInMemoryStorageForInApps;

  /// How long before a JWT expires the SDK should request a fresh one.
  final double expiringAuthTokenRefreshPeriod;

  /// Number of times to retry a failed auth token request.
  final int authRetryMaxRetries;

  /// Base interval (seconds) between auth token retries.
  final double authRetryIntervalSeconds;

  /// Data residency region for the project.
  final IterableDataRegion dataRegion;

  /// Enables embedded messaging on the native SDKs.
  final bool enableEmbeddedMessaging;

  final IterableUrlHandler? urlHandler;
  final IterableCustomActionHandler? customActionHandler;
  final IterableAuthHandler? authHandler;
  final IterableInAppHandler? inAppHandler;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pushIntegrationName': pushIntegrationName,
      'autoPushRegistration': autoPushRegistration,
      'inAppDisplayInterval': inAppDisplayInterval,
      'logLevel': logLevel.value,
      'allowedProtocols': allowedProtocols,
      'useInMemoryStorageForInApps': useInMemoryStorageForInApps,
      'expiringAuthTokenRefreshPeriod': expiringAuthTokenRefreshPeriod,
      'authRetryMaxRetries': authRetryMaxRetries,
      'authRetryIntervalSeconds': authRetryIntervalSeconds,
      'dataRegion': dataRegion.value,
      'enableEmbeddedMessaging': enableEmbeddedMessaging,
      // Flags so the native side knows which delegates to wire up.
      'hasUrlHandler': urlHandler != null,
      'hasCustomActionHandler': customActionHandler != null,
      'hasAuthHandler': authHandler != null,
      'hasInAppHandler': inAppHandler != null,
    };
  }
}

/// Data residency region for the Iterable project.
enum IterableDataRegion {
  us('US'),
  eu('EU');

  const IterableDataRegion(this.value);

  final String value;
}
