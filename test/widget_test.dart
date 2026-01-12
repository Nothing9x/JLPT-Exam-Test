import 'package:flutter_test/flutter_test.dart';

import 'package:jlptexamtest/main.dart';

void main() {
  testWidgets('Language selection screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const JLPTExamTestApp());

    expect(find.text('Choose display language'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
