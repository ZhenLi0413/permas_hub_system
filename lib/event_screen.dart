import 'package:flutter/material.dart';

import 'models/app_user_profile.dart';
import 'models/event_item.dart';
import 'services/event_service.dart';

class EventsScreen extends StatefulWidget {
  EventsScreen({super.key, required this.profile, EventService? service})
    : service = service ?? EventService();

  final AppUserProfile? profile;
  final EventService service;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedType = 'all';
  EventSort _sort = EventSort.upcoming;

  bool get _isAdmin => widget.profile?.isAdmin ?? false;

  Future<void> _openEditor([EventItem? event]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventEditorScreen(
          service: widget.service,
          event: event,
          createdBy: widget.profile?.uid ?? '',
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
          isAdmin: _isAdmin,
          onEdit: () {
            Navigator.of(context).pop();
            _openEditor(event);
          },
          onDelete: () {
            Navigator.of(context).pop();
            _deleteEvent(event);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventItem>>(
      stream: widget.service.watchEvents(
        filterType: _selectedType,
        sort: _sort,
      ),
      builder: (context, snapshot) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _EventsHeader(
                  isAdmin: _isAdmin,
                  selectedType: _selectedType,
                  sort: _sort,
                  onTypeChanged: (type) {
                    setState(() => _selectedType = type);
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
            else if (snapshot.connectionState == ConnectionState.waiting &&
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
                  subtitle: _isAdmin
                      ? 'Create the first event for the PERMAS community.'
                      : 'New PERMAS events will appear here soon.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList.separated(
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final event = snapshot.data![index];
                    return _EventCard(
                      event: event,
                      isAdmin: _isAdmin,
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
  }
}

class _EventsHeader extends StatelessWidget {
  const _EventsHeader({
    required this.isAdmin,
    required this.selectedType,
    required this.sort,
    required this.onTypeChanged,
    required this.onSortChanged,
    required this.onAdd,
  });

  final bool isAdmin;
  final String selectedType;
  final EventSort sort;
  final ValueChanged<String> onTypeChanged;
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Events',
                    style: TextStyle(
                      color: Color(0xFF001E40),
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Discover, participate, and lead within the university community.',
                    style: TextStyle(
                      color: Color(0xFF4A5D72),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: 'Add event',
                onPressed: onAdd,
                icon: const Icon(Icons.add),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filters.entries.map((entry) {
            final selected = entry.key == selectedType;
            return ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onTypeChanged(entry.key),
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
  });

  final EventItem event;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = event.isUpcoming;

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
                      event.imagePath,
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
              Row(
                children: [
                  _Pill(
                    text: active ? 'Open' : 'Closed',
                    background: active
                        ? const Color(0xFFBAEAFF)
                        : const Color(0xFFECEEF0),
                    color: active
                        ? const Color(0xFF001E40)
                        : const Color(0xFF4A5D72),
                  ),
                  const Spacer(),
                  Text(
                    event.type.toUpperCase(),
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
              _IconLine(icon: Icons.location_on_outlined, text: event.location),
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
  });

  final EventItem event;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 180,
                child: Image.asset(
                  event.imagePath,
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
            Row(
              children: [
                _Pill(
                  text: event.type.toUpperCase(),
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
            _IconLine(icon: Icons.location_on_outlined, text: event.location),
            const SizedBox(height: 18),
            Text(
              event.description,
              style: const TextStyle(
                color: Color(0xFF4A5D72),
                fontSize: 15,
                height: 1.55,
              ),
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
  late final TextEditingController _locationController;
  late DateTime _date;
  late String _type;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _imagePathController = TextEditingController(
      text: event?.imagePath ?? 'assets/mountkinabalu.jpg',
    );
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _timeController = TextEditingController(text: event?.time ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _date = event?.date ?? DateTime.now();
    _type = event?.type ?? 'academic';
  }

  @override
  void dispose() {
    _imagePathController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    _locationController.dispose();
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
      location: _locationController.text.trim(),
      type: _type,
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
                  label: 'Image asset path',
                  hint: 'assets/mountkinabalu.jpg',
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
                  controller: _locationController,
                  label: 'Location',
                  hint: 'L50, UTM',
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: _formDecoration('Type'),
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
                      setState(() => _type = value);
                    }
                  },
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
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _formDecoration(label).copyWith(hintText: hint),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
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
