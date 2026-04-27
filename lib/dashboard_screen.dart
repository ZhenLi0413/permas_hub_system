import 'package:flutter/material.dart';

import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  static const Color primary = Color(0xFF003E7E);
  static const Color surface = Color(0xFFF5F8FB);
  static const Color pageBackground = Color(0xFFF9F4EA);
  static const Color accentYellow = Color(0xFFF9E8B8);
  static const Color accentRed = Color(0xFFF7D7D1);
  static const Color cardBackground = Color(0xFFFFFFFF);

  void _openProfilePage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? background,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: background ?? surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF2)),
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
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF5E6C80),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome, Ali.',
            style: TextStyle(
              color: primary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Your central PERMAS community command center.',
            style: TextStyle(
              color: Color(0xFF5E6C80),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            children: [
              _buildCard(
                icon: Icons.calendar_month,
                title: 'Events',
                subtitle: 'Stay synchronized with campus life and workshops.',
                background: accentYellow,
              ),
              _buildCard(
                icon: Icons.campaign,
                title: 'Announcements',
                subtitle: 'Official updates and institutional broadcasts.',
                background: accentRed,
              ),
              _buildCard(
                icon: Icons.description,
                title: 'Documents',
                subtitle: 'Academic transcripts, handbooks, and forms.',
                background: accentYellow,
              ),
              _buildCard(
                icon: Icons.photo_library,
                title: 'Gallery',
                subtitle: 'Explore photo highlights from campus life.',
                background: const Color(0xFFEDE9FF),
              ),
              _buildCard(
                icon: Icons.chat_bubble_outline,
                title: 'Feedback',
                subtitle: 'Send your ideas, queries, or suggestions.',
                background: const Color(0xFFF8F4EA),
              ),
              _buildCard(
                icon: Icons.support_agent,
                title: 'Hotline',
                subtitle: 'Emergency contacts and immediate help.',
                background: const Color(0xFFF7E7E5),
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
                  'RECENT ACTIVITY',
                  style: TextStyle(
                    color: Color(0xFF003E7E),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 18),
                _RecentActivityItem(
                  title: 'Graduation Requirements 2024.pdf',
                  subtitle: 'Updated 2 hours ago',
                  icon: Icons.file_present,
                ),
                const SizedBox(height: 16),
                _RecentActivityItem(
                  title: 'Annual Tech Symposium Registration',
                  subtitle: 'Ending tomorrow',
                  icon: Icons.event_available,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.calendar_month, size: 68, color: primary),
          SizedBox(height: 18),
          Text('Events', style: TextStyle(color: primary, fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('View upcoming campus activities and workshops.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5E6C80), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _newsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.campaign, size: 68, color: primary),
          SizedBox(height: 18),
          Text('News', style: TextStyle(color: primary, fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('Latest PERMAS news and important campus updates.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5E6C80), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _hotlineContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.support_agent, size: 68, color: primary),
          SizedBox(height: 18),
          Text('Hotline', style: TextStyle(color: primary, fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('Emergency contacts and instant support information.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5E6C80), fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.14,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/permas_logo.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'PERMAS',
                            style: TextStyle(
                              color: primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _openProfilePage,
                        icon: const CircleAvatar(
                          backgroundColor: primary,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedTab == 0
                      ? _dashboardContent()
                      : _selectedTab == 1
                          ? _eventsContent()
                          : _selectedTab == 2
                              ? _newsContent()
                              : _hotlineContent(),
                ),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Hotline'),
        ],
      ),
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  const _RecentActivityItem({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(16),
      ),
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
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF5E6C80)),
        ],
      ),
    );
  }
}
