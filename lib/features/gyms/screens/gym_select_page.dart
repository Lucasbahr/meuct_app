import 'package:flutter/material.dart';

import '../../../core/branding/app_branding.dart';
import '../../../core/storage/gym_context_storage.dart';
import '../services/gym_service.dart';

/// Escolhe academia ativa para o header `X-Gym-Id` (admin de sistema).
/// Usa `GET /gyms` já existente na API — sem mudança no backend.
class GymSelectPage extends StatefulWidget {
  const GymSelectPage({
    super.key,
    this.title = "Escolher academia",
    this.barrierDismissible = false,
  });

  final String title;
  final bool barrierDismissible;

  @override
  State<GymSelectPage> createState() => _GymSelectPageState();
}

class _GymSelectPageState extends State<GymSelectPage> {
  final _svc = GymService();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _svc.listGyms();
      if (!mounted) return;
      setState(() {
        _rows = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  Future<void> _pick(int id) async {
    await GymContextStorage.instance.setGymId(id);
    await AppBrandingController.instance.refreshFromApi();
    if (!mounted) return;
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.barrierDismissible,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text("Tentar novamente"),
                          ),
                        ],
                      ),
                    ),
                  )
                : _rows.isEmpty
                    ? const Center(
                        child: Text(
                          "Nenhuma academia retornada pela API.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rows.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final row = _rows[i];
                          final id = GymService.parseGymId(row);
                          final name = GymService.parseGymName(row);
                          if (id == null) {
                            return const SizedBox.shrink();
                          }
                          return Material(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              title: Text(name),
                              subtitle: Text(
                                "ID $id",
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _pick(id),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
