import 'package:flutter/material.dart';
import '../../../widgets/password_field_with_visibility.dart';
import '../repositories/auth_repository.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnack("As senhas nao conferem.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _showSnack("Senha alterada com sucesso.");
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
      appBar: AppBar(title: const Text("Alterar senha")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PasswordFieldWithVisibility(
              controller: _currentPasswordController,
              decoration: const InputDecoration(labelText: "Senha atual"),
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
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: Text(_isLoading ? "Salvando..." : "ALTERAR SENHA"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
