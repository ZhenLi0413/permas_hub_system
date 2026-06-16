import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.acceptedTerms,
    this.photoUrl,
    this.matricNo,
    this.faculty,
    this.yearOfStudy,
    this.acceptedTermsAt,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final bool acceptedTerms;
  final String? photoUrl;
  final String? matricNo;
  final String? faculty;
  final String? yearOfStudy;
  final DateTime? acceptedTermsAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == 'admin';
  bool get isCommittee => role == 'committee';
  bool get canManageEvents => isAdmin || isCommittee;

  static AppUserProfile? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    return AppUserProfile(
      uid: snapshot.id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'PERMAS Member',
      email: data['email'] as String? ?? '',
      role: _normalizeRole(data['role'] as String?),
      acceptedTerms: data['acceptedTerms'] as bool? ?? false,
      photoUrl: data['photoUrl'] as String?,
      matricNo: data['matricNo'] as String?,
      faculty: data['faculty'] as String?,
      yearOfStudy: data['yearOfStudy'] as String?,
      acceptedTermsAt: _readDate(data['acceptedTermsAt']),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
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

  static String _normalizeRole(String? role) {
    if (role == 'admin' || role == 'committee') {
      return role!;
    }
    return 'member';
  }
}
