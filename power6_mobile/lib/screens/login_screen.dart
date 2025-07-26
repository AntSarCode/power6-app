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
      context.read<AppState>().setAuthToken(token);
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/');
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
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _handleLogin,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }
}

