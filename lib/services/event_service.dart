import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/event_item.dart';
import 'notification_service.dart';

enum EventSort { upcoming, newest, oldest }

class EventService {
  EventService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _notificationService = NotificationService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');

  Stream<List<EventItem>> watchEvents({
    String filterCategory = 'all',
    EventSort sort = EventSort.upcoming,
  }) {
    return _events.snapshots().map((snapshot) {
      final events = snapshot.docs.map(EventItem.fromSnapshot).where((event) {
        return filterCategory == 'all' || event.category == filterCategory;
      }).toList();

      events.sort((a, b) {
        switch (sort) {
          case EventSort.upcoming:
            return a.date.compareTo(b.date);
          case EventSort.newest:
            return b.date.compareTo(a.date);
          case EventSort.oldest:
            return a.date.compareTo(b.date);
        }
      });

      if (sort == EventSort.upcoming) {
        events.sort((a, b) {
          final aPast = a.isUpcoming ? 0 : 1;
          final bPast = b.isUpcoming ? 0 : 1;
          if (aPast != bPast) {
            return aPast.compareTo(bPast);
          }
          return a.date.compareTo(b.date);
        });
      }

      return events;
    });
  }

  Future<void> saveEvent(EventItem event, {required String createdBy}) async {
    final data = event.toFirestore(createdBy: createdBy);
    if (event.id.isEmpty) {
      final ref = await _events.add(<String, Object?>{
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await _notificationService.publishEventNotification(
          eventId: ref.id,
          event: event,
        );
      } catch (error) {
        debugPrint('Unable to publish event notification: $error');
      }
      return;
    }

    await _events.doc(event.id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteEvent(String eventId) async {
    await _events.doc(eventId).delete();
  }

  Future<void> ensureStarterEvents({required String createdBy}) async {
    final snapshot = await _events.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final now = DateTime.now();
    final samples = <EventItem>[
      EventItem(
        id: '',
        imagePath: 'assets/mountkinabalu.jpg',
        title: 'PERMAS Team Building',
        description:
            'A community bonding session with collaborative activities for members and committees.',
        date: now.add(const Duration(days: 7)),
        time: '10:00 AM',
        venue: 'L50, UTM',
        category: 'academic',
        status: 'open',
        capacity: 50,
        registrationDueDate: now.add(const Duration(days: 5)),
        createdBy: createdBy,
      ),
      EventItem(
        id: '',
        imagePath: 'assets/mountkinabalu.jpg',
        title: 'Career Fair: Tech and Innovation',
        description:
            'Meet industry guests, explore internship pathways, and prepare for early career opportunities.',
        date: now.add(const Duration(days: 14)),
        time: '09:00 AM',
        venue: 'Student Activity Center',
        category: 'career',
        status: 'open',
        capacity: 80,
        registrationDueDate: now.add(const Duration(days: 10)),
        createdBy: createdBy,
      ),
      EventItem(
        id: '',
        imagePath: 'assets/mountkinabalu.jpg',
        title: 'PERMAS Gala Night',
        description:
            'An evening celebration for the PERMAS community with performances and networking.',
        date: now.add(const Duration(days: 30)),
        time: '06:00 PM',
        venue: 'UTM',
        category: 'social',
        status: 'open',
        capacity: 120,
        registrationDueDate: now.add(const Duration(days: 21)),
        createdBy: createdBy,
      ),
    ];

    for (final event in samples) {
      final ref = _events.doc();
      batch.set(ref, <String, Object?>{
        ...event.toFirestore(createdBy: createdBy),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
