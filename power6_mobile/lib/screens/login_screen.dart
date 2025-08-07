import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
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
  String? _error;

  void _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await AuthService().login(
      _usernameController.text,
      _passwordController.text,
    );

    if (response.isSuccess) {
      final token = response.data!;
      final userResponse = await AuthService().getCurrentUser();

      if (userResponse.isSuccess && userResponse.data != null) {
        context.read<AppState>().setAuthToken(token, user: userResponse.data);
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        setState(() {
          _error = userResponse.error ?? 'Failed to load user info';
          _loading = false;
        });
      }
    } else {
      setState(() {
        _error = response.error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome Back')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Log In',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
