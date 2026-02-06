import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/counter_app.dart';

void main() {
  testWidgets('Counter initial value is 0', (WidgetTester tester) async {
    await tester.pumpWidget(const CounterApp());
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Counter increments when + button is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(const CounterApp());

    // Click increment button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify value changed to 1
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Counter decrements when - button is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(const CounterApp());

    // Click decrement button
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    // Verify value changed to -1
    expect(find.text('-1'), findsOneWidget);
  });
}
