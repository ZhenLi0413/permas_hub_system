import 'package:cloud_firestore/cloud_firestore.dart';

class EventItem {
  const EventItem({
    required this.id,
    this.imagePath,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.venue,
    required this.category,
    required this.status,
    required this.registrationDueDate,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? imagePath;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String venue;
  final String category;
  final String status;
  final DateTime registrationDueDate;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasImage => imagePath != null && imagePath!.trim().isNotEmpty;

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
      imagePath: _readOptionalString(data['imagePath']),
      title: data['title'] as String? ?? 'Untitled Event',
      description: data['description'] as String? ?? '',
      date: _readDate(data['date']) ?? DateTime.now(),
      time: data['time'] as String? ?? '',
      venue: data['venue'] as String? ?? data['location'] as String? ?? '',
      category:
          data['category'] as String? ?? data['type'] as String? ?? 'academic',
      status: data['status'] as String? ?? 'open',
      registrationDueDate:
          _readDate(data['registrationDueDate']) ??
          _readDate(data['date']) ??
          DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, Object?> toFirestore({required String createdBy}) {
    return <String, Object?>{
      'imagePath': _readOptionalString(imagePath),
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'time': time,
      'venue': venue,
      'category': category,
      'status': status,
      'registrationDueDate': Timestamp.fromDate(
        DateTime(
          registrationDueDate.year,
          registrationDueDate.month,
          registrationDueDate.day,
        ),
      ),
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static String? _readOptionalString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
