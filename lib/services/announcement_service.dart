import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement_item.dart';

class AnnouncementService {
  AnnouncementService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _firestore.collection('announcements');

  Stream<List<AnnouncementItem>> watchAnnouncements() {
    return _announcements.snapshots().map((snapshot) {
      final announcements = snapshot.docs
          .map(AnnouncementItem.fromSnapshot)
          .toList();
      announcements.sort((a, b) => b.date.compareTo(a.date));
      return announcements;
    });
  }

  Future<void> saveAnnouncement(
    AnnouncementItem announcement, {
    required String createdBy,
  }) async {
    final data = announcement.toFirestore(createdBy: createdBy);
    if (announcement.id.isEmpty) {
      await _announcements.add(<String, Object?>{
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _announcements
        .doc(announcement.id)
        .set(data, SetOptions(merge: true));
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _announcements.doc(announcementId).delete();
  }

  Future<void> ensureStarterAnnouncements({required String createdBy}) async {
    final snapshot = await _announcements.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final now = DateTime.now();
    final samples = <AnnouncementItem>[
      AnnouncementItem(
        id: '',
        imagePath: AnnouncementItem.defaultImagePath,
        type: 'urgent',
        date: now,
        title: 'System Maintenance: Infrastructure Upgrade',
        content:
            'The PERMAS Hub portal will undergo scheduled maintenance. Some services may be intermittent during the upgrade window.',
        createdBy: createdBy,
      ),
      AnnouncementItem(
        id: '',
        imagePath: AnnouncementItem.defaultImagePath,
        type: 'general',
        date: now.subtract(const Duration(days: 2)),
        title: 'Strategic Realignment for Q4 Operations',
        content:
            'PERMAS is improving cross-team coordination and response times through updated committee operating workflows.',
        createdBy: createdBy,
      ),
      AnnouncementItem(
        id: '',
        imagePath: AnnouncementItem.defaultImagePath,
        type: 'general',
        date: now.subtract(const Duration(days: 5)),
        title: 'Recognizing Exceptional Community Leadership',
        content:
            'This month we recognize volunteer contributions from members supporting campus community programs.',
        createdBy: createdBy,
      ),
    ];

    for (final announcement in samples) {
      final ref = _announcements.doc();
      batch.set(ref, <String, Object?>{
        ...announcement.toFirestore(createdBy: createdBy),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
