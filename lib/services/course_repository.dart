import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course.dart';

/// All Firestore access lives here. Data path: users/{uid}/courses/{courseId}
/// so every signed-in user only ever touches their own courses.
class CourseRepository {
  CourseRepository(this.uid);

  final String uid;

  CollectionReference<Map<String, dynamic>> get _courses => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('courses');

  /// Live list: emits again every time anything changes in Firestore.
  Stream<List<Course>> watch() {
    return _courses
        .snapshots()
        .map((snap) => snap.docs.map(Course.fromDoc).toList());
  }

  Future<void> add(Course course) => _courses.add(course.toMap());

  Future<void> update(Course course) =>
      _courses.doc(course.id).update(course.toMap());

  Future<void> delete(String id) => _courses.doc(id).delete();

  /// Puts a deleted course back with its old id (used by Undo).
  Future<void> restore(Course course) =>
      _courses.doc(course.id).set(course.toMap());

  Future<void> addAll(List<Course> courses) {
    final batch = FirebaseFirestore.instance.batch();
    for (final course in courses) {
      batch.set(_courses.doc(), course.toMap());
    }
    return batch.commit();
  }
}
