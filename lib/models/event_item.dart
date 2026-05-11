import 'package:cloud_firestore/cloud_firestore.dart';

class EventItem {
  const EventItem({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.type,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String imagePath;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String type;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isUpcoming {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    return !eventDay.isBefore(startOfToday);
  }

  static EventItem fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return EventItem(
      id: snapshot.id,
      imagePath: data['imagePath'] as String? ?? 'assets/mountkinabalu.jpg',
      title: data['title'] as String? ?? 'Untitled Event',
      description: data['description'] as String? ?? '',
      date: _readDate(data['date']) ?? DateTime.now(),
      time: data['time'] as String? ?? '',
      location: data['location'] as String? ?? '',
      type: data['type'] as String? ?? 'academic',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, Object?> toFirestore({required String createdBy}) {
    return <String, Object?>{
      'imagePath': imagePath,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'time': time,
      'location': location,
      'type': type,
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
