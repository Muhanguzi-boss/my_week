import 'package:flutter/material.dart';

import '../logic/week_rules.dart';
import '../models/course.dart';
import '../services/course_repository.dart';

/// Add a course (course == null) or edit an existing one.
class CourseScreen extends StatefulWidget {
  const CourseScreen({
    super.key,
    required this.repo,
    required this.initialDay,
    this.course,
  });

  final CourseRepository repo;
  final String initialDay;
  final Course? course;

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final nameController = TextEditingController();
  final startController = TextEditingController();
  final endController = TextEditingController();
  late String day;
  bool saving = false;

  bool get editing => widget.course != null;

  @override
  void initState() {
    super.initState();
    day = widget.initialDay;
    final course = widget.course;
    if (course != null) {
      nameController.text = course.name;
      startController.text = formatTime(course.startMin);
      endController.text = formatTime(course.endMin);
      day = course.day;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final error = validateCourseInput(
      name: nameController.text,
      startText: startController.text,
      endText: endController.text,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return; // refused: nothing changes
    }

    final old = widget.course;
    final course = Course(
      id: old?.id ?? '',
      name: nameController.text.trim(),
      day: day,
      startMin: parseTime(startController.text)!,
      endMin: parseTime(endController.text)!,
    );

    setState(() {
      saving = true;
    });
    try {
      if (editing) {
        await widget.repo.update(course);
      } else {
        await widget.repo.add(course);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Check your connection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit course' : 'Add course')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Course name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Day'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final d in weekDays)
                ChoiceChip(
                  label: Text(d),
                  selected: day == d,
                  onSelected: (_) {
                    setState(() {
                      day = d;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: startController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Start (HH:MM)',
                    hintText: '08:00',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: endController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'End (HH:MM)',
                    hintText: '10:00',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: const Icon(Icons.check),
            label: Text(editing ? 'Save changes' : 'Add course'),
          ),
        ],
      ),
    );
  }
}
