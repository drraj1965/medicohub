import 'package:flutter_test/flutter_test.dart';

import 'package:medicohub/app.dart';

void main() {
  testWidgets('MedicoHub renders consent gate', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicoHubApp());

    expect(find.text('MedicoHub'), findsOneWidget);
    expect(find.text('Consent Required'), findsOneWidget);
  });
}
