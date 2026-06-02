import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'feedback_model.dart';
import 'feedback_service.dart';

class FeedbackProvider extends ChangeNotifier {
  FeedbackProvider({FeedbackService? service})
    : _service = service ?? FeedbackService();

  final FeedbackService _service;

  bool _isSubmitting = false;
  bool _isLoadingAdmin = false;
  String _selectedAdminCategory = 'all';
  String? _errorMessage;
  String? _successMessage;
  List<FeedbackModel> _feedbacks = const [];

  StreamSubscription<List<FeedbackModel>>? _feedbacksSubscription;

  bool get isSubmitting => _isSubmitting;
  bool get isLoadingAdmin => _isLoadingAdmin;
  String get selectedAdminCategory => _selectedAdminCategory;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<FeedbackModel> get feedbacks => _feedbacks;

  static const adminCategories = <String>[
    'all',
    ...FeedbackModel.categoryOptions,
  ];

  Future<void> submitFeedback({
    required String eventId,
    required String eventName,
    required int rating,
    required String comment,
    required List<String> categories,
  }) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      _errorMessage = 'Please sign in before sending feedback.';
      notifyListeners();
      return;
    }

    final trimmedComment = comment.trim();
    if (eventId.trim().isEmpty || eventName.trim().isEmpty) {
      _errorMessage = 'Please select an event.';
      notifyListeners();
      return;
    }
    if (rating < 1 || rating > 5) {
      _errorMessage = 'Please choose a star rating between 1 and 5.';
      notifyListeners();
      return;
    }
    if (trimmedComment.isEmpty) {
      _errorMessage = 'Detailed feedback is required.';
      notifyListeners();
      return;
    }
    final normalizedCategories = categories
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    if (normalizedCategories.isEmpty) {
      _errorMessage = 'Please select at least one category.';
      notifyListeners();
      return;
    }
    if (!normalizedCategories.every(FeedbackModel.categoryOptions.contains)) {
      _errorMessage = 'Please select valid categories.';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _successMessage = null;
    _isSubmitting = true;
    notifyListeners();

    try {
      final payload = FeedbackModel(
        feedbackId: '',
        userId: authUser.uid,
        eventId: eventId,
        eventName: eventName,
        rating: rating,
        comment: trimmedComment,
        categories: normalizedCategories,
        submittedAt: DateTime.now(),
        status: FeedbackModel.pendingStatus,
      );
      await _service.createFeedback(payload);
      _successMessage = 'Thank you. Your feedback has been submitted.';
    } on TimeoutException {
      _errorMessage =
          'Submission timed out. Please check your connection and try again.';
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _errorMessage =
            'You do not have permission to submit feedback. Please sign out and sign in again.';
      } else {
        _errorMessage = 'Firebase error: ${e.message ?? e.code}';
      }
    } catch (_) {
      _errorMessage = 'Unable to submit feedback right now. Please try again.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void startListeningAdminFeedbacks() {
    _isLoadingAdmin = true;
    _errorMessage = null;
    _feedbacksSubscription?.cancel();

    _feedbacksSubscription = _service
        .watchFeedbacks(category: _selectedAdminCategory)
        .listen(
          (items) {
            _feedbacks = items;
            _isLoadingAdmin = false;
            notifyListeners();
          },
          onError: (_) {
            _isLoadingAdmin = false;
            _errorMessage =
                'Unable to load feedback list. Please refresh and try again.';
            notifyListeners();
          },
        );
  }

  Future<void> setAdminCategory(String category) async {
    if (_selectedAdminCategory == category) {
      return;
    }
    _selectedAdminCategory = category;
    startListeningAdminFeedbacks();
    notifyListeners();
  }

  Future<void> markReviewed(String feedbackId) async {
    try {
      await _service.markReviewed(feedbackId);
    } catch (_) {
      _errorMessage = 'Unable to update feedback status.';
      notifyListeners();
    }
  }

  Future<void> replyToFeedback({
    required String feedbackId,
    required String reply,
  }) async {
    final trimmedReply = reply.trim();
    if (trimmedReply.isEmpty) {
      _errorMessage = 'Reply cannot be empty.';
      notifyListeners();
      return;
    }

    try {
      await _service.replyToFeedback(
        feedbackId: feedbackId,
        reply: trimmedReply,
      );
      _successMessage = 'Reply submitted.';
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Unable to submit reply right now.';
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _feedbacksSubscription?.cancel();
    super.dispose();
  }
}
