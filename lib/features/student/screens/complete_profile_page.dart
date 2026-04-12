import 'package:flutter/material.dart';
import '../../../core/api/dio_unauthorized.dart';
import '../../auth/repositories/auth_repository.dart';
import '../services/student_service.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _service = StudentService();
  final _authRepository = AuthRepository();
  final _nomeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getMe();
      if (!mounted) return;
      final nome = (data["nome"] ?? "").toString();
      _nomeController.text = nome;
      setState(() => _isLoading = false);

      if (nome.trim().isNotEmpty) {
        // Usuário já completou o perfil.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, "/home");
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (dioIsUnauthorized(e)) {
        await _authRepository.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe seu nome para continuar.")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await _service.updateMyProfile(nome: nome);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Completar perfil")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.tertiary))
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      Text(
                        "Para entrar na tela inicial, precisamos do seu nome.",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nomeController,
                        decoration: const InputDecoration(labelText: "Nome"),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text("Salvando..."),
                                  ],
                                )
                              : const Text("Salvar"),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSaving)
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.brightness == Brightness.light
                              ? cs.inverseSurface.withValues(alpha: 0.72)
                              : cs.scrim.withValues(alpha: 0.65),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: cs.tertiary),
                              const SizedBox(height: 16),
                              Text(
                                "Salvando...",
                                style: TextStyle(
                                  color: cs.brightness == Brightness.light
                                      ? cs.onInverseSurface
                                      : cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

