import 'package:flutter/material.dart';

import 'feedback_model.dart';
import 'feedback_service.dart';
import 'models/event_analytics.dart';
import 'models/event_item.dart';
import 'models/event_participation.dart';
import 'services/event_service.dart';
import 'services/participation_service.dart';

class ReportingScreen extends StatefulWidget {
  const ReportingScreen({
    super.key,
    EventService? eventService,
    ParticipationService? participationService,
    FeedbackService? feedbackService,
  }) : _eventService = eventService,
       _participationService = participationService,
       _feedbackService = feedbackService;

  final EventService? _eventService;
  final ParticipationService? _participationService;
  final FeedbackService? _feedbackService;

  @override
  State<ReportingScreen> createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  late final EventService _eventService;
  late final ParticipationService _participationService;
  late final FeedbackService _feedbackService;
  String _selectedEventId = 'all';

  static const primary = Color(0xFF003366);
  static const secondaryText = Color(0xFF52677D);

  @override
  void initState() {
    super.initState();
    _eventService = widget._eventService ?? EventService();
    _participationService =
        widget._participationService ?? ParticipationService();
    _feedbackService = widget._feedbackService ?? FeedbackService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Event Reports & Analytics'),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 0,
      ),
      body: StreamBuilder<List<EventItem>>(
        stream: _eventService.watchEvents(sort: EventSort.newest),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.hasError) {
            return _ErrorState(message: eventSnapshot.error.toString());
          }
          if (!eventSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<EventParticipation>>(
            stream: _participationService.watchAllParticipations(),
            builder: (context, participationSnapshot) {
              if (participationSnapshot.hasError) {
                return _ErrorState(
                  message: participationSnapshot.error.toString(),
                );
              }
              if (!participationSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<List<FeedbackModel>>(
                stream: _feedbackService.watchFeedbacks(),
                builder: (context, feedbackSnapshot) {
                  if (feedbackSnapshot.hasError) {
                    return _ErrorState(
                      message: feedbackSnapshot.error.toString(),
                    );
                  }
                  if (!feedbackSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allReports = EventAnalytics.calculate(
                    events: eventSnapshot.data!,
                    participations: participationSnapshot.data!,
                    feedbacks: feedbackSnapshot.data!,
                  );
                  return _buildReport(allReports);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReport(List<EventAnalytics> allReports) {
    final selectedExists = allReports.any(
      (report) => report.event.id == _selectedEventId,
    );
    final selectedId = selectedExists ? _selectedEventId : 'all';
    final reports = selectedId == 'all'
        ? allReports
        : allReports.where((report) => report.event.id == selectedId).toList();
    final participants = reports.fold<int>(
      0,
      (total, item) => total + item.totalParticipants,
    );
    final attended = reports.fold<int>(
      0,
      (total, item) => total + item.attended,
    );
    final feedbackCount = reports.fold<int>(
      0,
      (total, item) => total + item.feedbackCount,
    );
    final weightedRatingTotal = reports.fold<double>(
      0,
      (total, item) => total + (item.averageRating * item.feedbackCount),
    );
    final averageRating = feedbackCount == 0
        ? 0.0
        : weightedRatingTotal / feedbackCount;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Performance overview',
            style: TextStyle(
              color: primary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live participation, attendance, and feedback results from Firestore.',
            style: TextStyle(color: secondaryText, height: 1.4),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: selectedId,
            decoration: const InputDecoration(
              labelText: 'Event',
              prefixIcon: Icon(Icons.filter_alt_outlined),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All events')),
              ...allReports.map(
                (report) => DropdownMenuItem(
                  value: report.event.id,
                  child: Text(
                    report.event.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) =>
                setState(() => _selectedEventId = value ?? 'all'),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.sizeOf(context).width >= 720 ? 4 : 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _MetricCard(
                label: 'Registrations',
                value: '$participants',
                icon: Icons.groups_outlined,
                color: const Color(0xFF1261A0),
              ),
              _MetricCard(
                label: 'Attended',
                value: '$attended',
                supporting: _percentage(attended, participants),
                icon: Icons.how_to_reg_outlined,
                color: const Color(0xFF16805B),
              ),
              _MetricCard(
                label: 'Feedback',
                value: '$feedbackCount',
                supporting: 'responses',
                icon: Icons.rate_review_outlined,
                color: const Color(0xFF7B4FA3),
              ),
              _MetricCard(
                label: 'Average rating',
                value: feedbackCount == 0
                    ? '—'
                    : averageRating.toStringAsFixed(1),
                supporting: feedbackCount == 0 ? 'No ratings' : 'out of 5',
                icon: Icons.star_outline,
                color: const Color(0xFFE08A00),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Event breakdown',
                  style: TextStyle(
                    color: primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${reports.length} event${reports.length == 1 ? '' : 's'}',
                style: const TextStyle(color: secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (reports.isEmpty)
            const _EmptyState()
          else
            ...reports.map(_EventReportCard.new),
        ],
      ),
    );
  }

  static String _percentage(int value, int total) {
    if (total == 0) return '0% rate';
    return '${(value / total * 100).round()}% rate';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.supporting,
  });

  final String label;
  final String value;
  final String? supporting;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            supporting == null ? label : '$label · $supporting',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF52677D), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EventReportCard extends StatelessWidget {
  const _EventReportCard(this.report);

  final EventAnalytics report;

  @override
  Widget build(BuildContext context) {
    final topCategories = report.categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE1E8EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.event.title,
              style: const TextStyle(
                color: Color(0xFF003366),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_date(report.event.date)} · ${report.event.venue}',
              style: const TextStyle(color: Color(0xFF52677D), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip('Pending', report.pending, const Color(0xFFE08A00)),
                _StatusChip(
                  'Confirmed',
                  report.confirmed,
                  const Color(0xFF1261A0),
                ),
                _StatusChip(
                  'Attended',
                  report.attended,
                  const Color(0xFF16805B),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Attendance rate: ${(report.attendanceRate * 100).round()}% '
              '(${report.attended}/${report.totalParticipants})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            LinearProgressIndicator(
              value: report.attendanceRate.clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: const Color(0xFFE8EEF3),
              color: const Color(0xFF16805B),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFE08A00), size: 20),
                const SizedBox(width: 6),
                Text(
                  report.feedbackCount == 0
                      ? 'No feedback received'
                      : '${report.averageRating.toStringAsFixed(1)}/5 from '
                            '${report.feedbackCount} response${report.feedbackCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (topCategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: topCategories.take(3).map((entry) {
                  return Chip(
                    label: Text('${entry.key} (${entry.value})'),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _date(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 52, color: Color(0xFF8A9AAA)),
          SizedBox(height: 12),
          Text('No event data is available yet.'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Unable to load analytics.\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
