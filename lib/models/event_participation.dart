import 'package:cloud_firestore/cloud_firestore.dart';

class EventParticipation {
  const EventParticipation({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.fullName,
    required this.faculty,
    required this.matricNumber,
    required this.college,
    required this.status, // 'pending', 'confirmed', 'attended'
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final String fullName;
  final String faculty;
  final String matricNumber;
  final String college;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static EventParticipation fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return EventParticipation(
      id: snapshot.id,
      eventId: data['eventId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      faculty: data['faculty'] as String? ?? '',
      matricNumber: data['matricNumber'] as String? ?? '',
      college: data['college'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'eventId': eventId,
      'userId': userId,
      'fullName': fullName,
      'faculty': faculty,
      'matricNumber': matricNumber,
      'college': college,
      'status': status,
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
