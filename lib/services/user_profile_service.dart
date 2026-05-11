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

  Future<void> createRegistrationProfile({
    required User user,
    required String name,
  }) async {
    await _users.doc(user.uid).set(<String, Object?>{
      'name': name.trim(),
      'email': user.email ?? '',
      'role': 'member',
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
}



