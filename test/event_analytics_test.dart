import 'package:flutter_test/flutter_test.dart';
import 'package:permas_hub_system/feedback_model.dart';
import 'package:permas_hub_system/models/event_analytics.dart';
import 'package:permas_hub_system/models/event_item.dart';
import 'package:permas_hub_system/models/event_participation.dart';

void main() {
  test('calculates participation, attendance, and feedback summaries', () {
    final event = EventItem(
      id: 'event-1',
      title: 'Leadership Camp',
      description: '',
      date: DateTime(2026, 6, 1),
      time: '9:00 AM',
      venue: 'UTM',
      category: 'academic',
      status: 'closed',
      registrationDueDate: DateTime(2026, 5, 28),
      createdBy: 'committee-1',
    );
    final participations = [
      _participation('p1', 'pending'),
      _participation('p2', 'confirmed'),
      _participation('p3', 'attended'),
      _participation('p4', 'attended'),
    ];
    final feedbacks = [
      _feedback('f1', 4, ['Event Content']),
      _feedback('f2', 5, ['Event Content', 'Venue & Facilities']),
    ];

    final report = EventAnalytics.calculate(
      events: [event],
      participations: participations,
      feedbacks: feedbacks,
    ).single;

    expect(report.totalParticipants, 4);
    expect(report.pending, 1);
    expect(report.confirmed, 1);
    expect(report.attended, 2);
    expect(report.attendanceRate, 0.5);
    expect(report.feedbackCount, 2);
    expect(report.averageRating, 4.5);
    expect(report.ratingCounts[5], 1);
    expect(report.categoryCounts['Event Content'], 2);
  });
}

EventParticipation _participation(String id, String status) {
  return EventParticipation(
    id: id,
    eventId: 'event-1',
    userId: 'user-$id',
    fullName: 'Member $id',
    faculty: 'Computing',
    matricNumber: id,
    college: 'KDOJ',
    status: status,
  );
}

FeedbackModel _feedback(String id, int rating, List<String> categories) {
  return FeedbackModel(
    feedbackId: id,
    userId: 'user-$id',
    eventId: 'event-1',
    eventName: 'Leadership Camp',
    rating: rating,
    comment: 'Good event',
    categories: categories,
    submittedAt: DateTime(2026, 6, 2),
    status: FeedbackModel.pendingStatus,
  );
}
