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
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profileService = UserProfileService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Image.asset('assets/permas_logo.png', width: 30, height: 30),
            const SizedBox(width: 10),
            const Text(
              'PERMAS',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
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

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: primary,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
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


