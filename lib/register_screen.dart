import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/user_profile_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final UserProfileService _profileService = UserProfileService();

  bool _acceptedTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Account created, but user data was unavailable.',
        );
      }

      await user.updateDisplayName(_nameController.text.trim());
      await _profileService.createRegistrationProfile(
        user: user,
        name: _nameController.text.trim(),
      );
      await user.sendEmailVerification();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Verification email sent.'),
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      String message = 'Registration failed. Please try again.';
      if (error.code == 'email-already-in-use') {
        message = 'This email is already in use.';
      } else if (error.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (error.code == 'weak-password') {
        message = 'Password is too weak.';
      } else if (error.message != null) {
        message = error.message!;
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
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
                              colors: [Colors.white, Colors.grey.shade300],
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
                          SizedBox(
                            height: 50,
                            child: Image.asset(
                              'assets/permas_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.token_outlined,
                                  size: 24,
                                  color: primary,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'PERMAS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Create Account.',
                            style: TextStyle(
                              color: title,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Register with your PERMAS details to join the hub.',
                            style: TextStyle(color: label, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              image: const DecorationImage(
                                image: AssetImage('assets/mountkinabalu.jpg'),
                                fit: BoxFit.cover,
                                opacity: 0.12,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _FieldLabel('FULL NAME'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: _inputDecoration(
                                      hint: 'Your name',
                                      border: border,
                                      background: fieldBg,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter your name.';
                                      }
                                      return null;
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
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter your email.';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter a valid email.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F4F8),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: border),
                                    ),
                                    child: const Text(
                                      'New accounts are created with Member access. Admin access is assigned separately.',
                                      style: TextStyle(
                                        color: Color(0xFF44546A),
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const _FieldLabel('PASSWORD'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: _inputDecoration(
                                      hint: 'password',
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
                                  const SizedBox(height: 14),
                                  const _FieldLabel('CONFIRM PASSWORD'),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _confirmController,
                                    obscureText: true,
                                    decoration: _inputDecoration(
                                      hint: 'password',
                                      border: border,
                                      background: fieldBg,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password.';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  CheckboxListTile(
                                    value: _acceptedTerms,
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _acceptedTerms = value ?? false;
                                            });
                                          },
                                    dense: true,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: primary,
                                    title: const Text(
                                      'I agree to the terms and conditions.',
                                      style: TextStyle(
                                        color: Color(0xFF44546A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        disabledBackgroundColor: const Color(
                                          0xFF7A93B5,
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('CREATE ACCOUNT'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 44,
                                    child: OutlinedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _backToLogin,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primary,
                                        side: const BorderSide(
                                          color: Color(0xFFD7E0EB),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text('BACK TO LOGIN'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Center(
                            child: Text(
                              'ENCRYPTED CONNECTION © 2026 PERMAS. All rights reserved.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF9AA8BA),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                height: 1.4,
                              ),
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

  void _backToLogin() {
    Navigator.of(context).pop();
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color background,
    required Color border,
  }) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: background,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA9B4C2), fontSize: 14),
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

