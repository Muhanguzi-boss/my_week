// Renders the real app screens (with fake data, no Firebase needed) into
// screenshots/*.png. Run from the project folder:
//
//   flutter test tool/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_week/logic/week_rules.dart';
import 'package:my_week/main.dart' show appTheme;
import 'package:my_week/screens/course_screen.dart';
import 'package:my_week/screens/login_screen.dart';
import 'package:my_week/screens/week_screen.dart';

import '../test/fakes.dart';

final boundaryKey = GlobalKey();

/// The test runner draws text as boxes unless real fonts are loaded.
Future<void> loadFonts() async {
  final fonts = '${Platform.environment['FLUTTER_ROOT']}'
      '/bin/cache/artifacts/material_fonts';
  Future<ByteData> file(String name) async =>
      ByteData.sublistView(await File('$fonts/$name').readAsBytes());

  final roboto = FontLoader('Roboto');
  for (final w in ['regular', 'medium', 'bold', 'black']) {
    roboto.addFont(file('roboto-$w.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')
        ..addFont(file('materialicons-regular.otf')))
      .load();
}

/// Same theme as the app, so the shots look like the real thing.
Widget themed(Widget home) {
  return RepaintBoundary(
    key: boundaryKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: home,
    ),
  );
}

Future<void> save(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    debugDisableShadows = true; // the test runner checks this at the end
    File('screenshots/$name').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(loadFonts);

  setUp(() {
    // Tests draw shadows as thick black outlines unless this is turned off.
    debugDisableShadows = false;
    // A typical phone: 360 x 780 logical pixels.
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 3;
  });

  testWidgets('login.png', (tester) async {
    await tester.pumpWidget(themed(const LoginScreen()));
    await tester.enterText(find.byType(TextField).at(0), 'student@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    FocusManager.instance.primaryFocus?.unfocus();
    await save(tester, 'login.png');
  });

  testWidgets('live.png', (tester) async {
    await tester.pumpWidget(themed(WeekScreen(
      user: FakeUser(uid: 'u1', email: 'student@example.com'),
      repo: FakeCourseRepository(sampleCourses()),
    )));
    await save(tester, 'live.png');
  });

  testWidgets('denied.png', (tester) async {
    await tester.pumpWidget(themed(WeekScreen(
      user: FakeUser(uid: 'u2', email: 'second@example.com'),
      repo: FakeCourseRepository(),
    )));
    await save(tester, 'denied.png');
  });

  testWidgets('add_course.png', (tester) async {
    await tester.pumpWidget(themed(
      CourseScreen(repo: FakeCourseRepository(), initialDay: 'Tue'),
    ));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Biology');
    await tester.enterText(fields.at(1), '25:00');
    await tester.enterText(fields.at(2), '26:00');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.widgetWithText(FilledButton, 'Add course'));
    await tester.pump();
    await save(tester, 'add_course.png');
  });
}

