// Basic Flutter integration test for the Iterable SDK example.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:iterable_sdk/iterable_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialize returns a result', (WidgetTester tester) async {
    final bool result = await IterableAPI.initialize(
      'test-api-key',
      IterableConfig(),
    );
    expect(result, isA<bool>());
  });
}
