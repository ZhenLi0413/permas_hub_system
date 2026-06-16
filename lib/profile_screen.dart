import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/app_user_profile.dart';
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
