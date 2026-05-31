import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementItem {
  const AnnouncementItem({
    required this.id,
    this.imagePath,
    required this.type,
    required this.date,
    required this.title,
    required this.content,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? imagePath;
  final String type;
  final DateTime date;
  final String title;
  final String content;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const defaultImagePath = 'assets/mountkinabalu.jpg';

  bool get hasImage => imagePath != null && imagePath!.trim().isNotEmpty;
  bool get isUrgent => type == 'urgent';

  static AnnouncementItem fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return AnnouncementItem(
      id: snapshot.id,
      imagePath: _readOptionalString(data['imagePath']),
      type: data['type'] as String? ?? 'general',
      date: _readDate(data['date']) ?? DateTime.now(),
      title: data['title'] as String? ?? 'Untitled Announcement',
      content: data['content'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, Object?> toFirestore({required String createdBy}) {
    return <String, Object?>{
      'imagePath': _readOptionalString(imagePath),
      'type': type,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'title': title,
      'content': content,
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
