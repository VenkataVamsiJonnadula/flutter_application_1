import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Dashboard loads correctly test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DashboardApp());
    await tester.pumpAndSettle();

    // Verify that our title is seen.
    expect(find.text('Jewellery Dashboard'), findsWidgets);
  });
}
