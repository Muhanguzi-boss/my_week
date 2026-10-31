import 'package:flutter_test/flutter_test.dart';
import 'package:my_week/logic/week_rules.dart';
import 'package:my_week/models/course.dart';

Course c(String id, String day, String start, String end) => Course(
      id: id,
      name: id,
      day: day,
      startMin: parseTime(start)!,
      endMin: parseTime(end)!,
    );

void main() {
  test('parseTime accepts good times and refuses bad ones', () {
    expect(parseTime('08:30'), 510);
    expect(parseTime(' 8:05 '), 485);
    expect(parseTime('8h'), isNull);
    expect(parseTime('25:00'), isNull);
    expect(parseTime('10:75'), isNull);
    expect(parseTime(''), isNull);
  });

  test('formatTime and formatDuration', () {
    expect(formatTime(510), '08:30');
    expect(formatDuration(210), '3h 30m');
    expect(formatDuration(120), '2h');
    expect(formatDuration(45), '45m');
  });

  test('touching courses do not clash, overlapping ones do', () {
    final a = c('a', 'Mon', '08:00', '10:00');
    final b = c('b', 'Mon', '10:00', '11:30');
    final d = c('d', 'Mon', '09:30', '11:00');
    expect(coursesOverlap(a, b), isFalse);
    expect(coursesOverlap(a, d), isTrue);
    expect(coursesOverlap(c('x', 'Tue', '08:00', '10:00'), a), isFalse);
    expect(totalMinutes([a, b]), 210);
  });

  test('clashesOf skips the course itself and names the others', () {
    final a = c('a', 'Mon', '08:00', '10:00');
    final d = c('d', 'Mon', '09:30', '11:00');
    expect(clashesOf(a, [a, d]).map((x) => x.id), ['d']);
    expect(clashesOf(a, [a]), isEmpty);
  });

  test('coursesOnDay sorts by start time', () {
    final afternoon = c('late', 'Mon', '14:00', '15:00');
    final early = c('early', 'Mon', '06:00', '07:00');
    expect(coursesOnDay('Mon', [afternoon, early]).map((x) => x.id), ['early', 'late']);
  });

  test('validateCourseInput refuses bad input', () {
    expect(validateCourseInput(name: '', startText: '08:00', endText: '09:00'), isNotNull);
    expect(validateCourseInput(name: 'A', startText: '8h', endText: '09:00'), isNotNull);
    expect(validateCourseInput(name: 'A', startText: '09:00', endText: '09:00'), isNotNull);
    expect(validateCourseInput(name: 'A', startText: '08:00', endText: '09:00'), isNull);
  });
}
