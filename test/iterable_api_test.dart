import 'dart:async';
import 'dart:io';

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

  test('IterableAPI.version matches the pubspec version', () {
    // The two are separate declarations by necessity (Dart cannot read the
    // pubspec at runtime), and Iterable is told this value — so pin them here
    // rather than let them drift.
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? match =
        RegExp(r'^version:\s*(\S+)$', multiLine: true).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'no version: line in pubspec.yaml');
    expect(IterableAPI.version, match!.group(1));
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

    test('keeps only the most recent pushes when nothing listens', () async {
      await IterableAPI.initialize('api-key', IterableConfig());

      // One more than the buffer holds; the oldest is expected to fall off.
      for (var i = 0; i < 6; i++) {
        await _emitFromNative('handlePushOpened', <String, dynamic>{
          'itbl': 'payload-$i',
        });
      }

      final List<Map<String, dynamic>> received = <Map<String, dynamic>>[];
      final StreamSubscription<Map<String, dynamic>> sub =
          IterableAPI.onPushOpened.listen(received.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);

      expect(
        received.map((Map<String, dynamic> e) => e['itbl']),
        <String>['payload-1', 'payload-2', 'payload-3', 'payload-4',
            'payload-5'],
      );
    });

    test('replays a buffered push once, not to every later subscriber',
        () async {
      await IterableAPI.initialize('api-key', IterableConfig());

      await _emitFromNative('handlePushOpened', <String, dynamic>{
        'itbl': 'once-only',
      });

      final List<Map<String, dynamic>> first = <Map<String, dynamic>>[];
      final StreamSubscription<Map<String, dynamic>> firstSub =
          IterableAPI.onPushOpened.listen(first.add);
      await Future<void>.delayed(Duration.zero);
      await firstSub.cancel();

      final List<Map<String, dynamic>> second = <Map<String, dynamic>>[];
      final StreamSubscription<Map<String, dynamic>> secondSub =
          IterableAPI.onPushOpened.listen(second.add);
      addTearDown(secondSub.cancel);
      await Future<void>.delayed(Duration.zero);

      expect(first.single['itbl'], 'once-only');
      expect(second, isEmpty);
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
