import 'package:cloud_firestore/cloud_firestore.dart';

/// One class in the week. Times are stored as minutes after midnight
/// (08:30 -> 510) so they are easy to compare and add up.
class Course {
  const Course({
    required this.id,
    required this.name,
    required this.day,
    required this.startMin,
    required this.endMin,
  });

  final String id; // Firestore document id ('' for a course not saved yet)
  final String name;
  final String day; // 'Mon' .. 'Fri'
  final int startMin;
  final int endMin;

  int get duration => endMin - startMin;

  Course copyWith({String? name, String? day, int? startMin, int? endMin}) {
    return Course(
      id: id,
      name: name ?? this.name,
      day: day ?? this.day,
      startMin: startMin ?? this.startMin,
      endMin: endMin ?? this.endMin,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'day': day,
        'startMin': startMin,
        'endMin': endMin,
      };

  factory Course.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Course(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      day: (data['day'] ?? 'Mon') as String,
      startMin: (data['startMin'] ?? 0) as int,
      endMin: (data['endMin'] ?? 0) as int,
    );
  }
}
