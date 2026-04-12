import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

class ResendVerificationPage extends StatefulWidget {
  const ResendVerificationPage({super.key});

  @override
  State<ResendVerificationPage> createState() =>
      _ResendVerificationPageState();
}

class _ResendVerificationPageState extends State<ResendVerificationPage> {
  final _emailController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe seu email.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.resendVerification(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Se o email existir, enviamos um link de verificação.",
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reenviar verificação")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _resend,
                child: Text(_isLoading ? "Enviando..." : "REENVIAR EMAIL"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

