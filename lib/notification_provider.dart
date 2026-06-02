import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models/notification_model.dart';
import 'services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? service})
    : _service = service ?? NotificationService();

  final NotificationService _service;

  StreamSubscription<List<NotificationModel>>? _subscription;

  String _userId = '';
  bool _hasInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _notifications = const [];
  NotificationModel? _pendingPopup;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((item) => item.isUnread).length;

  void startListening(String userId) {
    if (_userId == userId && _subscription != null) {
      return;
    }

    _userId = userId;
    _hasInitialized = false;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service
        .watchNotifications(userId)
        .listen(
          (items) {
            final previousIds = _notifications.map((item) => item.id).toSet();
            _notifications = items;
            _isLoading = false;

            if (_hasInitialized) {
              final newItems = items
                  .where((item) => !previousIds.contains(item.id))
                  .toList();
              if (newItems.isNotEmpty) {
                _pendingPopup = newItems.firstWhere(
                  (item) => item.isUnread,
                  orElse: () => newItems.first,
                );
              }
            } else {
              _hasInitialized = true;
            }

            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _errorMessage = 'Unable to load notifications. Please try again.';
            notifyListeners();
          },
        );
  }

  NotificationModel? consumePendingPopup() {
    final notification = _pendingPopup;
    _pendingPopup = null;
    return notification;
  }

  Future<void> markAsRead(String notificationId) async {
    if (_userId.isEmpty) {
      return;
    }

    try {
      await _service.markAsRead(
        userId: _userId,
        notificationId: notificationId,
      );
    } catch (_) {
      _errorMessage = 'Unable to update notification status.';
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId.isEmpty) {
      return;
    }

    try {
      await _service.markAllAsRead(_userId);
    } catch (_) {
      _errorMessage = 'Unable to update notification status.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
