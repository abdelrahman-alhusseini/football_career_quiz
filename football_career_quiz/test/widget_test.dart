import 'package:flutter_test/flutter_test.dart';
import 'package:football_career_quiz/main.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FootballCareerQuizApp());

    expect(find.text('Career Guess'), findsWidgets);
  });
}
