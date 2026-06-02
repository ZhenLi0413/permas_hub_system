import 'dart:async';

import 'package:flutter/material.dart';

import 'models/notification_model.dart';

class NotificationPopup extends StatefulWidget {
  const NotificationPopup({
    super.key,
    required this.notification,
    required this.onViewEvent,
    required this.onDismiss,
  });

  final NotificationModel notification;
  final VoidCallback onViewEvent;
  final VoidCallback onDismiss;

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> {
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed) {
      return;
    }
    _dismissed = true;
    _timer?.cancel();
    widget.onDismiss();
  }

  void _openEvent() {
    if (_dismissed) {
      return;
    }
    _dismissed = true;
    _timer?.cancel();
    widget.onViewEvent();
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: InkWell(
            onTap: _openEvent,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDE6F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 30, 64, 0.18),
                    blurRadius: 22,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: notification.type.color.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          notification.type.icon,
                          color: notification.type.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: const TextStyle(
                                color: Color(0xFF001E40),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.eventTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF10243A),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Dismiss',
                        onPressed: _dismiss,
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.previewText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF4A5D72),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: notification.type.color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          notification.formattedEventDate,
                          style: TextStyle(
                            color: notification.type.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openEvent,
                        child: Text(notification.actionLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationAnnouncementDetailScreen extends StatelessWidget {
  const NotificationAnnouncementDetailScreen({
    super.key,
    required this.notification,
  });

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF003366),
        elevation: 0,
        title: const Text('Announcement Detail'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDDE6F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 30, 64, 0.05),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: notification.type.color.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          notification.type.icon,
                          color: notification.type.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: const TextStyle(
                                color: Color(0xFF001E40),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.eventTitle,
                              style: const TextStyle(
                                color: Color(0xFF10243A),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _AnnouncementDetailRow(
                    label: 'Date',
                    value: notification.formattedEventDate,
                  ),
                  const SizedBox(height: 12),
                  _AnnouncementDetailRow(
                    label: 'Time',
                    value: notification.eventTime,
                  ),
                  const SizedBox(height: 12),
                  _AnnouncementDetailRow(
                    label: 'Venue',
                    value: notification.eventVenue,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Details',
                    style: TextStyle(
                      color: Color(0xFF001E40),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.eventDescription.isNotEmpty
                        ? notification.eventDescription
                        : notification.previewText,
                    style: const TextStyle(
                      color: Color(0xFF4A5D72),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementDetailRow extends StatelessWidget {
  const _AnnouncementDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4A5D72),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF001E40),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
