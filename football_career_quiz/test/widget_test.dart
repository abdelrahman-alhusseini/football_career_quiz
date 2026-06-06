import 'package:flutter_test/flutter_test.dart';
import 'package:football_career_quiz/main.dart';

void main() {
  testWidgets('Football Career Quiz app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const FootballCareerQuizApp());

    expect(find.text('Football Career Quiz'), findsWidgets);
    expect(find.text('Solo Mode'), findsOneWidget);
  });
}
