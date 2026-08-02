import 'package:flutter_test/flutter_test.dart';
import 'package:msal_flutter_example/main.dart';

void main() {
  testWidgets('renders the example app controls', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    expect(find.text('Plugin example app'), findsOneWidget);
    expect(find.text('AcquireToken()'), findsOneWidget);
    expect(find.text('loadAccount()'), findsOneWidget);
    expect(find.text('AcquireTokenSilently()'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });
}
