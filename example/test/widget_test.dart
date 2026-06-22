import 'package:flutter_test/flutter_test.dart';

import 'package:iterable_sdk_example/main.dart';

void main() {
  testWidgets('renders the example scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Iterable SDK example'), findsOneWidget);
    expect(find.text('Set email'), findsOneWidget);
  });
}
