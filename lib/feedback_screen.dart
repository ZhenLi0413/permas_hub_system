import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_feedback_screen.dart';
import 'feedback_model.dart';
import 'feedback_provider.dart';
import 'models/app_user_profile.dart';
import 'models/event_item.dart';
import 'services/event_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, required this.profile});

  final AppUserProfile? profile;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _eventService = EventService();
  late final FeedbackProvider _provider;

  int _rating = 0;
  final Set<String> _selectedCategories = <String>{};
  String? _selectedEventId;
  String? _selectedEventName;

  static const Color primary = Color(0xFF003366);
  static const Color textSecondary = Color(0xFF4A5D72);

  @override
  void initState() {
    super.initState();
    _provider = FeedbackProvider();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId =
        widget.profile?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before sending feedback.'),
        ),
      );
      return;
    }

    await _provider.submitFeedback(
      eventId: _selectedEventId ?? '',
      eventName: _selectedEventName ?? '',
      rating: _rating,
      comment: _commentController.text,
      categories: _selectedCategories.toList(),
    );

    if (!mounted) {
      return;
    }

    if (_provider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_provider.errorMessage!)));
      _provider.clearMessages();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_provider.successMessage ?? 'Feedback submitted.'),
      ),
    );
    _provider.clearMessages();

    setState(() {
      _rating = 0;
      _selectedCategories.clear();
      _selectedEventId = null;
      _selectedEventName = null;
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile?.isAdmin ?? false) {
      return const AdminFeedbackScreen();
    }

    return ChangeNotifierProvider<FeedbackProvider>.value(
      value: _provider,
      child: Consumer<FeedbackProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Feedback',
                      style: TextStyle(
                        color: primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Share your thoughts.',
                      style: TextStyle(
                        color: primary,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        height: 0.96,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Help us improve the PERMAS event experience. Your feedback helps us build better future events.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFDCE4EE)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.04),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EVENT',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<List<EventItem>>(
                              stream: _eventService.watchEvents(
                                sort: EventSort.newest,
                              ),
                              builder: (context, snapshot) {
                                final events =
                                    snapshot.data ?? const <EventItem>[];
                                if (events.isEmpty) {
                                  return const Text(
                                    'No events available yet. Please wait for events to be published.',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 13,
                                    ),
                                  );
                                }

                                return DropdownButtonFormField<String>(
                                  initialValue: _selectedEventId,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF2F5F9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText:
                                        'Select the event you recently joined',
                                  ),
                                  items: events
                                      .map(
                                        (event) => DropdownMenuItem<String>(
                                          value: event.id,
                                          child: Text(event.title),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    final selected = events
                                        .where((event) => event.id == value)
                                        .toList();
                                    setState(() {
                                      _selectedEventId = value;
                                      _selectedEventName = selected.isEmpty
                                          ? null
                                          : selected.first.title;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please select an event.';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'OVERALL EXPERIENCE',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: List.generate(5, (index) {
                                final starIndex = index + 1;
                                final isSelected = starIndex <= _rating;
                                return IconButton(
                                  onPressed: () {
                                    setState(() => _rating = starIndex);
                                  },
                                  iconSize: 38,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    isSelected ? Icons.star : Icons.star,
                                    color: isSelected
                                        ? primary
                                        : const Color(0xFFB8C5D3),
                                  ),
                                );
                              }),
                            ),
                            if (_rating == 0)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Please select your rating.',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 22),
                            const Text(
                              'DETAILED FEEDBACK',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _commentController,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText:
                                    'What can we do to improve your experience at PERMAS event?',
                                hintStyle: const TextStyle(
                                  color: textSecondary,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF2F5F9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(18),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Detailed feedback is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'CATEGORY',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: FeedbackModel.categoryOptions.map((
                                category,
                              ) {
                                final selected = _selectedCategories.contains(
                                  category,
                                );
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(category),
                                  onSelected: (isSelected) {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedCategories.add(category);
                                      } else {
                                        _selectedCategories.remove(category);
                                      }
                                    });
                                  },
                                  selectedColor: primary,
                                  backgroundColor: const Color(0xFFE3E9EF),
                                  labelStyle: TextStyle(
                                    color: selected ? Colors.white : primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (_selectedCategories.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Please select at least one category.',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 28),
                            const Text(
                              'By submitting, you agree to our community guidelines.',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: provider.isSubmitting
                                    ? null
                                    : _submitFeedback,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                child: provider.isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.8,
                                        ),
                                      )
                                    : const Text('SUBMIT FEEDBACK'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
