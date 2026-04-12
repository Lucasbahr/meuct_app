import 'package:flutter/material.dart';

import '../../../shared/themes/app_tokens.dart';
import '../services/admin_service.dart';
import '../widgets/admin_shell.dart';
import '../../membership/services/membership_service.dart';

int? _coerceId(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String _planPriceLabel(dynamic priceRaw) {
  final n = priceRaw is num
      ? priceRaw.toDouble()
      : double.tryParse(priceRaw?.toString() ?? "");
  if (n != null && n == 0) return "Grátis";
  return "R\$ ${MembershipService.formatMoney(priceRaw)}";
}

/// Planos, novas assinaturas e registro manual de pagamento (API membership).
class AdminPlansTab extends StatefulWidget {
  const AdminPlansTab({super.key});

  @override
  State<AdminPlansTab> createState() => _AdminPlansTabState();
}

class _AdminPlansTabState extends State<AdminPlansTab> {
  final _membership = MembershipService();
  final _admin = AdminService();

  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  bool _activeOnly = false;
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
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _membership.listPlans(activeOnly: _activeOnly),
        _admin.getStudents(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0];
        _students = results[1];
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

  Future<void> _createPlan() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: "30");
    var active = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("Novo plano"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nome *"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Preço (BRL) *",
                    hintText: "99.90 ou 0 (gratuito)",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: daysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Duração (dias) *",
                  ),
                ),
                SwitchListTile(
                  title: const Text("Plano ativo"),
                  value: active,
                  onChanged: (v) => setLocal(() => active = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Criar")),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final name = nameCtrl.text.trim();
    final price = double.tryParse(priceCtrl.text.replaceAll(",", "."));
    final days = int.tryParse(daysCtrl.text.trim());
    if (name.isEmpty || price == null || price < 0 || days == null || days < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Preencha nome, preço (0 = gratuito) e dias válidos."),
        ),
      );
      return;
    }
    try {
      await _membership.createPlan(
        name: name,
        price: price,
        durationDays: days,
        isActive: active,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plano criado.")),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
        ),
      );
    }
  }

  Future<void> _newSubscription() async {
    if (_plans.isEmpty || _students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cadastre planos e tenha alunos na lista.")),
      );
      return;
    }
    final activePlans = _plans.where((p) => p["is_active"] != false).toList();
    if (activePlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum plano ativo.")),
      );
      return;
    }

    int? studentId;
    int? planId;
    final startCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text("Nova assinatura"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: studentId,
                  decoration: const InputDecoration(labelText: "Aluno *"),
                  items: _students
                      .map((s) {
                        final sid = _coerceId(s["id"]);
                        if (sid == null) return null;
                        final nome = (s["nome"] ?? "#$sid").toString();
                        return DropdownMenuItem(value: sid, child: Text(nome));
                      })
                      .whereType<DropdownMenuItem<int>>()
                      .toList(),
                  onChanged: (v) => setLocal(() => studentId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: planId,
                  decoration: const InputDecoration(labelText: "Plano *"),
                  items: activePlans
                      .map((p) {
                        final pid = _coerceId(p["id"]);
                        if (pid == null) return null;
                        final nome = (p["name"] ?? "Plano").toString();
                        return DropdownMenuItem(
                          value: pid,
                          child: Text("$nome · ${_planPriceLabel(p["price"])}"),
                        );
                      })
                      .whereType<DropdownMenuItem<int>>()
                      .toList(),
                  onChanged: (v) => setLocal(() => planId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: "Início (opcional)",
                    hintText: "AAAA-MM-DD",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Criar")),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    if (studentId == null || planId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione aluno e plano.")),
      );
      return;
    }
    try {
      final res = await _membership.createSubscription(
        studentId: studentId!,
        planId: planId!,
        startDate: startCtrl.text.trim().isEmpty ? null : startCtrl.text.trim(),
      );
      if (!mounted) return;
      final payments = res["payments"];
      String extra = "";
      if (payments is List && payments.isNotEmpty) {
        final first = payments.first;
        if (first is Map && first["id"] != null) {
          extra = " ID do 1º pagamento: ${first["id"]}.";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Assinatura criada.$extra")),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _markPaidDialog() async {
    final idCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Registrar pagamento"),
        content: TextField(
          controller: idCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "ID do pagamento *",
            helperText: "Exibido ao criar assinatura ou na API",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Confirmar")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final pid = int.tryParse(idCtrl.text.trim());
    if (pid == null) return;
    try {
      await _membership.markPaymentPaid(pid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pagamento marcado como pago.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.tertiary;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: accent,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              AdminHeroIntro(
                icon: Icons.payments_outlined,
                title: "Mensalidades",
                subtitle:
                    "Planos, assinaturas e registro manual de pagamentos (dinheiro, PIX, etc.).",
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  FilterChip(
                    label: const Text("Só ativos"),
                    selected: _activeOnly,
                    onSelected: (v) {
                      setState(() => _activeOnly = v);
                      _load();
                    },
                    selectedColor: accent.withValues(alpha: 0.22),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _markPaidDialog,
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text("Registrar pagamento"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _newSubscription,
                icon: const Icon(Icons.link),
                label: const Text("Nova assinatura (aluno + plano)"),
              ),
              const SizedBox(height: 20),
              Text(
                "Planos cadastrados",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              if (_plans.isEmpty)
                const AdminEmptyHint(
                  message: "Nenhum plano ainda. Use o botão + para criar o primeiro.",
                  icon: Icons.price_change_outlined,
                )
              else
                ..._plans.map((p) {
                  final name = (p["name"] ?? "Plano").toString();
                  final priceRaw = p["price"];
                  final priceLine = _planPriceLabel(priceRaw);
                  final days = p["duration_days"]?.toString() ?? "—";
                  final active = p["is_active"] != false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: cs.outline.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$priceLine · $days dias",
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : cs.onSurfaceVariant.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              active ? "Ativo" : "Inativo",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? AppColors.success
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _createPlan,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
