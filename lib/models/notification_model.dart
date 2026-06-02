import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'event_item.dart';

enum NotificationType {
  newEventAnnouncement(
    'new_event_announcement',
    'New Event Announcement',
    Icons.campaign_outlined,
    Color(0xFF003366),
  ),
  eventUpdate(
    'event_update',
    'Event Update',
    Icons.update_outlined,
    Color(0xFF0F6BA8),
  ),
  eventCancellation(
    'event_cancellation',
    'Event Cancellation',
    Icons.event_busy_outlined,
    Color(0xFFB42318),
  ),
  eventReminder(
    'event_reminder',
    'Event Reminder',
    Icons.notifications_active_outlined,
    Color(0xFF8E5A00),
  );

  const NotificationType(this.value, this.label, this.icon, this.color);

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  static NotificationType fromValue(String? value) {
    switch (value) {
      case 'event_update':
        return NotificationType.eventUpdate;
      case 'event_cancellation':
        return NotificationType.eventCancellation;
      case 'event_reminder':
        return NotificationType.eventReminder;
      case 'new_event_announcement':
      default:
        return NotificationType.newEventAnnouncement;
    }
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.recipientUserId,
    required this.type,
    required this.title,
    required this.shortDescription,
    required this.eventId,
    required this.eventTitle,
    required this.eventDescription,
    required this.eventDate,
    required this.eventTime,
    required this.eventVenue,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.updatedAt,
  });

  final String id;
  final String recipientUserId;
  final NotificationType type;
  final String title;
  final String shortDescription;
  final String eventId;
  final String eventTitle;
  final String eventDescription;
  final DateTime eventDate;
  final String eventTime;
  final String eventVenue;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? updatedAt;

  bool get isUnread => !isRead;

  String get formattedEventDate => _formatDate(eventDate);

  String get previewText =>
      shortDescription.trim().isNotEmpty ? shortDescription : eventDescription;

  String get actionLabel => 'View Event';

  factory NotificationModel.fromEvent({
    required String id,
    required String recipientUserId,
    required String eventId,
    required EventItem event,
    required NotificationType type,
    bool isRead = false,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id,
      recipientUserId: recipientUserId,
      type: type,
      title: type.label,
      shortDescription: _buildSummary(event.description),
      eventId: eventId,
      eventTitle: event.title,
      eventDescription: event.description,
      eventDate: event.date,
      eventTime: event.time,
      eventVenue: event.venue,
      isRead: isRead,
      createdAt: createdAt ?? DateTime.now(),
      readAt: readAt,
      updatedAt: updatedAt,
    );
  }

  factory NotificationModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return NotificationModel(
      id: snapshot.id,
      recipientUserId: data['recipientUserId'] as String? ?? '',
      type: NotificationType.fromValue(data['type'] as String?),
      title:
          data['title'] as String? ??
          NotificationType.newEventAnnouncement.label,
      shortDescription: data['shortDescription'] as String? ?? '',
      eventId: data['eventId'] as String? ?? '',
      eventTitle: data['eventTitle'] as String? ?? 'Untitled Event',
      eventDescription: data['eventDescription'] as String? ?? '',
      eventDate: _readDate(data['eventDate']) ?? DateTime.now(),
      eventTime: data['eventTime'] as String? ?? '',
      eventVenue: data['eventVenue'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      readAt: _readDate(data['readAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'recipientUserId': recipientUserId,
      'type': type.value,
      'title': title,
      'shortDescription': shortDescription,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDescription': eventDescription,
      'eventDate': Timestamp.fromDate(
        DateTime(eventDate.year, eventDate.month, eventDate.day),
      ),
      'eventTime': eventTime,
      'eventVenue': eventVenue,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt == null ? null : Timestamp.fromDate(readAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static String _buildSummary(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      return 'A new event has been published.';
    }
    if (trimmed.length <= 110) {
      return trimmed;
    }
    return '${trimmed.substring(0, 107).trimRight()}...';
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
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
}
