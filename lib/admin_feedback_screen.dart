import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'feedback_model.dart';
import 'feedback_provider.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  late final FeedbackProvider _provider;
  final ScrollController _listScrollController = ScrollController();
  String _selectedEventName = 'all';

  static const Color primary = Color(0xFF003366);
  static const Color textSecondary = Color(0xFF4A5D72);

  @override
  void initState() {
    super.initState();
    _provider = FeedbackProvider()..startListeningAdminFeedbacks();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _markReviewed(FeedbackModel feedback) async {
    await _provider.markReviewed(feedback.feedbackId);

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
      const SnackBar(content: Text('Feedback marked as reviewed.')),
    );
    _provider.clearMessages();
  }

  Future<void> _openReplyDialog(FeedbackModel feedback) async {
    final controller = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reply to feedback'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write your response to this feedback...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Send Reply'),
            ),
          ],
        );
      },
    );

    if (submitted != true) {
      return;
    }

    await _provider.replyToFeedback(
      feedbackId: feedback.feedbackId,
      reply: controller.text,
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
      SnackBar(content: Text(_provider.successMessage ?? 'Reply submitted.')),
    );
    _provider.clearMessages();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FeedbackProvider>.value(
      value: _provider,
      child: Consumer<FeedbackProvider>(
        builder: (context, provider, _) {
          final eventNameOptions = <String>{'all'}
            ..addAll(provider.feedbacks.map((item) => item.eventName));
          final eventNames = eventNameOptions.toList()..sort();
          final selectedEventName = eventNames.contains(_selectedEventName)
              ? _selectedEventName
              : 'all';
          final filteredItems = provider.feedbacks.where((item) {
            if (selectedEventName == 'all') {
              return true;
            }
            return item.eventName == selectedEventName;
          }).toList();

          return Scaffold(
            backgroundColor: const Color(0xFFF7F9FB),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EVENT FEEDBACK',
                        style: TextStyle(
                          color: Color(0xFF001E40),
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Review and manage submitted event feedback from members.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by Category',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: FeedbackProvider.adminCategories.map((
                          category,
                        ) {
                          final selected =
                              provider.selectedAdminCategory == category;
                          return ChoiceChip(
                            selected: selected,
                            label: Text(category),
                            onSelected: (_) =>
                                provider.setAdminCategory(category),
                            selectedColor: primary,
                            backgroundColor: const Color(0xFFE4EAF1),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Filter by Event',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedEventName,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCE4EE),
                            ),
                          ),
                        ),
                        items: eventNames
                            .map(
                              (eventName) => DropdownMenuItem<String>(
                                value: eventName,
                                child: Text(
                                  eventName == 'all' ? 'All Events' : eventName,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEventName = value ?? 'all';
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.isLoadingAdmin
                      ? const Center(child: CircularProgressIndicator())
                      : filteredItems.isEmpty
                      ? const Center(
                          child: Text(
                            'No feedback found for the selected filters.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : Scrollbar(
                          controller: _listScrollController,
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _listScrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: filteredItems.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFDCE4EE),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.eventName,
                                                style: const TextStyle(
                                                  color: primary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Submitted: ${_formatDate(item.submittedAt)}',
                                                style: const TextStyle(
                                                  color: textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                item.status ==
                                                    FeedbackModel.reviewedStatus
                                                ? const Color(0xFFD2F6DC)
                                                : const Color(0xFFFFE9B7),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            item.status,
                                            style: const TextStyle(
                                              color: primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(5, (i) {
                                            return Icon(
                                              i < item.rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: primary,
                                              size: 20,
                                            );
                                          }),
                                        ),
                                        ...item.categories.map((category) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE7EEF6),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              category,
                                              style: const TextStyle(
                                                color: primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item.comment,
                                      style: const TextStyle(
                                        color: textSecondary,
                                        fontSize: 14,
                                        height: 1.45,
                                      ),
                                    ),
                                    if (item.adminReply != null &&
                                        item.adminReply!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F7FB),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Admin reply: ${item.adminReply!}',
                                          style: const TextStyle(
                                            color: primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (item.status !=
                                            FeedbackModel.reviewedStatus)
                                          FilledButton(
                                            onPressed: () =>
                                                _markReviewed(item),
                                            child: const Text('Mark Reviewed'),
                                          ),
                                        FilledButton.tonal(
                                          onPressed: () =>
                                              _openReplyDialog(item),
                                          child: Text(
                                            item.adminReply == null
                                                ? 'Reply'
                                                : 'Edit Reply',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
