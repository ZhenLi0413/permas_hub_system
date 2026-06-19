import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'models/app_user_profile.dart';
import 'services/user_profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PERMAS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (UserProfileService.isAdminEmail(user.email)) {
            return const DashboardScreen();
          }
          return StreamBuilder<AppUserProfile?>(
            stream: UserProfileService().watchProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting ||
                  !profileSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final profile = profileSnapshot.data!;
              if (profile.isMembershipApproved) {
                return const DashboardScreen();
              }
              return MembershipApplicationStatusScreen(profile: profile);
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class MembershipApplicationStatusScreen extends StatelessWidget {
  const MembershipApplicationStatusScreen({super.key, required this.profile});

  final AppUserProfile profile;

  @override
  Widget build(BuildContext context) {
    final rejected = profile.isMembershipRejected;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rejected ? Icons.cancel_outlined : Icons.hourglass_top,
                        size: 64,
                        color: rejected
                            ? const Color(0xFFB3261E)
                            : const Color(0xFFE08A00),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        rejected
                            ? 'Application not approved'
                            : 'Application under review',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF003366),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        rejected
                            ? 'Your PERMAS membership application was reviewed but could not be approved.'
                            : 'Thanks, ${profile.name}. A committee member will verify your application before access is granted.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF52677D),
                          height: 1.5,
                        ),
                      ),
                      if (rejected && profile.rejectionReason != null) ...[
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDEA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Reason: ${profile.rejectionReason}',
                            style: const TextStyle(color: Color(0xFF7D211B)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.logout),
                          label: const Text('SIGN OUT'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
