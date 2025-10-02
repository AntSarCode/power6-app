import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import './signup_screen.dart';
import '../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  final _formKey = GlobalKey<FormState>();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await AuthService().login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      final token = response.data!;
      final userResponse = await AuthService().getCurrentUser();

      if (userResponse.isSuccess && userResponse.data != null) {
        context.read<AppState>().setAuthToken(token, user: userResponse.data);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() {
          _error = userResponse.error ?? 'Failed to load user info';
          _loading = false;
        });
      }
    } else {
      setState(() {
        _error = response.error ?? 'Login failed';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Welcome Back'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Animated gradient background
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A0F12),
                      const Color.fromRGBO(15, 31, 36, 0.95),
                      const Color(0xFF0A0F12),
                    ],
                    stops: [0, value.clamp(0.2, 0.8), 1],
                  ),
                ),
              );
            },
          ),

          // Decorative teal glow
          Positioned(
            top: -120,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0FB3A0),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox.shrink(),
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
                            // Logo / Hero
                            const SizedBox(height: 8),
                            const Icon(Icons.local_fire_department_rounded, size: 56, color: Colors.tealAccent),
                            const SizedBox(height: 12),
                            Text(
                              'Power6',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Six tasks. One streak. Keep it burning.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 24),

                            // Username field
                            _LabeledField(
                              label: 'Username',
                              child: TextFormField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter username' : null,
                                decoration: _inputDecoration(
                                  hint: 'Enter your username',
                                  icon: Icons.person_outline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Password field
                            _LabeledField(
                              label: 'Password',
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                style: const TextStyle(color: Colors.white),
                                validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                                onFieldSubmitted: (_) => _loading ? null : _handleLogin(),
                                decoration: _inputDecoration(
                                  hint: 'Enter your password',
                                  icon: Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _obscure ? 'Show password' : 'Hide password',
                                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.verified_user, size: 16, color: Colors.teal.shade200),
                                    const SizedBox(width: 6),
                                    Text('Secure login', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    // TODO: route to forgot password when implemented
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Forgot password coming soon')),
                                    );
                                  },
                                  child: const Text('Forgot password?'),
                                )
                              ],
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            const SizedBox(height: 16),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _handleLogin,
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
                                          'Log In',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                  ),
                                  child: const Text('Sign up'),
                                ),
                              ],
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
        borderSide: BorderSide(color: const Color.fromRGBO(0, 150, 136, 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: const Color.fromRGBO(100, 255, 218, 0.9), width: 1.2),
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
