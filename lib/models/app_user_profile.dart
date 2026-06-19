import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.acceptedTerms,
    required this.membershipStatus,
    this.photoUrl,
    this.matricNo,
    this.faculty,
    this.yearOfStudy,
    this.acceptedTermsAt,
    this.createdAt,
    this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final bool acceptedTerms;
  final String membershipStatus;
  final String? photoUrl;
  final String? matricNo;
  final String? faculty;
  final String? yearOfStudy;
  final DateTime? acceptedTermsAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  bool get isAdmin => role == 'admin';
  bool get isCommittee => role == 'committee';
  bool get canManageEvents => isAdmin || isCommittee;
  bool get canManageMembers => isAdmin || isCommittee;
  bool get isMembershipPending => membershipStatus == 'pending';
  bool get isMembershipApproved => membershipStatus == 'approved';
  bool get isMembershipRejected => membershipStatus == 'rejected';

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
      // Profiles created before the application workflow are existing members.
      membershipStatus: _normalizeMembershipStatus(
        data['membershipStatus'] as String?,
      ),
      photoUrl: data['photoUrl'] as String?,
      matricNo: data['matricNo'] as String?,
      faculty: data['faculty'] as String?,
      yearOfStudy: data['yearOfStudy'] as String?,
      acceptedTermsAt: _readDate(data['acceptedTermsAt']),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      reviewedAt: _readDate(data['reviewedAt']),
      reviewedBy: _readOptionalString(data['reviewedBy']),
      rejectionReason: _readOptionalString(data['rejectionReason']),
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

  static String _normalizeMembershipStatus(String? status) {
    if (status == 'pending' || status == 'approved' || status == 'rejected') {
      return status!;
    }
    return 'approved';
  }

  static String? _readOptionalString(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }
}
