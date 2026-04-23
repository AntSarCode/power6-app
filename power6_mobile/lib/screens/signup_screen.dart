import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/signup';
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _obscurePwd = true;
  bool _obscureCfm = true;
  String? _error;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_password.text != _confirm.text) {
      setState(() => _error = "Passwords don't match.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _authService.register(
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      if (res.isSuccess) {
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        setState(() => _error = res.error ?? 'Sign up failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0F12),
                  Color.fromRGBO(15, 31, 36, 0.95),
                  Color(0xFF0A0F12),
                ],
              ),
            ),
          ),

          // Decorative glows
          Positioned(
            left: -100,
            top: -80,
            child: SizedBox(
              width: 260,
              height: 260,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: const Color.fromRGBO(15, 179, 160, 0.35)),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 0, 0, 0.35),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color.fromRGBO(0, 150, 136, 0.25)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            const Icon(Icons.local_fire_department_rounded, size: 56, color: Colors.tealAccent),
                            const SizedBox(height: 12),
                            Text(
                              'Join Power6',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Six tasks a day. Make consistency easy.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 24),

                            _LabeledField(
                              label: 'Username',
                              child: TextFormField(
                                controller: _username,
                                decoration: _inputDecoration(hint: 'Choose a username', icon: Icons.person_outline),
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(height: 14),

                            _LabeledField(
                              label: 'Email',
                              child: TextFormField(
                                controller: _email,
                                decoration: _inputDecoration(hint: 'you@email.com', icon: Icons.alternate_email),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                              ),
                            ),
                            const SizedBox(height: 14),

                            _LabeledField(
                              label: 'Password',
                              child: TextFormField(
                                controller: _password,
                                decoration: _inputDecoration(hint: 'Create a password', icon: Icons.lock_outline).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePwd ? 'Show password' : 'Hide password',
                                    icon: Icon(_obscurePwd ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                                  ),
                                ),
                                obscureText: _obscurePwd,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                              ),
                            ),
                            const SizedBox(height: 14),

                            _LabeledField(
                              label: 'Confirm password',
                              child: TextFormField(
                                controller: _confirm,
                                decoration: _inputDecoration(hint: 'Re-enter password', icon: Icons.lock_person_outlined).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _obscureCfm ? 'Show password' : 'Hide password',
                                    icon: Icon(_obscureCfm ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () => setState(() => _obscureCfm = !_obscureCfm),
                                  ),
                                ),
                                obscureText: _obscureCfm,
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => (v == null || v.isEmpty) ? 'Confirm your password' : null,
                              ),
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                            ],

                            const SizedBox(height: 16),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _loading
                                      ? const SizedBox(
                                          key: ValueKey('loading'),
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                        )
                                      : const Text(
                                          key: ValueKey('text'),
                                          'Sign up',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? ', style: TextStyle(color: Colors.white70)),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  ),
                                  child: const Text('Log in'),
                                )
                              ],
                            ),

                            const SizedBox(height: 4),
                            Text(
                              'By signing up, you agree to our Terms and Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.teal.shade200),
      filled: true,
      isDense: true,
      fillColor: const Color.fromRGBO(14, 22, 25, 0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color.fromRGBO(0, 150, 136, 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color.fromRGBO(100, 255, 218, 0.9), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 2),
          child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70)),
        ),
        child,
      ],
    );
  }
}