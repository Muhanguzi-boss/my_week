import '../models/course.dart';

const List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

const Map<String, String> fullDayNames = {
  'Mon': 'Monday',
  'Tue': 'Tuesday',
  'Wed': 'Wednesday',
  'Thu': 'Thursday',
  'Fri': 'Friday',
};

/// Turns '08:30' into 510 minutes. Returns null if the text is not HH:MM
/// or the time does not exist (25:00, 10:75, '8h' ...).
int? parseTime(String text) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
  if (match == null) return null;
  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  if (hours > 23 || minutes > 59) return null;
  return hours * 60 + minutes;
}

/// Turns 510 back into '08:30'.
String formatTime(int totalMinutes) {
  final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
  final m = (totalMinutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// 210 -> '3h 30m', 120 -> '2h', 45 -> '45m', 0 -> '0m'.
String formatDuration(int totalMinutes) {
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Two courses clash when they are on the same day and each one starts
/// before the other one ends. Strict `<` means 10:00-11:00 and 11:00-12:00
/// do NOT clash: they only touch.
bool coursesOverlap(Course a, Course b) {
  return a.day == b.day && a.startMin < b.endMin && b.startMin < a.endMin;
}

/// Every other course that clashes with [course]. The course itself is
/// skipped (matched by id), so editing a course never clashes with itself.
List<Course> clashesOf(Course course, List<Course> all) {
  return all
      .where((other) => other.id != course.id && coursesOverlap(course, other))
      .toList();
}

/// Courses of one day, earliest start first (a copy; [all] is not changed).
List<Course> coursesOnDay(String day, List<Course> all) {
  final list = all.where((c) => c.day == day).toList();
  list.sort((a, b) {
    final byStart = a.startMin.compareTo(b.startMin);
    return byStart != 0 ? byStart : a.name.compareTo(b.name);
  });
  return list;
}

int totalMinutes(List<Course> courses) {
  var sum = 0;
  for (final c in courses) {
    sum += c.duration;
  }
  return sum;
}

/// Checks the add / edit form. Returns an error message, or null if the
/// input is fine.
String? validateCourseInput({
  required String name,
  required String startText,
  required String endText,
}) {
  if (name.trim().isEmpty) return 'Please enter the course name.';
  final start = parseTime(startText);
  if (start == null) return 'Start time must look like 08:00 (00:00 to 23:59).';
  final end = parseTime(endText);
  if (end == null) return 'End time must look like 10:00 (00:00 to 23:59).';
  if (end <= start) return 'End time must be after the start time.';
  return null;
}

/// Sample week: three+ days, with one clash (Mathematics / Physics on Monday).
/// Wednesday is left empty on purpose.
List<Course> sampleCourses() {
  Course c(String name, String day, String start, String end) => Course(
        id: '',
        name: name,
        day: day,
        startMin: parseTime(start)!,
        endMin: parseTime(end)!,
      );
  return [
    c('Mathematics', 'Mon', '08:00', '10:00'),
    c('Physics', 'Mon', '09:30', '11:00'),
    c('Programming', 'Tue', '10:00', '12:00'),
    c('English', 'Thu', '08:00', '09:30'),
    c('Programming Lab', 'Thu', '09:30', '11:30'),
    c('Networks', 'Fri', '13:00', '15:00'),
  ];
}
