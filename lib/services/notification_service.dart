import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_item.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _notifications(String userId) =>
      _users.doc(userId).collection('notifications');

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    if (userId.trim().isEmpty) {
      return Stream.value(const <NotificationModel>[]);
    }

    return _notifications(userId).snapshots().map((snapshot) {
      final items = snapshot.docs.map(NotificationModel.fromSnapshot).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _notifications(userId).doc(notificationId).set(<String, Object?>{
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllAsRead(String userId) async {
    final unreadSnapshot = await _notifications(
      userId,
    ).where('isRead', isEqualTo: false).get();

    if (unreadSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in unreadSnapshot.docs) {
      batch.set(doc.reference, <String, Object?>{
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> publishEventNotification({
    required String eventId,
    required EventItem event,
    NotificationType type = NotificationType.newEventAnnouncement,
  }) async {
    final membersSnapshot = await _users
        .where('role', isEqualTo: 'member')
        .get();
    final approvedMembers = membersSnapshot.docs.where((member) {
      final status = member.data()['membershipStatus'] as String?;
      // Missing status represents a member created before applications existed.
      return status == null || status == 'approved';
    }).toList();
    if (approvedMembers.isEmpty) {
      return;
    }

    final createdAt = DateTime.now();
    final batch = _firestore.batch();

    for (final member in approvedMembers) {
      final notification = NotificationModel.fromEvent(
        id: '',
        recipientUserId: member.id,
        eventId: eventId,
        event: event,
        type: type,
        createdAt: createdAt,
      );
      final ref = _notifications(member.id).doc();
      batch.set(ref, notification.toFirestore());
    }

    await batch.commit();
  }
}
