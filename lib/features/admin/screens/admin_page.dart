import 'package:flutter/material.dart';

import '../../../core/auth/session_service.dart';
import '../widgets/admin_shell.dart';
import 'academy_admin_page.dart';
import 'system_admin_hub_page.dart';

/// Entrada do painel admin: **admin de sistema** vê o hub (plataforma separada da academia);
/// **admin da academia** vai direto ao painel operacional.
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _sessionService = SessionService();
  bool _loading = true;
  bool _isAdmin = false;
  bool _isSystemAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final isAdmin = await _sessionService.isAdmin();
    final isSys = await _sessionService.isSystemAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _isSystemAdmin = isSys;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AdminPanelStyle.accent),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text("Painel administrativo")),
        body: const AdminAccessDeniedBody(),
      );
    }

    if (_isSystemAdmin) {
      return const SystemAdminHubPage();
    }

    return const AcademyAdminPage();
  }
}
