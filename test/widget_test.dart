import 'package:aura/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows provided home widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Aura(
        home: Scaffold(body: Center(child: Text('Test Home'))),
      ),
    );

    expect(find.text('Test Home'), findsOneWidget);
  });
}
