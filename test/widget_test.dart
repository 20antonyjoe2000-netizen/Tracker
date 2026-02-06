import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/main.dart';

void main() {
  testWidgets('Year tracker app displays days remaining', (WidgetTester tester) async {
    await tester.pumpWidget(const YearTrackerApp());

    // Verify that 'Days remaining' label is present
    expect(find.text('Days remaining'), findsOneWidget);
    expect(find.text('every day, one less'), findsOneWidget);
  });
}
