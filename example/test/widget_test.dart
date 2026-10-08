import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_msal_plus_example/main.dart';

void main() {
  testWidgets('authentication is disabled until MSAL is initialized', (
    tester,
  ) async {
    await tester.pumpWidget(const MsalExampleApp());
    expect(find.text('MSAL authentication'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sign in'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Acquire silently'),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.text('Configure CLIENT_ID before initializing.'),
      findsOneWidget,
    );
  });
}
