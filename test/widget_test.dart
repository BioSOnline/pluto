// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pluto/main.dart';
import 'package:pluto/pluto_providers.dart';

void main() {
  testWidgets('Pluto app renders home shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [plutoIsTestProvider.overrideWithValue(true)],
        child: const PlutoApp(),
      ),
    );

    expect(find.text('Pluto'), findsOneWidget);
    expect(find.text('No voice notes yet'), findsOneWidget);
  });
}
