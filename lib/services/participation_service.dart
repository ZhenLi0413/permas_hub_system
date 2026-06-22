import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_participation.dart';

class ParticipationService {
  ParticipationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _participations =>
      _firestore.collection('participations');

  // Stream of a user's participation status for a specific event
  Stream<EventParticipation?> watchParticipation(
    String eventId,
    String userId,
  ) {
    final docId = '${userId}_$eventId';
    return _participations.doc(docId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return EventParticipation.fromSnapshot(snapshot);
    });
  }

  // Stream of all participations for a specific event (for admin view)
  Stream<List<EventParticipation>> watchEventParticipations(String eventId) {
    return _participations.where('eventId', isEqualTo: eventId).snapshots().map(
      (snapshot) {
        return snapshot.docs.map(EventParticipation.fromSnapshot).toList();
      },
    );
  }

  // Stream of all participations for a specific user (to show all registered events)
  Stream<List<EventParticipation>> watchUserParticipations(String userId) {
    return _participations.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map(EventParticipation.fromSnapshot).toList();
    });
  }

  // Stream of all participations in the system, used to compute event counts once.
  Stream<List<EventParticipation>> watchAllParticipations() {
    return _participations.snapshots().map((snapshot) {
      return snapshot.docs.map(EventParticipation.fromSnapshot).toList();
    });
  }

  // Register for an event
  Future<void> register({
    required String eventId,
    required String userId,
    required String fullName,
    required String faculty,
    required String matricNumber,
    required String college,
    required String courseProgram,
    required String semester,
    required String phoneNumber,
    required String emergencyContact,
    required String dietaryRestrictions,
  }) async {
    final docId = '${userId}_$eventId';
    await _participations.doc(docId).set(<String, Object?>{
      'eventId': eventId,
      'userId': userId,
      'fullName': fullName.trim(),
      'faculty': faculty.trim(),
      'matricNumber': matricNumber.trim(),
      'college': college.trim(),
      'courseProgram': courseProgram.trim(),
      'semester': semester.trim(),
      'phoneNumber': phoneNumber.trim(),
      'emergencyContact': emergencyContact.trim(),
      'dietaryRestrictions': dietaryRestrictions.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update status (approve -> 'confirmed', mark attended -> 'attended')
  Future<void> updateStatus(String docId, String status) async {
    await _participations.doc(docId).update(<String, Object?>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete/Cancel participation
  Future<void> deleteParticipation(String docId) async {
    await _participations.doc(docId).delete();
  }
}
