import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_week/models/course.dart';
import 'package:my_week/services/course_repository.dart';

/// A signed-in user without Firebase. Only uid and email are used by the app.
class FakeUser implements User {
  FakeUser({required this.uid, required this.email});

  @override
  final String uid;

  @override
  final String? email;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Keeps courses in memory instead of Firestore, but still streams every
/// change like the real repository does.
class FakeCourseRepository extends CourseRepository {
  FakeCourseRepository([List<Course> start = const []]) : super('fake-uid') {
    for (final course in start) {
      _save(course);
    }
  }

  final List<Course> _items = [];
  final _changes = StreamController<List<Course>>.broadcast();
  var _nextId = 1;

  List<Course> get items => List.unmodifiable(_items);

  void _save(Course course) {
    final id = course.id.isEmpty ? 'c${_nextId++}' : course.id;
    _items.add(Course(
      id: id,
      name: course.name,
      day: course.day,
      startMin: course.startMin,
      endMin: course.endMin,
    ));
  }

  void _emit() => _changes.add(List.of(_items));

  @override
  Stream<List<Course>> watch() async* {
    yield List.of(_items);
    yield* _changes.stream;
  }

  @override
  Future<void> add(Course course) async {
    _save(course);
    _emit();
  }

  @override
  Future<void> update(Course course) async {
    _items[_items.indexWhere((c) => c.id == course.id)] = course;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((c) => c.id == id);
    _emit();
  }

  @override
  Future<void> restore(Course course) => add(course);

  @override
  Future<void> addAll(List<Course> courses) async {
    courses.forEach(_save);
    _emit();
  }
}
