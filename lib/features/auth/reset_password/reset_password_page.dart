import 'package:flutter/material.dart';
import '../../../widgets/password_field_with_visibility.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnack("As senhas nao conferem.");
      return;
    }
    if (_tokenController.text.trim().isEmpty) {
      _showSnack("Informe o token de redefinicao.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.resetPassword(
        token: _tokenController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _showSnack("Senha redefinida com sucesso.");
      Navigator.pop(context);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst("Exception: ", ""))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Redefinir senha")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(labelText: "Token"),
            ),
            const SizedBox(height: 12),
            PasswordFieldWithVisibility(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: "Nova senha"),
            ),
            const SizedBox(height: 12),
            PasswordFieldWithVisibility(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: "Confirmar senha"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: Text(_isLoading ? "Salvando..." : "REDEFINIR SENHA"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
