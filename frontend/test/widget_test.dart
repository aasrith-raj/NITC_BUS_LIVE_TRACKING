import 'package:flutter_test/flutter_test.dart';

import 'package:nitc_bus_tracking/app.dart';

void main() {
  testWidgets('NITC Bus Tracking app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const NitcBusApp());

    expect(find.byType(NitcBusApp), findsOneWidget);
  });
}
