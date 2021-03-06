import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_nearby/pages/settings.dart';
import 'package:spotify_nearby/pages/home.dart';

void main() {

  testWidgets('tapping settings should redirect to settings page', (WidgetTester tester) async {
    await tester.pumpWidget( MaterialApp(home: Home()));

    expect(find.byIcon(Icons.settings), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byType(Settings), findsOneWidget);
  });
  
}
