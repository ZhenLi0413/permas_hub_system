import 'package:flutter/material.dart';

import 'models/announcement_item.dart';
import 'models/app_user_profile.dart';
import 'services/announcement_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  AnnouncementsScreen({
    super.key,
    required this.profile,
    AnnouncementService? service,
  }) : service = service ?? AnnouncementService();

  final AppUserProfile? profile;
  final AnnouncementService service;

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  bool get _isAdmin => widget.profile?.isAdmin ?? false;

  Future<void> _openEditor([AnnouncementItem? announcement]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnnouncementEditorScreen(
          service: widget.service,
          announcement: announcement,
          createdBy: widget.profile?.uid ?? '',
        ),
      ),
    );
  }

  Future<void> _deleteAnnouncement(AnnouncementItem announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete announcement?'),
          content: Text(
            'This will permanently delete "${announcement.title}".',
          ),
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

    await widget.service.deleteAnnouncement(announcement.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Announcement deleted.')));
  }

  void _openDetails(AnnouncementItem announcement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _AnnouncementDetailsSheet(
          announcement: announcement,
          isAdmin: _isAdmin,
          onEdit: () {
            Navigator.of(context).pop();
            _openEditor(announcement);
          },
          onDelete: () {
            Navigator.of(context).pop();
            _deleteAnnouncement(announcement);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AnnouncementItem>>(
      stream: widget.service.watchAnnouncements(),
      builder: (context, snapshot) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _AnnouncementsHeader(
                  isAdmin: _isAdmin,
                  onAdd: () => _openEditor(),
                ),
              ),
            ),
            if (snapshot.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _StateMessage(
                  icon: Icons.cloud_off,
                  title: 'Unable to load announcements',
                  subtitle: snapshot.error.toString(),
                ),
              )
            else if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if ((snapshot.data ?? const <AnnouncementItem>[]).isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _StateMessage(
                  icon: Icons.campaign_outlined,
                  title: 'No announcements yet',
                  subtitle: _isAdmin
                      ? 'Create the first update for PERMAS members.'
                      : 'Official PERMAS updates will appear here soon.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList.separated(
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final announcement = snapshot.data![index];
                    return _AnnouncementCard(
                      announcement: announcement,
                      isAdmin: _isAdmin,
                      onTap: () => _openDetails(announcement),
                      onEdit: () => _openEditor(announcement),
                      onDelete: () => _deleteAnnouncement(announcement),
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

class _AnnouncementsHeader extends StatelessWidget {
  const _AnnouncementsHeader({required this.isAdmin, required this.onAdd});

  final bool isAdmin;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Announcements',
                style: TextStyle(
                  color: Color(0xFF001E40),
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'The latest updates, official news, and essential briefings from PERMAS.',
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
            tooltip: 'Add announcement',
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ],
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.isAdmin,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final AnnouncementItem announcement;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final urgent = announcement.isUrgent;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: SizedBox(
                  height: 170,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        announcement.imagePath,
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
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(0, 30, 64, 0.02),
                              Color.fromRGBO(0, 30, 64, 0.58),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _Pill(
                                  text: announcement.type.toUpperCase(),
                                  background: urgent
                                      ? const Color(0xFF003366)
                                      : const Color(0xFFBAEAFF),
                                  color: urgent
                                      ? Colors.white
                                      : const Color(0xFF001E40),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    formatDisplayDate(announcement.date),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              announcement.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAdmin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit announcement',
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete announcement',
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      announcement.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4A5D72),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementDetailsSheet extends StatelessWidget {
  const _AnnouncementDetailsSheet({
    required this.announcement,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  final AnnouncementItem announcement;
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
                  announcement.imagePath,
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
                  text: announcement.type.toUpperCase(),
                  background: announcement.isUrgent
                      ? const Color(0xFF003366)
                      : const Color(0xFFECEEF0),
                  color: announcement.isUrgent
                      ? Colors.white
                      : const Color(0xFF003366),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    formatDisplayDate(announcement.date),
                    style: const TextStyle(
                      color: Color(0xFF7D8B9A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isAdmin) ...[
                  IconButton(
                    tooltip: 'Edit announcement',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete announcement',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text(
              announcement.title,
              style: const TextStyle(
                color: Color(0xFF001E40),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              announcement.content,
              style: const TextStyle(
                color: Color(0xFF4A5D72),
                fontSize: 15,
                height: 1.58,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnnouncementEditorScreen extends StatefulWidget {
  const AnnouncementEditorScreen({
    super.key,
    required this.service,
    required this.createdBy,
    this.announcement,
  });

  final AnnouncementService service;
  final String createdBy;
  final AnnouncementItem? announcement;

  @override
  State<AnnouncementEditorScreen> createState() =>
      _AnnouncementEditorScreenState();
}

class _AnnouncementEditorScreenState extends State<AnnouncementEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _imagePathController;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DateTime _date;
  late String _type;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final announcement = widget.announcement;
    _imagePathController = TextEditingController(
      text: announcement?.imagePath ?? AnnouncementItem.defaultImagePath,
    );
    _titleController = TextEditingController(text: announcement?.title ?? '');
    _contentController = TextEditingController(
      text: announcement?.content ?? '',
    );
    _date = announcement?.date ?? DateTime.now();
    _type = announcement?.type ?? 'general';
  }

  @override
  void dispose() {
    _imagePathController.dispose();
    _titleController.dispose();
    _contentController.dispose();
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

    final announcement = AnnouncementItem(
      id: widget.announcement?.id ?? '',
      imagePath: _imagePathController.text.trim(),
      type: _type,
      date: _date,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdBy: widget.announcement?.createdBy ?? widget.createdBy,
      createdAt: widget.announcement?.createdAt,
      updatedAt: widget.announcement?.updatedAt,
    );

    try {
      await widget.service.saveAnnouncement(
        announcement,
        createdBy: widget.createdBy,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.announcement == null
                ? 'Announcement created.'
                : 'Announcement saved.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save announcement: $error')),
      );
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
        title: Text(
          widget.announcement == null
              ? 'Add Announcement'
              : 'Edit Announcement',
        ),
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
                  hint: AnnouncementItem.defaultImagePath,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: _formDecoration('Type'),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'general',
                      child: Text('General'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'urgent',
                      child: Text('Urgent'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(formatIsoDate(_date)),
                ),
                const SizedBox(height: 14),
                _EditorField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'Announcement title',
                ),
                const SizedBox(height: 14),
                _EditorField(
                  controller: _contentController,
                  label: 'Content',
                  hint: 'Announcement content',
                  maxLines: 6,
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
                    label: const Text('SAVE ANNOUNCEMENT'),
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
