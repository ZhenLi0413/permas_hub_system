import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/app_user_profile.dart';
import 'models/event_item.dart';
import 'models/event_participation.dart';
import 'services/event_service.dart';
import 'services/participation_service.dart';

class EventsScreen extends StatefulWidget {
  EventsScreen({super.key, required this.profile, EventService? service})
    : service = service ?? EventService();

  final AppUserProfile? profile;
  final EventService service;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedCategory = 'all';
  EventSort _sort = EventSort.upcoming;
  final _participationService = ParticipationService();

  bool get _canManageEvents => widget.profile?.canManageEvents ?? false;

  Future<void> _openEditor([EventItem? event]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventEditorScreen(
          service: widget.service,
          event: event,
          createdBy: widget.profile?.uid.isNotEmpty == true
              ? widget.profile!.uid
              : FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
      ),
    );
  }

  Future<void> _deleteEvent(EventItem event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete event?'),
          content: Text('This will permanently delete "${event.title}".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.service.deleteEvent(event.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Event deleted.')));
  }

  void _openDetails(EventItem event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _EventDetailsSheet(
          event: event,
          isAdmin: _canManageEvents,
          participationService: _participationService,
          userId: widget.profile?.uid.isNotEmpty == true
              ? widget.profile!.uid
              : FirebaseAuth.instance.currentUser?.uid ?? '',
          onEdit: () {
            Navigator.of(context).pop();
            _openEditor(event);
          },
          onDelete: () {
            Navigator.of(context).pop();
            _deleteEvent(event);
          },
          onRegister: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EventRegistrationScreen(
                  eventId: event.id,
                  userId: widget.profile?.uid.isNotEmpty == true
                      ? widget.profile!.uid
                      : FirebaseAuth.instance.currentUser?.uid ?? '',
                  participationService: _participationService,
                  registrationDueDate: event.registrationDueDate,
                ),
              ),
            );
          },
          onViewParticipants: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EventParticipantsScreen(
                  event: event,
                  participationService: _participationService,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.profile?.uid.isNotEmpty == true
        ? widget.profile!.uid
        : FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<EventParticipation>>(
      stream: _participationService.watchAllParticipations(),
      builder: (context, allParticipationSnapshot) {
        final allParticipations = allParticipationSnapshot.data ?? const [];
        final eventRegisteredCount = <String, int>{};
        for (final p in allParticipations) {
          eventRegisteredCount[p.eventId] =
              (eventRegisteredCount[p.eventId] ?? 0) + 1;
        }

        return StreamBuilder<List<EventParticipation>>(
          stream: _participationService.watchUserParticipations(userId),
          builder: (context, participationSnapshot) {
            final participations = participationSnapshot.data ?? const [];
            final statusMap = {
              for (var p in participations) p.eventId: p.status,
            };

            return StreamBuilder<List<EventItem>>(
              stream: widget.service.watchEvents(
                filterCategory: _selectedCategory,
                sort: _sort,
              ),
              builder: (context, snapshot) {
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: _EventsHeader(
                          isAdmin: _canManageEvents,
                          selectedCategory: _selectedCategory,
                          sort: _sort,
                          onCategoryChanged: (category) {
                            setState(() => _selectedCategory = category);
                          },
                          onSortChanged: (sort) {
                            setState(() => _sort = sort);
                          },
                          onAdd: () => _openEditor(),
                        ),
                      ),
                    ),
                    if (snapshot.hasError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _StateMessage(
                          icon: Icons.cloud_off,
                          title: 'Unable to load events',
                          subtitle: snapshot.error.toString(),
                        ),
                      )
                    else if (snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if ((snapshot.data ?? const <EventItem>[]).isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _StateMessage(
                          icon: Icons.event_busy,
                          title: 'No events yet',
                          subtitle: _canManageEvents
                              ? 'Create the first event for the PERMAS community.'
                              : 'New PERMAS events will appear here soon.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        sliver: SliverList.separated(
                          itemCount: snapshot.data!.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            final event = snapshot.data![index];
                            return _EventCard(
                              event: event,
                              isAdmin: _canManageEvents,
                              participationStatus: statusMap[event.id],
                              registeredCount:
                                  eventRegisteredCount[event.id] ?? 0,
                              onTap: () => _openDetails(event),
                              onEdit: () => _openEditor(event),
                              onDelete: () => _deleteEvent(event),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EventsHeader extends StatelessWidget {
  const _EventsHeader({
    required this.isAdmin,
    required this.selectedCategory,
    required this.sort,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onAdd,
  });

  final bool isAdmin;
  final String selectedCategory;
  final EventSort sort;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<EventSort> onSortChanged;
  final VoidCallback onAdd;

  static const _filters = <String, String>{
    'all': 'All',
    'academic': 'Academic',
    'social': 'Social',
    'career': 'Career',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'EVENTS',
          style: TextStyle(
            color: Color(0xFF001E40),
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Discover, participate, and lead within the university community.',
          style: TextStyle(color: Color(0xFF4A5D72), fontSize: 14, height: 1.5),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: onAdd,
              child: const Text('+ ADD NEW'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filters.entries.map((entry) {
            final selected = entry.key == selectedCategory;
            return ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onCategoryChanged(entry.key),
              selectedColor: const Color(0xFF003366),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF001E40),
                fontWeight: FontWeight.w800,
              ),
              backgroundColor: const Color(0xFFECEEF0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF003366)
                      : const Color(0xFFD0D8E1),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECEEF0).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0D8E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EventSort>(
                value: sort,
                icon: const Icon(Icons.keyboard_arrow_down),
                onChanged: (value) {
                  if (value != null) {
                    onSortChanged(value);
                  }
                },
                items: const [
                  DropdownMenuItem<EventSort>(
                    value: EventSort.upcoming,
                    child: Text('Sort by: Upcoming'),
                  ),
                  DropdownMenuItem<EventSort>(
                    value: EventSort.newest,
                    child: Text('Sort by: Newest'),
                  ),
                  DropdownMenuItem<EventSort>(
                    value: EventSort.oldest,
                    child: Text('Sort by: Oldest'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isAdmin,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.registeredCount,
    this.participationStatus,
  });

  final EventItem event;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int registeredCount;
  final String? participationStatus;

  @override
  Widget build(BuildContext context) {
    final active = event.isUpcoming && event.status == 'open';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFECEEF0)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 30, 64, 0.05),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (event.hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 160,
                    child: ColorFiltered(
                      colorFilter: active
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            )
                          : const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                      child: Image.asset(
                        event.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFECEEF0),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(0xFF4A5D72),
                              size: 42,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  _Pill(
                    text: event.status.toUpperCase(),
                    background: active
                        ? const Color(0xFFBAEAFF)
                        : const Color(0xFFECEEF0),
                    color: active
                        ? const Color(0xFF001E40)
                        : const Color(0xFF4A5D72),
                  ),
                  if (participationStatus != null) ...[
                    const SizedBox(width: 8),
                    _Pill(
                      text: participationStatus!.toUpperCase(),
                      background: _getStatusBgColor(participationStatus!),
                      color: _getStatusTextColor(participationStatus!),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    event.category.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF003366),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Edit event',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete event',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: TextStyle(
                  color: active
                      ? const Color(0xFF001E40)
                      : const Color(0xFF4A5D72),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              _IconLine(
                icon: Icons.calendar_today,
                text: '${formatDisplayDate(event.date)} - ${event.time}',
              ),
              const SizedBox(height: 8),
              _IconLine(icon: Icons.location_on_outlined, text: event.venue),
              const SizedBox(height: 8),
              _IconLine(
                icon: Icons.how_to_reg_outlined,
                text:
                    'Register by ${formatDisplayDate(event.registrationDueDate)}',
              ),
              const SizedBox(height: 10),
              if (event.capacity != null) ...[
                Text(
                  'Participants: $registeredCount / ${event.capacity}',
                  style: const TextStyle(
                    color: Color(0xFF4A5D72),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                Text(
                  'Participants: $registeredCount',
                  style: const TextStyle(
                    color: Color(0xFF4A5D72),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capacity: Unlimited',
                  style: const TextStyle(
                    color: Color(0xFF4A5D72),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailsSheet extends StatelessWidget {
  const _EventDetailsSheet({
    required this.event,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.participationService,
    required this.userId,
    required this.onRegister,
    required this.onViewParticipants,
  });

  final EventItem event;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ParticipationService participationService;
  final String userId;
  final VoidCallback onRegister;
  final VoidCallback onViewParticipants;

  Future<void> _markAsAttended(BuildContext context, String docId) async {
    try {
      await participationService.updateStatus(docId, 'attended');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your attendance has been recorded.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (event.hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 180,
                  child: Image.asset(
                    event.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFECEEF0),
                        child: const Icon(Icons.image_outlined, size: 48),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            Row(
              children: [
                _Pill(
                  text: event.category.toUpperCase(),
                  background: const Color(0xFF003366),
                  color: Colors.white,
                ),
                const Spacer(),
                if (isAdmin) ...[
                  IconButton(
                    tooltip: 'Edit event',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete event',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: const TextStyle(
                color: Color(0xFF001E40),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            _IconLine(
              icon: Icons.calendar_today,
              text: '${formatDisplayDate(event.date)} - ${event.time}',
            ),
            const SizedBox(height: 8),
            _IconLine(icon: Icons.location_on_outlined, text: event.venue),
            const SizedBox(height: 8),
            _IconLine(
              icon: Icons.how_to_reg_outlined,
              text:
                  'Register by ${formatDisplayDate(event.registrationDueDate)}',
            ),
            const SizedBox(height: 8),
            _IconLine(
              icon: Icons.info_outline,
              text: event.status.toUpperCase(),
            ),
            const SizedBox(height: 18),
            Text(
              event.description,
              style: const TextStyle(
                color: Color(0xFF4A5D72),
                fontSize: 15,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<EventParticipation>>(
              stream: participationService.watchEventParticipations(event.id),
              builder: (context, participantsSnapshot) {
                final participants = participantsSnapshot.data ?? const [];
                final pendingCount = participants
                    .where((p) => p.status == 'pending')
                    .length;
                final confirmedCount = participants
                    .where((p) => p.status == 'confirmed')
                    .length;
                final attendedCount = participants
                    .where((p) => p.status == 'attended')
                    .length;
                final registeredCount = participants.length;
                final hasLimitedCapacity =
                    event.capacity != null && event.capacity! > 0;
                final capacityLabel = event.capacity?.toString() ?? 'Unlimited';
                final occupancyRate = hasLimitedCapacity
                    ? ((registeredCount / event.capacity!) * 100)
                          .clamp(0, 100)
                          .round()
                    : 0;
                final attendanceRate = confirmedCount > 0
                    ? ((attendedCount / confirmedCount) * 100).round()
                    : 0;
                final isDeadlinePassed = DateTime.now().isAfter(
                  event.registrationDueDate,
                );
                final isOpen = event.status == 'open' && !isDeadlinePassed;
                final isFull =
                    hasLimitedCapacity && confirmedCount >= event.capacity!;
                final canRegister = isOpen && !isFull;
                final registerButtonLabel = isFull
                    ? 'EVENT FULL'
                    : isDeadlinePassed
                    ? 'REGISTRATION CLOSED (DEADLINE PASSED)'
                    : isOpen
                    ? 'REGISTER FOR EVENT'
                    : 'REGISTRATION CLOSED';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFECEEF0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            hasLimitedCapacity
                                ? 'Registered: $registeredCount / ${event.capacity}'
                                : 'Registered: $registeredCount',
                            style: const TextStyle(
                              color: Color(0xFF001E40),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Capacity: $capacityLabel',
                            style: const TextStyle(
                              color: Color(0xFF4A5D72),
                              fontSize: 13,
                            ),
                          ),
                          if (hasLimitedCapacity) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Occupancy Rate: $occupancyRate%',
                              style: const TextStyle(
                                color: Color(0xFF4A5D72),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: occupancyRate / 100.0,
                              color: const Color(0xFF003366),
                              backgroundColor: const Color(0xFFECEEF0),
                              minHeight: 8,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFECEEF0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 30, 64, 0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Event Analytics',
                              style: TextStyle(
                                color: Color(0xFF001E40),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(label: 'Capacity', value: capacityLabel),
                            const SizedBox(height: 8),
                            _DetailRow(
                              label: 'Registered',
                              value: registeredCount.toString(),
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
                              label: 'Pending',
                              value: pendingCount.toString(),
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
                              label: 'Confirmed',
                              value: confirmedCount.toString(),
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
                              label: 'Attended',
                              value: attendedCount.toString(),
                            ),
                            if (hasLimitedCapacity) ...[
                              const SizedBox(height: 16),
                              _DetailRow(
                                label: 'Occupancy Rate',
                                value: '$occupancyRate%',
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: occupancyRate / 100.0,
                                color: const Color(0xFF003366),
                                backgroundColor: const Color(0xFFECEEF0),
                                minHeight: 8,
                              ),
                            ],
                            const SizedBox(height: 16),
                            _DetailRow(
                              label: 'Attendance Rate',
                              value: '$attendanceRate%',
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: attendanceRate / 100.0,
                              color: const Color(0xFF0F8554),
                              backgroundColor: const Color(0xFFECEEF0),
                              minHeight: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (!isAdmin) ...[
                      StreamBuilder<EventParticipation?>(
                        stream: participationService.watchParticipation(
                          event.id,
                          userId,
                        ),
                        builder: (context, snapshot) {
                          final participation = snapshot.data;
                          if (participation == null) {
                            return SizedBox(
                              height: 50,
                              child: FilledButton.icon(
                                onPressed: canRegister ? onRegister : null,
                                icon: const Icon(Icons.assignment_outlined),
                                label: Text(registerButtonLabel),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4F8),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFD0D8E1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'YOUR PARTICIPATION',
                                          style: TextStyle(
                                            color: Color(0xFF001E40),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Spacer(),
                                        _Pill(
                                          text: participation.status
                                              .toUpperCase(),
                                          background: _getStatusBgColor(
                                            participation.status,
                                          ),
                                          color: _getStatusTextColor(
                                            participation.status,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      height: 24,
                                      color: Color(0xFFD0D8E1),
                                    ),
                                    _DetailRow(
                                      label: 'Full Name',
                                      value: participation.fullName,
                                    ),
                                    const SizedBox(height: 8),
                                    _DetailRow(
                                      label: 'Faculty',
                                      value: participation.faculty,
                                    ),
                                    const SizedBox(height: 8),
                                    _DetailRow(
                                      label: 'Matric No.',
                                      value: participation.matricNumber,
                                    ),
                                    const SizedBox(height: 8),
                                    _DetailRow(
                                      label: 'College',
                                      value: participation.college,
                                    ),
                                    const SizedBox(height: 8),
                                    _DetailRow(
                                      label: 'Course/Program',
                                      value: participation.courseProgram,
                                    ),
                                    const SizedBox(height: 8),
                                    _DetailRow(
                                      label: 'Semester',
                                      value: participation.semester,
                                    ),
                                    const SizedBox(height: 8),
                                    _DetailRow(
                                      label: 'Phone Number',
                                      value: participation.phoneNumber,
                                    ),
                                    const SizedBox(height: 8),
                                    _DetailRow(
                                      label: 'Emergency Contact',
                                      value: participation.emergencyContact,
                                    ),
                                    const SizedBox(height: 8),
                                    _DetailRow(
                                      label: 'Dietary Restrictions',
                                      value: participation.dietaryRestrictions,
                                    ),
                                  ],
                                ),
                              ),
                              if (participation.status == 'confirmed') ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 50,
                                  child: FilledButton.icon(
                                    onPressed: () => _markAsAttended(
                                      context,
                                      participation.id,
                                    ),
                                    icon: const Icon(
                                      Icons.assignment_turned_in_outlined,
                                    ),
                                    label: const Text('MARK AS ATTENDED'),
                                  ),
                                ),
                              ] else if (participation.status ==
                                  'attended') ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4EDDA),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Thank you! Your attendance has been recorded.',
                                    style: TextStyle(
                                      color: Color(0xFF155724),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: onViewParticipants,
                          icon: const Icon(Icons.people_outline),
                          label: const Text('VIEW PARTICIPANTS'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EventEditorScreen extends StatefulWidget {
  const EventEditorScreen({
    super.key,
    required this.service,
    required this.createdBy,
    this.event,
  });

  final EventService service;
  final String createdBy;
  final EventItem? event;

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _imagePathController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _timeController;
  late final TextEditingController _venueController;
  late final TextEditingController _capacityController;
  late DateTime _date;
  late DateTime _registrationDueDate;
  late String _category;
  late String _status;
  bool _isSaving = false;
  bool _unlimitedParticipants = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _imagePathController = TextEditingController(text: event?.imagePath ?? '');
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _timeController = TextEditingController(text: event?.time ?? '');
    _venueController = TextEditingController(text: event?.venue ?? '');
    _capacityController = TextEditingController(
      text: event?.capacity?.toString() ?? '50',
    );
    _unlimitedParticipants = event?.capacity == null;
    _date = event?.date ?? DateTime.now();
    _registrationDueDate = event?.registrationDueDate ?? DateTime.now();
    _category = event?.category ?? 'academic';
    _status = event?.status ?? 'open';
  }

  @override
  void dispose() {
    _imagePathController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _date = picked);
  }

  Future<void> _pickRegistrationDueDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _registrationDueDate,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _registrationDueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final event = EventItem(
      id: widget.event?.id ?? '',
      imagePath: _imagePathController.text.trim(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _date,
      time: _timeController.text.trim(),
      venue: _venueController.text.trim(),
      category: _category,
      status: _status,
      capacity: _unlimitedParticipants
          ? null
          : int.parse(_capacityController.text.trim()),
      registrationDueDate: _registrationDueDate,
      createdBy: widget.event?.createdBy ?? widget.createdBy,
      createdAt: widget.event?.createdAt,
      updatedAt: widget.event?.updatedAt,
    );

    try {
      await widget.service.saveEvent(event, createdBy: widget.createdBy);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.event == null ? 'Event created.' : 'Event saved.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save event: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        elevation: 0,
        title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EditorField(
                  controller: _imagePathController,
                  label: 'Image asset path (optional)',
                  hint: 'assets/mountkinabalu.jpg',
                  isRequired: false,
                ),
                const SizedBox(height: 14),
                _EditorField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'Event title',
                ),
                const SizedBox(height: 14),
                _EditorField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Event description',
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(formatIsoDate(_date)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _EditorField(
                        controller: _timeController,
                        label: 'Time',
                        hint: '10:00 AM',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _EditorField(
                  controller: _venueController,
                  label: 'Venue',
                  hint: 'L50, UTM',
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: _formDecoration('Category'),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'academic',
                      child: Text('Academic'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'social',
                      child: Text('Social'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'career',
                      child: Text('Career'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  value: _unlimitedParticipants,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _unlimitedParticipants = value);
                  },
                  title: const Text('Unlimited Participants'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_unlimitedParticipants) ...[
                  const SizedBox(height: 14),
                  _EditorField(
                    controller: _capacityController,
                    label: 'Maximum Participants',
                    hint: '50',
                    keyboardType: TextInputType.number,
                    enabled: !_unlimitedParticipants,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Maximum Participants is required.';
                      }
                      final capacity = int.tryParse(value.trim());
                      if (capacity == null || capacity < 1) {
                        return 'Enter a valid number (minimum 1).';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: _formDecoration('Status'),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'open',
                      child: Text('Open'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'closed',
                      child: Text('Closed'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickRegistrationDueDate,
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: Text(
                    'Registration due: ${formatIsoDate(_registrationDueDate)}',
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('SAVE EVENT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isRequired = true,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isRequired;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: _formDecoration(label).copyWith(hintText: hint),
      validator:
          validator ??
          (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return '$label is required.';
            }
            return null;
          },
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF003366), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4A5D72),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.color,
  });

  final String text;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFF003366)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF001E40),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4A5D72),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _formDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD0D8E1)),
    ),
  );
}

String formatIsoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String formatDisplayDate(DateTime date) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

Color _getStatusBgColor(String status) {
  switch (status) {
    case 'pending':
      return const Color(0xFFFFF3CD);
    case 'confirmed':
      return const Color(0xFFD1ECF1);
    case 'attended':
      return const Color(0xFFD4EDDA);
    default:
      return const Color(0xFFECEEF0);
  }
}

Color _getStatusTextColor(String status) {
  switch (status) {
    case 'pending':
      return const Color(0xFF856404);
    case 'confirmed':
      return const Color(0xFF0C5460);
    case 'attended':
      return const Color(0xFF155724);
    default:
      return const Color(0xFF4A5D72);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A8A9C),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF001E40),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class EventRegistrationScreen extends StatefulWidget {
  const EventRegistrationScreen({
    super.key,
    required this.eventId,
    required this.userId,
    required this.participationService,
    required this.registrationDueDate,
  });

  final String eventId;
  final String userId;
  final ParticipationService participationService;
  final DateTime registrationDueDate;

  @override
  State<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _facultyController = TextEditingController();
  final _matricNumberController = TextEditingController();
  final _collegeController = TextEditingController();
  final _courseProgramController = TextEditingController();
  final _semesterController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _dietaryRestrictionsController = TextEditingController();
  bool _isSubmitting = false;
  bool _agreedToTerms = false;
  bool _consentToMedia = false;
  bool _showConsentValidation = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _facultyController.dispose();
    _matricNumberController.dispose();
    _collegeController.dispose();
    _courseProgramController.dispose();
    _semesterController.dispose();
    _phoneNumberController.dispose();
    _emergencyContactController.dispose();
    _dietaryRestrictionsController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String? _phoneValidator(String label, String? value) {
    final requiredError = _requiredValidator(label, value);
    if (requiredError != null) {
      return requiredError;
    }
    final normalized = value!.replaceAll(RegExp(r'[^0-9+]'), '');
    final isValid = RegExp(r'^\+?[0-9]{9,15}$').hasMatch(normalized);
    if (!isValid) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (DateTime.now().isAfter(widget.registrationDueDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration deadline has passed.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms || !_consentToMedia) {
      setState(() => _showConsentValidation = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide all required consents before submitting.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.participationService.register(
        eventId: widget.eventId,
        userId: widget.userId,
        fullName: _fullNameController.text,
        faculty: _facultyController.text,
        matricNumber: _matricNumberController.text,
        college: _collegeController.text,
        courseProgram: _courseProgramController.text,
        semester: _semesterController.text,
        phoneNumber: _phoneNumberController.text,
        emergencyContact: _emergencyContactController.text,
        dietaryRestrictions: _dietaryRestrictionsController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration submitted. Status is pending.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);

    final isClosed = DateTime.now().isAfter(widget.registrationDueDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        elevation: 0,
        title: const Text('Event Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join Activity',
                  style: TextStyle(
                    color: Color(0xFF001E40),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Registration closes on: '
                  '${widget.registrationDueDate.day}/'
                  '${widget.registrationDueDate.month}/'
                  '${widget.registrationDueDate.year}',
                  style: const TextStyle(
                    color: Color(0xFFFF0000),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Please fill in your correct information to participate in this club activity.',
                  style: TextStyle(color: Color(0xFF4A5D72), fontSize: 14),
                ),
                const SizedBox(height: 24),
                _RegistrationField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                ),
                const SizedBox(height: 16),
                _RegistrationField(
                  controller: _facultyController,
                  label: 'Faculty',
                  hint: 'e.g. Faculty of Computing',
                ),
                const SizedBox(height: 16),
                _RegistrationField(
                  controller: _matricNumberController,
                  label: 'Matric Number',
                  hint: 'e.g. A21CS0001',
                ),
                const SizedBox(height: 16),
                _RegistrationField(
                  controller: _collegeController,
                  label: 'College',
                  hint: 'e.g. Kolej Tun Razak',
                ),
                const SizedBox(height: 16),
                _RegistrationField(
                  controller: _courseProgramController,
                  label: 'Course/Program',
                  hint: 'e.g. Bachelor of Computer Science',
                ),
                const SizedBox(height: 16),
                _RegistrationField(
                  controller: _semesterController,
                  label: 'Semester',
                  hint: 'e.g. Semester 6',
                ),
                const SizedBox(height: 16),
                _RegistrationField(
                  controller: _phoneNumberController,
                  label: 'Phone Number',
                  hint: 'e.g. +60123456789',
                  keyboardType: TextInputType.phone,
                  validator: (value) => _phoneValidator('Phone Number', value),
                ),
                const SizedBox(height: 16),
                _RegistrationField(
                  controller: _emergencyContactController,
                  label: 'Emergency Contact',
                  hint: 'Name and phone number',
                ),
                const SizedBox(height: 16),
                _RegistrationField(
                  controller: _dietaryRestrictionsController,
                  label: 'Dietary Restrictions',
                  hint: 'e.g. Vegetarian / None',
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _showConsentValidation &&
                              (!_agreedToTerms || !_consentToMedia)
                          ? Colors.red
                          : const Color(0xFFD0D8E1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                            if (_agreedToTerms && _consentToMedia) {
                              _showConsentValidation = false;
                            }
                          });
                        },
                        title: const Text(
                          'I agree to the event terms and conditions.',
                          style: TextStyle(
                            color: Color(0xFF001E40),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _consentToMedia,
                        onChanged: (value) {
                          setState(() {
                            _consentToMedia = value ?? false;
                            if (_agreedToTerms && _consentToMedia) {
                              _showConsentValidation = false;
                            }
                          });
                        },
                        title: const Text(
                          'I consent to photos/videos being taken during the event.',
                          style: TextStyle(
                            color: Color(0xFF001E40),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_showConsentValidation &&
                          (!_agreedToTerms || !_consentToMedia))
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Both consent checkboxes are required.',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: (_isSubmitting || isClosed) ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isClosed
                                ? 'REGISTRATION CLOSED'
                                : 'SUBMIT REGISTRATION',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationField extends StatelessWidget {
  const _RegistrationField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _formDecoration(label).copyWith(hintText: hint),
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required.';
            }
            return null;
          },
    );
  }
}

class EventParticipantsScreen extends StatefulWidget {
  const EventParticipantsScreen({
    super.key,
    required this.event,
    required this.participationService,
  });

  final EventItem event;
  final ParticipationService participationService;

  @override
  State<EventParticipantsScreen> createState() =>
      _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  Future<void> _updateStatus(String docId, String status) async {
    try {
      await widget.participationService.updateStatus(docId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Participant marked as $status.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  Future<void> _deleteParticipant(
    BuildContext context,
    String docId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove participant?'),
          content: Text(
            'Are you sure you want to remove "$name" from this event?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await widget.participationService.deleteParticipation(docId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Participant removed.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove participant: $e')),
      );
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleParticipantSelection(String docId) {
    setState(() {
      if (!_selectedIds.add(docId)) {
        _selectedIds.remove(docId);
      }
    });
  }

  void _toggleSelectAll(List<EventParticipation> participants) {
    setState(() {
      final allIds = participants.map((participant) => participant.id).toSet();
      if (_selectedIds.length == allIds.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(allIds);
      }
    });
  }

  Future<void> _batchApprove(List<EventParticipation> participants) async {
    final selectedPending = participants.where(
      (participant) =>
          _selectedIds.contains(participant.id) &&
          participant.status == 'pending',
    );

    if (selectedPending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending requests selected to approve.'),
        ),
      );
      return;
    }

    try {
      await Future.wait(
        selectedPending.map(
          (participant) => widget.participationService.updateStatus(
            participant.id,
            'confirmed',
          ),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedPending.length} request(s) approved.'),
        ),
      );
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve selected participants: $e')),
      );
    }
  }

  Future<void> _batchDelete(List<EventParticipation> participants) async {
    final selectedParticipants = participants
        .where((participant) => _selectedIds.contains(participant.id))
        .toList();
    if (selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No participants selected to remove.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove selected participants?'),
          content: Text(
            'Are you sure you want to remove ${selectedParticipants.length} selected participant(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await Future.wait(
        selectedParticipants.map(
          (participant) =>
              widget.participationService.deleteParticipation(participant.id),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selectedParticipants.length} participant(s) removed.',
          ),
        ),
      );
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove selected participants: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        elevation: 0,
        title: const Text('Participants List'),
        actions: [
          if (!_selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _toggleSelectionMode,
                icon: const Icon(
                  Icons.check_box_outline_blank,
                  color: Color(0xFF003366),
                ),
                label: const Text(
                  'Select',
                  style: TextStyle(color: Color(0xFF003366)),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Cancel selection',
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      color: Color(0xFF001E40),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage registered participants for this event.',
                    style: TextStyle(color: Color(0xFF4A5D72), fontSize: 14),
                  ),
                ],
              ),
            ),
            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFECEEF0)),
                  ),
                  child: Text(
                    '${_selectedIds.length} selected',
                    style: const TextStyle(
                      color: Color(0xFF001E40),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: StreamBuilder<List<EventParticipation>>(
                stream: widget.participationService.watchEventParticipations(
                  widget.event.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _StateMessage(
                      icon: Icons.error_outline,
                      title: 'Error loading participants',
                      subtitle: snapshot.error.toString(),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return const _StateMessage(
                      icon: Icons.people_outline,
                      title: 'No participants yet',
                      subtitle:
                          'When students register, they will appear here.',
                    );
                  }

                  return Column(
                    children: [
                      if (_selectionMode)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => _toggleSelectAll(list),
                                icon: Icon(
                                  _selectedIds.length == list.length
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: const Color(0xFF003366),
                                ),
                                label: Text(
                                  _selectedIds.length == list.length
                                      ? 'Deselect All'
                                      : 'Select All',
                                  style: const TextStyle(
                                    color: Color(0xFF003366),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Approve selected',
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                                onPressed: _selectedIds.isNotEmpty
                                    ? () => _batchApprove(list)
                                    : null,
                              ),
                              IconButton(
                                tooltip: 'Delete selected',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: _selectedIds.isNotEmpty
                                    ? () => _batchDelete(list)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final p = list[index];
                            final isSelected = _selectedIds.contains(p.id);
                            return InkWell(
                              onTap: _selectionMode
                                  ? () => _toggleParticipantSelection(p.id)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFECEEF0),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 30, 64, 0.03),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    if (_selectionMode) ...[
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (_) =>
                                            _toggleParticipantSelection(p.id),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.fullName,
                                            style: const TextStyle(
                                              color: Color(0xFF001E40),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Matric: ${p.matricNumber} • ${p.college}',
                                            style: const TextStyle(
                                              color: Color(0xFF4A5D72),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            p.faculty,
                                            style: const TextStyle(
                                              color: Color(0xFF4A5D72),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${p.courseProgram} • ${p.semester}',
                                            style: const TextStyle(
                                              color: Color(0xFF4A5D72),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Phone: ${p.phoneNumber}',
                                            style: const TextStyle(
                                              color: Color(0xFF4A5D72),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Emergency: ${p.emergencyContact}',
                                            style: const TextStyle(
                                              color: Color(0xFF4A5D72),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Dietary: ${p.dietaryRestrictions}',
                                            style: const TextStyle(
                                              color: Color(0xFF4A5D72),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _Pill(
                                            text: p.status.toUpperCase(),
                                            background: _getStatusBgColor(
                                              p.status,
                                            ),
                                            color: _getStatusTextColor(
                                              p.status,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        if (p.status == 'pending')
                                          IconButton(
                                            tooltip: 'Approve',
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.green,
                                            ),
                                            onPressed: () => _updateStatus(
                                              p.id,
                                              'confirmed',
                                            ),
                                          ),
                                        IconButton(
                                          tooltip: 'Delete / Remove',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _deleteParticipant(
                                            context,
                                            p.id,
                                            p.fullName,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
