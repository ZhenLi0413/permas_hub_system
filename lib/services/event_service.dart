import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_item.dart';

enum EventSort { upcoming, newest, oldest }

class EventService {
  EventService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');

  Stream<List<EventItem>> watchEvents({
    String filterType = 'all',
    EventSort sort = EventSort.upcoming,
  }) {
    return _events.snapshots().map((snapshot) {
      final events = snapshot.docs.map(EventItem.fromSnapshot).where((event) {
        return filterType == 'all' || event.type == filterType;
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
      await _events.add(<String, Object?>{
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
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
        location: 'L50, UTM',
        type: 'academic',
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
        location: 'Student Activity Center',
        type: 'career',
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
        location: 'UTM',
        type: 'social',
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
