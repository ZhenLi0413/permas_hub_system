import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_profile.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const adminEmail = 'admin@gmail.com';
  static const adminPassword = 'admin123';

  static bool isAdminEmail(String? email) =>
      email?.trim().toLowerCase() == adminEmail;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<AppUserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map(AppUserProfile.fromSnapshot);
  }

  Future<AppUserProfile?> getProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    return AppUserProfile.fromSnapshot(snapshot);
  }

  Stream<List<AppUserProfile>> watchMembershipApplications() {
    return _users.snapshots().map((snapshot) {
      final profiles = snapshot.docs
          .map(AppUserProfile.fromSnapshot)
          .whereType<AppUserProfile>()
          .where((profile) => !profile.isAdmin && !profile.isCommittee)
          .toList();
      profiles.sort((a, b) {
        const order = <String, int>{'pending': 0, 'rejected': 1, 'approved': 2};
        final statusComparison = (order[a.membershipStatus] ?? 3).compareTo(
          order[b.membershipStatus] ?? 3,
        );
        if (statusComparison != 0) return statusComparison;
        return (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        );
      });
      return profiles;
    });
  }

  Future<void> createRegistrationProfile({
    required User user,
    required String name,
    required String matricNo,
    required String faculty,
    required String yearOfStudy,
  }) async {
    await _users.doc(user.uid).set(<String, Object?>{
      'name': name.trim(),
      'email': user.email ?? '',
      'role': 'member',
      'membershipStatus': 'pending',
      'matricNo': matricNo.trim(),
      'faculty': faculty.trim(),
      'yearOfStudy': yearOfStudy.trim(),
      'acceptedTerms': true,
      'acceptedTermsAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureGoogleProfile(User user) async {
    final profileRef = _users.doc(user.uid);
    final snapshot = await profileRef.get();

    if (snapshot.exists) {
      await profileRef.update(<String, Object?>{
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await profileRef.set(<String, Object?>{
      'name': user.displayName?.trim().isNotEmpty == true
          ? user.displayName
          : 'PERMAS Member',
      'email': user.email ?? '',
      'role': 'member',
      'membershipStatus': 'pending',
      'acceptedTerms': false,
      'acceptedTermsAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureAdminProfile(User user) async {
    final profileRef = _users.doc(user.uid);
    final snapshot = await profileRef.get();

    final data = <String, Object?>{
      'name': 'PERMAS Admin',
      'email': adminEmail,
      'role': 'admin',
      'membershipStatus': 'approved',
      'acceptedTerms': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (snapshot.exists) {
      await profileRef.set(data, SetOptions(merge: true));
      return;
    }

    await profileRef.set(<String, Object?>{
      ...data,
      'acceptedTermsAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _users.doc(uid).update(<String, Object?>{
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfileDetails({
    required String uid,
    required String name,
    required String matricNo,
    required String faculty,
    required String yearOfStudy,
  }) async {
    await _users.doc(uid).update(<String, Object?>{
      'name': name.trim(),
      'matricNo': matricNo.trim(),
      'faculty': faculty.trim(),
      'yearOfStudy': yearOfStudy.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reviewMembershipApplication({
    required String uid,
    required String reviewerId,
    required bool approve,
    String? rejectionReason,
  }) async {
    final reason = rejectionReason?.trim();
    if (!approve && (reason == null || reason.isEmpty)) {
      throw ArgumentError('A rejection reason is required.');
    }

    await _users.doc(uid).update(<String, Object?>{
      'membershipStatus': approve ? 'approved' : 'rejected',
      'reviewedBy': reviewerId,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': approve ? null : reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
