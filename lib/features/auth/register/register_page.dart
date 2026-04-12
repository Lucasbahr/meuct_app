import 'package:flutter/material.dart';
import '../../../shared/themes/app_button_styles.dart';
import '../../../widgets/password_field_with_visibility.dart';
import '../repositories/auth_repository.dart';
import '../../gyms/services/gym_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();
  final _gymService = GymService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _gyms = [];
  int? _selectedGymId;
  bool _gymsLoading = true;
  String? _gymLoadError;

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadGyms() async {
    setState(() {
      _gymsLoading = true;
      _gymLoadError = null;
    });
    try {
      final list = await _gymService.listGyms();
      if (!mounted) return;
      final ids = list
          .map(GymService.parseGymId)
          .whereType<int>()
          .toList();
      int? nextId = _selectedGymId;
      if (ids.isNotEmpty) {
        nextId = (nextId != null && ids.contains(nextId)) ? nextId : ids.first;
      } else {
        nextId ??= 1;
      }
      setState(() {
        _gyms = list;
        _selectedGymId = nextId;
        _gymsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gymLoadError = e.toString().replaceFirst("Exception: ", "");
        _selectedGymId = 1;
        _gymsLoading = false;
      });
    }
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack("As senhas nao conferem.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.register(
        _emailController.text.trim(),
        _passwordController.text,
        gymId: _selectedGymId,
      );
      if (!mounted) return;
      _showSnack("Conta criada. Verifique seu email para ativar o acesso.");
      Navigator.pop(context);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _gymsWithId => _gyms
      .where((g) => GymService.parseGymId(g) != null)
      .toList();

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst("Exception: ", ""))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Criar conta")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            PasswordFieldWithVisibility(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Senha"),
            ),
            const SizedBox(height: 12),
            PasswordFieldWithVisibility(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: "Confirmar senha"),
            ),
            const SizedBox(height: 16),
            Text(
              "Academia",
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 6),
            if (_gymsLoading)
              const LinearProgressIndicator(minHeight: 2)
            else if (_gymsWithId.isEmpty)
              Text(
                _gymLoadError != null
                    ? "Não foi possível carregar academias ($_gymLoadError). "
                        "Será usado gym_id padrão (1)."
                    : _gyms.isEmpty
                        ? "Nenhuma academia listada. Será usado gym_id padrão (1)."
                        : "Lista de academias sem identificador válido. "
                            "Será usado gym_id padrão (1).",
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedGymId,
                decoration: const InputDecoration(
                  labelText: "Sua academia",
                  border: OutlineInputBorder(),
                ),
                items: _gymsWithId
                    .map((g) {
                      final id = GymService.parseGymId(g)!;
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(GymService.parseGymName(g)),
                      );
                    })
                    .toList(),
                onChanged: (v) => setState(() => _selectedGymId = v),
              ),
            if (!_gymsLoading && _gymsWithId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loadGyms,
                  child: const Text("Atualizar lista"),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _register,
                child: Text(_isLoading ? "Criando..." : "CRIAR CONTA"),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, "/resend-verification");
              },
              style: AppButtonStyles.dangerText(),
              child: const Text("Nao recebeu o email? Reenviar"),
            ),
          ],
        ),
      ),
    );
  }
}
