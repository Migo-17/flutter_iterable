import 'package:flutter_test/flutter_test.dart';
import 'package:iterable_sdk/iterable_sdk.dart';

void main() {
  group('IterableCommerceItem', () {
    test('round-trips through a map', () {
      final item = IterableCommerceItem(
        id: 'sku-1',
        name: 'Coffee',
        price: 4.5,
        quantity: 2,
        categories: <String>['drinks'],
      );

      final IterableCommerceItem decoded =
          IterableCommerceItem.fromMap(item.toMap());

      expect(decoded.id, 'sku-1');
      expect(decoded.name, 'Coffee');
      expect(decoded.price, 4.5);
      expect(decoded.quantity, 2);
      expect(decoded.categories, <String>['drinks']);
    });
  });

  group('IterableInAppMessage', () {
    test('parses from a native map', () {
      final message = IterableInAppMessage.fromMap(<String, dynamic>{
        'messageId': 'm1',
        'campaignId': 99,
        'saveToInbox': true,
        'read': false,
        'createdAt': 1700000000000,
        'customPayload': <String, dynamic>{'foo': 'bar'},
      });

      expect(message.messageId, 'm1');
      expect(message.campaignId, 99);
      expect(message.saveToInbox, isTrue);
      expect(message.customPayload?['foo'], 'bar');
      expect(message.createdAt, isNotNull);
    });
  });

  group('IterableConfig', () {
    test('serializes handler flags', () {
      final config = IterableConfig(
        pushIntegrationName: 'com.example.app',
        logLevel: IterableLogLevel.debug,
        urlHandler: (_, _) => true,
      );

      final Map<String, dynamic> map = config.toMap();

      expect(map['pushIntegrationName'], 'com.example.app');
      expect(map['logLevel'], IterableLogLevel.debug.value);
      expect(map['hasUrlHandler'], isTrue);
      expect(map['hasAuthHandler'], isFalse);
    });
  });

  group('IterableEmbeddedMessage', () {
    test('parses metadata and elements', () {
      final message = IterableEmbeddedMessage.fromMap(<String, dynamic>{
        'metadata': <String, dynamic>{
          'messageId': 'e1',
          'campaignId': 7,
          'placementId': 1,
          'isProof': false,
        },
        'elements': <String, dynamic>{
          'title': 'Hello',
          'body': 'World',
          'buttons': <dynamic>[
            <String, dynamic>{'id': 'b1', 'title': 'Tap'}
          ],
        },
      });

      expect(message.metadata.messageId, 'e1');
      expect(message.metadata.campaignId, 7);
      expect(message.elements?.title, 'Hello');
      expect(message.elements?.buttons?.first.id, 'b1');
    });
  });
}
