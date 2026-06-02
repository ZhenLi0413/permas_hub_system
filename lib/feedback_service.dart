import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'feedback_model.dart';

class FeedbackService {
  FeedbackService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _feedbacks =>
      _firestore.collection('feedbacks');

  Stream<List<FeedbackModel>> watchFeedbacks({String category = 'all'}) {
    return _feedbacks.orderBy('submittedAt', descending: true).snapshots().map((
      snapshot,
    ) {
      final all = snapshot.docs.map(FeedbackModel.fromSnapshot).toList();
      if (category == 'all') {
        return all;
      }
      return all.where((item) => item.categories.contains(category)).toList();
    });
  }

  Future<void> createFeedback(FeedbackModel feedback) async {
    final docRef = _feedbacks.doc();
    final payload = feedback.copyWith(feedbackId: docRef.id).toFirestore();
    await docRef.set(payload);
  }

  Future<void> updateFeedback(FeedbackModel feedback) async {
    if (feedback.feedbackId.trim().isEmpty) {
      throw ArgumentError('feedbackId is required for update.');
    }

    await _feedbacks
        .doc(feedback.feedbackId)
        .set(feedback.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteFeedback(String feedbackId) async {
    await _feedbacks.doc(feedbackId).delete();
  }

  Future<void> markReviewed(String feedbackId) async {
    await _feedbacks.doc(feedbackId).set(<String, Object?>{
      'status': FeedbackModel.reviewedStatus,
    }, SetOptions(merge: true));
  }

  Future<void> replyToFeedback({
    required String feedbackId,
    required String reply,
  }) async {
    await _feedbacks.doc(feedbackId).set(<String, Object?>{
      'status': FeedbackModel.reviewedStatus,
      'adminReply': reply.trim(),
      'repliedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
