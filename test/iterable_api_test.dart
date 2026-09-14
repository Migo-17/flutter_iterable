import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iterable_sdk/iterable_sdk.dart';

const MethodChannel _channel = MethodChannel('iterable_sdk/method');
const StandardMethodCodec _codec = StandardMethodCodec();

/// Delivers a native -> Dart call the way the plugin does at runtime.
Future<void> _emitFromNative(String method, Object? arguments) {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    _channel.name,
    _codec.encodeMethodCall(MethodCall(method, arguments)),
    (ByteData? _) {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> calls = <MethodCall>[];
  bool nativeInitialized = false;

  setUp(() {
    calls.clear();
    nativeInitialized = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          nativeInitialized = true;
          return true;
        case 'isInitialized':
          return nativeInitialized;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('initialization', () {
    test('isInitialized is false until the native SDK is initialized',
        () async {
      expect(await IterableAPI.isInitialized(), isFalse);

      expect(await IterableAPI.initialize('api-key', IterableConfig()), isTrue);

      expect(await IterableAPI.isInitialized(), isTrue);
    });

    test('initialize forwards the plugin version to the native SDK', () async {
      await IterableAPI.initialize('api-key', IterableConfig());

      final MethodCall call =
          calls.firstWhere((MethodCall c) => c.method == 'initialize');
      expect(
        (call.arguments as Map)['version'],
        IterableAPI.version,
      );
    });

    test('an empty API key is refused without reaching the native SDK',
        () async {
      expect(await IterableAPI.initialize('', IterableConfig()), isFalse);

      expect(calls, isEmpty);
      expect(await IterableAPI.isInitialized(), isFalse);
    });

    test('initialize reports false when the native SDK does not come up',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        return call.method == 'initialize' ? false : null;
      });

      expect(await IterableAPI.initialize('api-key', IterableConfig()), isFalse);
      expect(await IterableAPI.isInitialized(), isFalse);
    });
  });

  group('onPushOpened', () {
    test('replays a push that arrived before anything was listening', () async {
      await IterableAPI.initialize('api-key', IterableConfig());

      // A push that launches the app from a terminated state is delivered while
      // Flutter is still starting up, before app code subscribes.
      await _emitFromNative('handlePushOpened', <String, dynamic>{
        'itbl': 'cold-start-payload',
      });

      final Map<String, dynamic> payload =
          await IterableAPI.onPushOpened.first.timeout(
        const Duration(seconds: 5),
      );
      expect(payload['itbl'], 'cold-start-payload');
    });

    test('delivers to an existing listener without buffering', () async {
      await IterableAPI.initialize('api-key', IterableConfig());

      final List<Map<String, dynamic>> received = <Map<String, dynamic>>[];
      final StreamSubscription<Map<String, dynamic>> sub =
          IterableAPI.onPushOpened.listen(received.add);
      addTearDown(sub.cancel);

      await _emitFromNative('handlePushOpened', <String, dynamic>{
        'itbl': 'warm-payload',
      });
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single['itbl'], 'warm-payload');
    });
  });
}
