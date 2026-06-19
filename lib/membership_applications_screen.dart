import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/app_user_profile.dart';
import 'services/user_profile_service.dart';

class MembershipApplicationsScreen extends StatefulWidget {
  const MembershipApplicationsScreen({super.key, UserProfileService? service})
    : _service = service;

  final UserProfileService? _service;

  @override
  State<MembershipApplicationsScreen> createState() =>
      _MembershipApplicationsScreenState();
}

class _MembershipApplicationsScreenState
    extends State<MembershipApplicationsScreen> {
  late final UserProfileService _service;
  String _filter = 'pending';
  String? _busyUserId;

  static const primary = Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? UserProfileService();
  }

  Future<void> _approve(AppUserProfile applicant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve application?'),
        content: Text(
          '${applicant.name} will receive full member access to PERMAS Hub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _review(applicant, approve: true);
  }

  Future<void> _reject(AppUserProfile applicant) async {
    final controller = TextEditingController();
    String? validationMessage;
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reject application'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Reason',
              hintText: 'Explain why the application is not valid',
              errorText: validationMessage,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
              ),
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  setDialogState(
                    () => validationMessage = 'A rejection reason is required.',
                  );
                  return;
                }
                Navigator.pop(context, value);
              },
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (reason == null) return;
    await _review(applicant, approve: false, reason: reason);
  }

  Future<void> _review(
    AppUserProfile applicant, {
    required bool approve,
    String? reason,
  }) async {
    final reviewerId = FirebaseAuth.instance.currentUser?.uid;
    if (reviewerId == null) return;
    setState(() => _busyUserId = applicant.uid);
    try {
      await _service.reviewMembershipApplication(
        uid: applicant.uid,
        reviewerId: reviewerId,
        approve: approve,
        rejectionReason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? '${applicant.name} was approved.'
                : '${applicant.name} was rejected.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to review application: $error')),
      );
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Member Applications'),
        foregroundColor: primary,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<AppUserProfile>>(
        stream: _service.watchMembershipApplications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load applications.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final applications = snapshot.data!;
          final pendingCount = applications
              .where((item) => item.isMembershipPending)
              .length;
          final visible = _filter == 'all'
              ? applications
              : applications
                    .where((item) => item.membershipStatus == _filter)
                    .toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '$pendingCount pending application${pendingCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Verify applicant details before granting club member access.',
                style: TextStyle(color: Color(0xFF52677D)),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'pending', label: Text('Pending')),
                    ButtonSegment(value: 'approved', label: Text('Approved')),
                    ButtonSegment(value: 'rejected', label: Text('Rejected')),
                    ButtonSegment(value: 'all', label: Text('All')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (selection) {
                    setState(() => _filter = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (visible.isEmpty)
                const _EmptyApplications()
              else
                ...visible.map(
                  (applicant) => _ApplicationCard(
                    applicant: applicant,
                    busy: _busyUserId == applicant.uid,
                    onApprove: () => _approve(applicant),
                    onReject: () => _reject(applicant),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.applicant,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final AppUserProfile applicant;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final pending = applicant.isMembershipPending;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE1E8EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE7EEF7),
                  foregroundColor: const Color(0xFF003366),
                  child: Text(
                    applicant.name.isEmpty
                        ? '?'
                        : applicant.name[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: const TextStyle(
                          color: Color(0xFF003366),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        applicant.email,
                        style: const TextStyle(color: Color(0xFF52677D)),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(applicant.membershipStatus),
              ],
            ),
            const SizedBox(height: 16),
            _Detail(label: 'Matric number', value: applicant.matricNo),
            _Detail(label: 'Faculty', value: applicant.faculty),
            _Detail(label: 'Year of study', value: applicant.yearOfStudy),
            _Detail(
              label: 'Applied',
              value: applicant.createdAt == null
                  ? null
                  : _formatDate(applicant.createdAt!),
            ),
            if (applicant.rejectionReason != null) ...[
              const Divider(height: 24),
              Text(
                'Rejection reason: ${applicant.rejectionReason}',
                style: const TextStyle(color: Color(0xFF9B2C25)),
              ),
            ],
            if (pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB3261E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : onApprove,
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7C8E)),
            ),
          ),
          Expanded(
            child: Text(
              value?.trim().isNotEmpty == true ? value! : 'Not provided',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => const Color(0xFF16805B),
      'rejected' => const Color(0xFFB3261E),
      _ => const Color(0xFFE08A00),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 54, color: Color(0xFF8A9AAA)),
          SizedBox(height: 12),
          Text('No applications in this category.'),
        ],
      ),
    );
  }
}
