import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_week/logic/week_rules.dart';
import 'package:my_week/screens/course_screen.dart';
import 'package:my_week/screens/login_screen.dart';
import 'package:my_week/screens/week_screen.dart';

import 'fakes.dart';

Widget app(Widget home) => MaterialApp(home: home);

Widget week(FakeCourseRepository repo) => app(WeekScreen(
      user: FakeUser(uid: 'u1', email: 'student@example.com'),
      repo: repo,
    ));

void main() {
  testWidgets('login refuses an email without @', (tester) async {
    await tester.pumpWidget(app(const LoginScreen()));
    expect(find.text('My Week'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'not-an-email');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Please enter a valid email address.'), findsOneWidget);
  });

  testWidgets('empty week offers the sample week, which shows the clash',
      (tester) async {
    final repo = FakeCourseRepository();
    await tester.pumpWidget(week(repo));
    await tester.pumpAndSettle();
    expect(find.text('No classes on Monday'), findsOneWidget);

    await tester.tap(find.text('Load a sample week'));
    await tester.pumpAndSettle();
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.textContaining('Clashes with Physics'), findsOneWidget);
    expect(find.text('This week: 11h'), findsOneWidget);
  });

  testWidgets('an empty day says so', (tester) async {
    await tester.pumpWidget(week(FakeCourseRepository(sampleCourses())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wed (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No classes on Wednesday'), findsOneWidget);
  });

  testWidgets('add course refuses 25:00 and saves nothing', (tester) async {
    final repo = FakeCourseRepository();
    await tester.pumpWidget(app(CourseScreen(repo: repo, initialDay: 'Mon')));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Biology');
    await tester.enterText(fields.at(1), '25:00');
    await tester.enterText(fields.at(2), '26:00');
    await tester.tap(find.widgetWithText(FilledButton, 'Add course'));
    await tester.pump();

    expect(find.textContaining('Start time must look like'), findsOneWidget);
    expect(repo.items, isEmpty);
  });
}
