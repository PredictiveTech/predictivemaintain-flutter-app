import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/network/api_config.dart';
import '../../core/network/auth_token_holder.dart' as auth;
import '../../core/network/http_client.dart';
import '../../navigation/home_screen.dart';
import '../infrastructure/auth_session_dto.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _client = HttpClient(tokenProvider: () async => auth.accessToken);
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final session = AuthSessionDto.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        ).toDomain();
        auth.accessToken = session.accessToken;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showError(_errorMessage(response.statusCode, response.body));
      }
    } catch (e) {
      _showError('No se pudo iniciar sesión: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMessage(int status, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['message'] is String) {
        return json['message'] as String;
      }
    } catch (_) {}
    return 'Error al iniciar sesión (HTTP $status)';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const CircularProgressIndicator()
                else
                  FilledButton(
                    onPressed: _login,
                    child: const Text('Entrar'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
