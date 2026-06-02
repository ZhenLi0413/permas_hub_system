import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  const FeedbackModel({
    required this.feedbackId,
    required this.userId,
    required this.eventId,
    required this.eventName,
    required this.rating,
    required this.comment,
    required this.categories,
    required this.submittedAt,
    required this.status,
    this.adminReply,
    this.repliedAt,
  });

  final String feedbackId;
  final String userId;
  final String eventId;
  final String eventName;
  final int rating;
  final String comment;
  final List<String> categories;
  final DateTime submittedAt;
  final String status;
  final String? adminReply;
  final DateTime? repliedAt;

  static const pendingStatus = 'Pending';
  static const reviewedStatus = 'Reviewed';

  static const categoryOptions = <String>[
    'Event Organization',
    'Event Content',
    'Activities & Engagement',
    'Venue & Facilities',
    'Suggestions',
    'Complaint/Issue',
  ];

  static FeedbackModel fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return FeedbackModel(
      feedbackId: data['feedbackId'] as String? ?? snapshot.id,
      userId: data['userId'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      eventName: data['eventName'] as String? ?? 'Unknown Event',
      rating: _readRating(data['rating']),
      comment: data['comment'] as String? ?? '',
      categories: _readCategories(data),
      submittedAt: _readDate(data['submittedAt']) ?? DateTime.now(),
      status: data['status'] as String? ?? pendingStatus,
      adminReply: _readOptionalString(data['adminReply']),
      repliedAt: _readDate(data['repliedAt']),
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'feedbackId': feedbackId,
      'userId': userId,
      'eventId': eventId,
      'eventName': eventName,
      'rating': rating,
      'comment': comment,
      'categories': categories,
      // Legacy compatibility for older readers expecting a single category.
      'category': categories.isEmpty ? null : categories.first,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status,
      'adminReply': adminReply,
      'repliedAt': repliedAt == null ? null : Timestamp.fromDate(repliedAt!),
    };
  }

  FeedbackModel copyWith({
    String? feedbackId,
    String? userId,
    String? eventId,
    String? eventName,
    int? rating,
    String? comment,
    List<String>? categories,
    DateTime? submittedAt,
    String? status,
    String? adminReply,
    DateTime? repliedAt,
  }) {
    return FeedbackModel(
      feedbackId: feedbackId ?? this.feedbackId,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      categories: categories ?? this.categories,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      adminReply: adminReply ?? this.adminReply,
      repliedAt: repliedAt ?? this.repliedAt,
    );
  }

  static List<String> _readCategories(Map<String, dynamic> data) {
    final dynamicList = data['categories'];
    if (dynamicList is List) {
      final parsed = dynamicList
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    final legacyCategory = _readOptionalString(data['category']);
    if (legacyCategory != null) {
      return <String>[legacyCategory];
    }

    return <String>['Suggestions'];
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

  static String? _readOptionalString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _readRating(Object? value) {
    if (value is int) {
      return value.clamp(1, 5);
    }
    if (value is num) {
      return value.toInt().clamp(1, 5);
    }
    return 1;
  }
}
