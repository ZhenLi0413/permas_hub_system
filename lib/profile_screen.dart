import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/app_user_profile.dart';
import 'models/event_item.dart';
import 'models/event_participation.dart';
import 'services/event_service.dart';
import 'services/participation_service.dart';
import 'services/user_profile_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primary = Color(0xFF003366);
  static const Color textSecondary = Color(0xFF5E6C80);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  void _showAvatarPicker(BuildContext context, String uid, String? currentPhotoUrl) {
    final profileService = UserProfileService();
    final customUrlController = TextEditingController(text: currentPhotoUrl);
    final avatars = [
      'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
      'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka',
      'https://api.dicebear.com/7.x/avataaars/png?seed=Jack',
      'https://api.dicebear.com/7.x/avataaars/png?seed=Sophia',
      'https://api.dicebear.com/7.x/avataaars/png?seed=Boots',
      'https://api.dicebear.com/7.x/avataaars/png?seed=Spooky',
      'https://api.dicebear.com/7.x/avataaars/png?seed=Luna',
      'https://api.dicebear.com/7.x/avataaars/png?seed=Oliver',
    ];

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Profile Picture'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select a built-in avatar:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 280,
                  height: 160,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: avatars.length,
                    itemBuilder: (context, index) {
                      final url = avatars[index];
                      final isSelected = currentPhotoUrl == url;
                      return GestureDetector(
                        onTap: () async {
                          Navigator.of(context).pop();
                          try {
                            await profileService.updatePhotoUrl(uid, url);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e')),
                              );
                            }
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? primary : Colors.transparent,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Or paste custom image URL:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: customUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/avatar.jpg',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final url = customUrlController.text.trim();
                Navigator.of(context).pop();
                try {
                  await profileService.updatePhotoUrl(uid, url);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                }
              },
              child: const Text('Save URL'),
            ),
          ],
        );
      },
    );
  }

  void _showEventsParticipated(BuildContext context, String userId) {
    final participationService = ParticipationService();
    final eventService = EventService();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StreamBuilder<List<EventItem>>(
          stream: eventService.watchEvents(),
          builder: (context, eventSnapshot) {
            final events = eventSnapshot.data ?? [];
            final eventMap = {for (final e in events) e.id: e};

            return StreamBuilder<List<EventParticipation>>(
              stream: participationService.watchUserParticipations(userId),
              builder: (context, partSnapshot) {
                if (partSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final participations = partSnapshot.data ?? [];
                if (participations.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note, size: 48, color: textSecondary),
                        SizedBox(height: 12),
                        Text(
                          'No Participated Events',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You have not registered for any events yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'PARTICIPATED EVENTS',
                          style: TextStyle(
                            color: primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: participations.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final part = participations[index];
                              final event = eventMap[part.eventId];
                              final title = event?.title ?? 'Unknown Event';
                              final dateStr = event != null
                                  ? '${event.date.day}/${event.date.month}/${event.date.year}'
                                  : 'N/A';

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primary,
                                  ),
                                ),
                                subtitle: Text(
                                  'Date: $dateStr',
                                  style: const TextStyle(color: textSecondary),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusBgColor(part.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    part.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusTextColor(part.status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, String uid, AppUserProfile? profile) {
    final profileService = UserProfileService();
    final nameController = TextEditingController(text: profile?.name);
    final matricController = TextEditingController(text: profile?.matricNo ?? '');
    final facultyController = TextEditingController(text: profile?.faculty ?? '');
    final yearController = TextEditingController(text: profile?.yearOfStudy ?? '');

    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile Details'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: matricController,
                    decoration: const InputDecoration(
                      labelText: 'Matric No',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Matric number is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: facultyController,
                    decoration: const InputDecoration(
                      labelText: 'Faculty',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Faculty is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: yearController,
                    decoration: const InputDecoration(
                      labelText: 'Year of Study',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Year 3',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Year of study is required.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop();
                try {
                  await profileService.updateProfileDetails(
                    uid: uid,
                    name: nameController.text,
                    matricNo: matricController.text,
                    faculty: facultyController.text,
                    yearOfStudy: yearController.text,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update profile: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'attended':
        return const Color(0xFFD2F6DC);
      case 'confirmed':
        return const Color(0xFFE3F2FD);
      case 'pending':
      default:
        return const Color(0xFFFFE9B7);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'attended':
        return const Color(0xFF1B5E20);
      case 'confirmed':
        return const Color(0xFF0D47A1);
      case 'pending':
      default:
        return const Color(0xFFE65100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profileService = UserProfileService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: user == null
          ? const Center(child: Text('No user signed in.'))
          : StreamBuilder<AppUserProfile?>(
              stream: profileService.watchProfile(user.uid),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final name = profile?.name.trim().isNotEmpty == true
                    ? profile!.name
                    : user.displayName ?? 'PERMAS Member';
                final email = profile?.email.trim().isNotEmpty == true
                    ? profile!.email
                    : user.email ?? 'No email available';
                final role = profile?.role ?? 'member';

                final hasPhoto = profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'PROFILE',
                        style: TextStyle(
                          color: primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: () => _showAvatarPicker(context, user.uid, profile?.photoUrl),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 54,
                                backgroundColor: primary.withValues(alpha: 0.1),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: primary,
                                  backgroundImage: hasPhoto
                                      ? NetworkImage(profile.photoUrl ?? '')
                                      : null,
                                  child: !hasPhoto
                                      ? Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 38,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: primary,
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.05),
                              blurRadius: 14,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileInfoRow(label: 'Name', value: name),
                            const SizedBox(height: 18),
                            _ProfileInfoRow(label: 'Matric No', value: profile?.matricNo ?? 'Not set'),
                            const SizedBox(height: 18),
                            _ProfileInfoRow(label: 'Faculty', value: profile?.faculty ?? 'Not set'),
                            const SizedBox(height: 18),
                            _ProfileInfoRow(label: 'Year of Study', value: profile?.yearOfStudy ?? 'Not set'),
                            const SizedBox(height: 18),
                            _ProfileInfoRow(label: 'Email', value: email),
                            const SizedBox(height: 18),
                            _ProfileInfoRow(
                              label: 'Role',
                              value: _displayRole(role),
                            ),
                            const SizedBox(height: 18),
                            _ProfileInfoRow(
                              label: 'Email Verification',
                              value: user.emailVerified
                                  ? 'Verified'
                                  : 'Pending',
                            ),
                            const SizedBox(height: 18),
                            _ProfileInfoRow(
                              label: 'Terms Accepted',
                              value: profile?.acceptedTerms == true
                                  ? 'Yes'
                                  : 'Not recorded',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _showEventsParticipated(context, user.uid),
                              icon: const Icon(Icons.event_available),
                              label: const Text(
                                'Event Participated',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFECEEF0),
                                foregroundColor: primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFFD0D8E1)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _showEditProfileDialog(context, user.uid, profile),
                              icon: const Icon(Icons.edit),
                              label: const Text(
                                'Edit Profile',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('LOGOUT'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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

  String _displayRole(String role) {
    if (role == 'admin') {
      return 'Admin';
    }
    if (role == 'committee') {
      return 'Committee';
    }
    return 'Member';
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5E6C80),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF10243A), fontSize: 14),
          ),
        ),
      ],
    );
  }
}
