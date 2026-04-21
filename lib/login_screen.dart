import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _roles = const ['Public User', 'Admin', 'Staff'];
  String _selectedRole = 'Public User';
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isEmailLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      String message = 'Login failed. Please try again.';
      if (error.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (error.code == 'user-not-found' ||
          error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        message = 'Wrong email or password.';
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isEmailLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${error.message ?? error.code}')),
      );
    } catch (error, stackTrace) {
      debugPrint('Google sign-in error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003E7E);
    const title = Color(0xFF002F63);
    const bg = Color(0xFFEFF3F8);
    const panel = Color(0xFFF7FAFD);
    const label = Color(0xFF5E6C80);
    const border = Color(0xFFD7DFE8);
    const fieldBg = Color(0xFFF1F4F8);

    final bool isAnyLoading = _isEmailLoading || _isGoogleLoading;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7E0EB)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 90,
                      child: Opacity(
                        opacity: 0.14,
                        child: Container(
                          width: 84,
                          height: 190,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.grey.shade300,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.token_outlined,
                            size: 24,
                            color: primary,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'PERMAS Hub',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primary,
                              fontSize: 33 / 2,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Portal Access.',
                            style: TextStyle(
                              color: title,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Enter your credentials to continue to the hub.',
                            style: TextStyle(
                              color: label,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _FieldLabel('ACCOUNT ROLE'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedRole,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF596A80),
                                    ),
                                    decoration: _inputDecoration(
                                      hint: '',
                                      border: border,
                                      background: fieldBg,
                                    ),
                                    items: _roles
                                        .map(
                                          (role) => DropdownMenuItem<String>(
                                            value: role,
                                            child: Text(role),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() => _selectedRole = value);
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  const _FieldLabel('EMAIL ADDRESS'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _inputDecoration(
                                      hint: 'name@domain.com',
                                      border: border,
                                      background: fieldBg,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your email.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  const Row(
                                    children: [
                                      Expanded(child: _FieldLabel('PASSWORD')),
                                      Text(
                                        'FORGOT?',
                                        style: TextStyle(
                                          color: primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: _inputDecoration(
                                      hint: '••••••••',
                                      border: border,
                                      background: fieldBg,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password.';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: isAnyLoading ? null : _signIn,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      child: _isEmailLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('LOGIN  ➜'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 44,
                                    child: OutlinedButton(
                                      onPressed: isAnyLoading ? null : _openRegister,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: primary, width: 1.2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        foregroundColor: primary,
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      child: const Text('SIGN UP'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 44,
                                    child: OutlinedButton.icon(
                                      onPressed: isAnyLoading ? null : _signInWithGoogle,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFFD0D8E4)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        foregroundColor: const Color(0xFF22354D),
                                      ),
                                      icon: _isGoogleLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.g_mobiledata, size: 24),
                                      label: const Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 34,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'New to PERMAS?',
                                        style: TextStyle(
                                          color: label,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      GestureDetector(
                                        onTap: _openRegister,
                                        child: const Text(
                                          'Create an account',
                                          style: TextStyle(
                                            color: primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  color: const Color(0xFFD7DFE8),
                                ),
                                const Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _StatusPanel(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'ENCRYPTED CONNECTION © 2024 PERMAS HUB\nSYSTEMS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF9AA8BA),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color border,
    required Color background,
  }) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: background,
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFA9B4C2),
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF7A93B5), width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: border),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF5E6C80),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'System Status',
          style: TextStyle(
            color: Color(0xFF5E6C80),
            fontSize: 12,
          ),
        ),
        SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: Color(0xFF0A5AA5)),
            SizedBox(width: 6),
            Text(
              'Operational',
              style: TextStyle(
                color: Color(0xFF003E7E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
