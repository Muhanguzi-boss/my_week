import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../logic/week_rules.dart';
import '../models/course.dart';
import '../services/course_repository.dart';
import 'course_screen.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key, required this.user, this.repo});

  final User user;

  /// Leave null in the app. Tests pass their own (fake) repository.
  final CourseRepository? repo;

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  late final CourseRepository repo =
      widget.repo ?? CourseRepository(widget.user.uid);
  late final Stream<List<Course>> courseStream = repo.watch();
  String selectedDay = 'Mon';

  void openCourse({Course? course}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseScreen(
          repo: repo,
          initialDay: selectedDay,
          course: course,
        ),
      ),
    );
    // No .then needed: the Firestore stream redraws this screen by itself.
  }

  void confirmDelete(Course course) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete this course?'),
          content: Text(
            '${course.name} (${course.day} ${formatTime(course.startMin)}'
            '-${formatTime(course.endMin)})',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteCourse(course);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteCourse(Course course) async {
    try {
      await repo.delete(course.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${course.name} deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => repo.restore(course),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete. Check your connection.')),
      );
    }
  }

  Future<void> loadSample() async {
    await repo.addAll(sampleCourses());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Course>>(
      stream: courseStream,
      builder: (context, snapshot) {
        final all = snapshot.data ?? <Course>[];
        final dayCourses = coursesOnDay(selectedDay, all);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Week'),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => openCourse(),
            icon: const Icon(Icons.add),
            label: const Text('Add course'),
          ),
          body: Column(
            children: [
              weekHeader(all),
              dayChips(all),
              const SizedBox(height: 4),
              Expanded(child: body(snapshot, all, dayCourses)),
            ],
          ),
        );
      },
    );
  }

  Widget weekHeader(List<Course> all) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: colors.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This week: ${formatDuration(totalMinutes(all))}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                Text(
                  widget.user.email ?? 'Signed in',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget dayChips(List<Course> all) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          for (final d in weekDays)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$d (${coursesOnDay(d, all).length})'),
                selected: selectedDay == d,
                onSelected: (_) {
                  setState(() {
                    selectedDay = d;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget body(
    AsyncSnapshot<List<Course>> snapshot,
    List<Course> all,
    List<Course> dayCourses,
  ) {
    if (snapshot.hasError) {
      return const Center(child: Text('Could not load your courses.'));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    final dayName = fullDayNames[selectedDay]!;

    if (dayCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No classes on $dayName', style: const TextStyle(fontSize: 18)),
            if (all.isEmpty) ...[
              const SizedBox(height: 12),
              const Text('Your week is empty.'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: loadSample,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Load a sample week'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$dayName: ${formatDuration(totalMinutes(dayCourses))}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: dayCourses.length,
            itemBuilder: (context, index) {
              final course = dayCourses[index];
              final clashes = clashesOf(course, all);
              return courseCard(course, clashes);
            },
          ),
        ),
      ],
    );
  }

  Widget courseCard(Course course, List<Course> clashes) {
    final clashing = clashes.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: clashing ? Colors.red.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: clashing ? Colors.red : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () => openCourse(course: course),
        leading: Icon(
          clashing ? Icons.warning_amber_rounded : Icons.menu_book_outlined,
          color: clashing ? Colors.red : null,
        ),
        title: Text(
          course.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: clashing ? Colors.red.shade900 : null,
          ),
        ),
        subtitle: Text(
          '${formatTime(course.startMin)} - ${formatTime(course.endMin)}'
          '  (${formatDuration(course.duration)})'
          '${clashing ? '\nClashes with ${clashes.map((c) => c.name).join(', ')}' : ''}',
          style: TextStyle(color: clashing ? Colors.red.shade900 : null),
        ),
        isThreeLine: clashing,
        trailing: IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => confirmDelete(course),
        ),
      ),
    );
  }
}
