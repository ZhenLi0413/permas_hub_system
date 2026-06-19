import '../feedback_model.dart';
import 'event_item.dart';
import 'event_participation.dart';

class EventAnalytics {
  const EventAnalytics({
    required this.event,
    required this.pending,
    required this.confirmed,
    required this.attended,
    required this.feedbackCount,
    required this.averageRating,
    required this.ratingCounts,
    required this.categoryCounts,
  });

  final EventItem event;
  final int pending;
  final int confirmed;
  final int attended;
  final int feedbackCount;
  final double averageRating;
  final Map<int, int> ratingCounts;
  final Map<String, int> categoryCounts;

  int get totalParticipants => pending + confirmed + attended;

  double get attendanceRate =>
      totalParticipants == 0 ? 0 : attended / totalParticipants;

  double get feedbackRate => attended == 0 ? 0 : feedbackCount / attended;

  static List<EventAnalytics> calculate({
    required List<EventItem> events,
    required List<EventParticipation> participations,
    required List<FeedbackModel> feedbacks,
  }) {
    final results = events.map((event) {
      final eventParticipations = participations
          .where((item) => item.eventId == event.id)
          .toList();
      final eventFeedbacks = feedbacks
          .where((item) => item.eventId == event.id)
          .toList();
      final ratingCounts = <int, int>{
        for (var rating = 1; rating <= 5; rating++) rating: 0,
      };
      final categoryCounts = <String, int>{};

      for (final feedback in eventFeedbacks) {
        ratingCounts[feedback.rating] =
            (ratingCounts[feedback.rating] ?? 0) + 1;
        for (final category in feedback.categories) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      final ratingTotal = eventFeedbacks.fold<int>(
        0,
        (total, item) => total + item.rating,
      );

      return EventAnalytics(
        event: event,
        pending: eventParticipations
            .where((item) => item.status.toLowerCase() == 'pending')
            .length,
        confirmed: eventParticipations
            .where((item) => item.status.toLowerCase() == 'confirmed')
            .length,
        attended: eventParticipations
            .where((item) => item.status.toLowerCase() == 'attended')
            .length,
        feedbackCount: eventFeedbacks.length,
        averageRating: eventFeedbacks.isEmpty
            ? 0
            : ratingTotal / eventFeedbacks.length,
        ratingCounts: ratingCounts,
        categoryCounts: categoryCounts,
      );
    }).toList();

    results.sort((a, b) => b.event.date.compareTo(a.event.date));
    return results;
  }
}
