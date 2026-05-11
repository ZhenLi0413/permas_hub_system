import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'announcement_screen.dart';
import 'event_screen.dart';
import 'models/app_user_profile.dart';
import 'profile_screen.dart';
import 'services/announcement_service.dart';
import 'services/event_service.dart';
import 'services/user_profile_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;
  bool _isRefreshingEmail = false;
  bool _isSendingVerification = false;

  final _profileService = UserProfileService();
  final _eventService = EventService();
  final _announcementService = AnnouncementService();

  static const Color primary = Color(0xFF003366);
  static const Color pageBackground = Color(0xFFF7F9FB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF4A5D72);

  @override
  void initState() {
    super.initState();
    _ensureStarterContent();
  }

  Future<void> _ensureStarterContent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !UserProfileService.isAdminEmail(user.email)) {
      return;
    }

    try {
      await Future.wait([
        _eventService.ensureStarterEvents(createdBy: user.uid),
        _announcementService.ensureStarterAnnouncements(createdBy: user.uid),
      ]);
    } catch (error, stackTrace) {
      debugPrint('Starter content seed failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _openProfilePage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  Future<void> _resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _isSendingVerification = true);
    try {
      await user.sendEmailVerification();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification email sent.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to send verification email: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingVerification = false);
      }
    }
  }

  Future<void> _refreshEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _isRefreshingEmail = true);
    try {
      await user.reload();
      if (!mounted) {
        return;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FirebaseAuth.instance.currentUser?.emailVerified == true
                ? 'Email verified.'
                : 'Email is still not verified.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to refresh verification: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshingEmail = false);
      }
    }
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE6F0)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8EFFF),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(icon, color: primary, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF10243A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardContent(AppUserProfile? profile) {
    final user = FirebaseAuth.instance.currentUser;
    final name = profile?.name.trim().isNotEmpty == true
        ? profile!.name
        : user?.displayName ?? 'PERMAS Member';
    final role = profile?.role ?? 'member';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome, $name.',
            style: const TextStyle(
              color: primary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            role == 'admin'
                ? 'Admin access is active for event and announcement management.'
                : 'Your central PERMAS community command center.',
            style: const TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 0.94,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            children: [
              _buildFeatureCard(
                icon: Icons.calendar_month,
                title: 'Events',
                subtitle: 'Browse academic, social, and career activities.',
                background: const Color(0xFFF9E8B8),
                onTap: () => setState(() => _selectedTab = 1),
              ),
              _buildFeatureCard(
                icon: Icons.campaign,
                title: 'Announcements',
                subtitle: 'Read official updates and urgent notices.',
                background: const Color(0xFFDDF5FF),
                onTap: () => setState(() => _selectedTab = 2),
              ),
              _buildFeatureCard(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'Review your PERMAS account information.',
                background: const Color(0xFFEDE9FF),
                onTap: _openProfilePage,
              ),
              _buildFeatureCard(
                icon: Icons.support_agent,
                title: 'Feedback',
                subtitle: 'Send ideas, questions, or support requests.',
                background: const Color(0xFFF7E7E5),
                onTap: () => setState(() => _selectedTab = 3),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5EAF2)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SPRINT 2 MODULES',
                  style: TextStyle(
                    color: primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 18),
                _RecentActivityItem(
                  title: 'Firestore Events Service',
                  subtitle:
                      'Image path, title, description, date, time, location, type.',
                  icon: Icons.event_available,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
                const SizedBox(height: 16),
                _RecentActivityItem(
                  title: 'Firestore Announcements Service',
                  subtitle: 'General and urgent announcements with admin CRUD.',
                  icon: Icons.campaign_outlined,
                  onTap: () => setState(() => _selectedTab = 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackContent() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 68, color: primary),
            SizedBox(height: 18),
            Text(
              'Feedback',
              style: TextStyle(
                color: primary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Feedback workflows can be connected in a later sprint.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentForTab(AppUserProfile? profile) {
    switch (_selectedTab) {
      case 1:
        return EventsScreen(profile: profile, service: _eventService);
      case 2:
        return AnnouncementsScreen(
          profile: profile,
          service: _announcementService,
        );
      case 3:
        return _feedbackContent();
      case 0:
      default:
        return _dashboardContent(profile);
    }
  }

  Widget _verificationBanner() {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = UserProfileService.isAdminEmail(user?.email);

    if (user == null || user.emailVerified || isAdmin) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE08A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email not verified',
            style: TextStyle(
              color: Color(0xFF6B4F00),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A verification link was sent to ${user.email}. You can keep using the app while you verify.',
            style: const TextStyle(
              color: Color(0xFF6B4F00),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isSendingVerification
                    ? null
                    : _resendVerificationEmail,
                icon: _isSendingVerification
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mark_email_read_outlined),
                label: const Text('Resend'),
              ),
              OutlinedButton.icon(
                onPressed: _isRefreshingEmail
                    ? null
                    : _refreshEmailVerification,
                icon: _isRefreshingEmail
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<AppUserProfile?>(
      stream: _profileService.watchProfile(user.uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return Scaffold(
          backgroundColor: pageBackground,
          body: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    'assets/mountkinabalu.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/permas_logo.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'PERMAS Hub',
                            style: TextStyle(
                              color: primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (profile?.isAdmin ?? false) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBAEAFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Color(0xFF001E40),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          IconButton(
                            tooltip: 'Profile',
                            onPressed: _openProfilePage,
                            icon: const CircleAvatar(
                              backgroundColor: primary,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _verificationBanner(),
                    Expanded(child: _contentForTab(profile)),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedTab,
            onTap: (index) => setState(() => _selectedTab = index),
            selectedItemColor: primary,
            unselectedItemColor: const Color(0xFF7A8A9C),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Events',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.campaign),
                label: 'Announcements',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.support_agent),
                label: 'Feedback',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  const _RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FBFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF003E7E)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF10243A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF5E6C80),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF5E6C80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


