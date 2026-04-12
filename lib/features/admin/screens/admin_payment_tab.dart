import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/password_field_with_visibility.dart';
import '../../marketplace/services/marketplace_service.dart';
import '../widgets/admin_shell.dart';

/// Pagamentos: Mercado Pago via **OAuth** (recomendado) ou token manual; PayPal com Client ID/Secret.
class AdminPaymentTab extends StatefulWidget {
  const AdminPaymentTab({super.key});

  @override
  State<AdminPaymentTab> createState() => _AdminPaymentTabState();
}

class _AdminPaymentTabState extends State<AdminPaymentTab> {
  final _service = MarketplaceService();
  String _provider = "mercado_pago";
  final _clientId = TextEditingController();
  final _clientSecret = TextEditingController();
  final _accessToken = TextEditingController();
  final _refreshToken = TextEditingController();
  bool _saving = false;
  bool _loadingStatus = true;
  bool _linking = false;
  Map<String, dynamic>? _mpStatus;

  @override
  void initState() {
    super.initState();
    _loadMpStatus();
  }

  @override
  void dispose() {
    _clientId.dispose();
    _clientSecret.dispose();
    _accessToken.dispose();
    _refreshToken.dispose();
    super.dispose();
  }

  Future<void> _loadMpStatus() async {
    setState(() => _loadingStatus = true);
    try {
      final s = await _service.getPaymentConfig(provider: "mercado_pago");
      if (!mounted) return;
      setState(() {
        _mpStatus = s;
        _loadingStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mpStatus = null;
        _loadingStatus = false;
      });
    }
  }

  Future<void> _vincularMercadoPago() async {
    setState(() => _linking = true);
    try {
      final url = await _service.startMercadoPagoOAuth();
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível abrir o navegador.")),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Faça login no Mercado Pago e autorize. Depois volte ao app e toque em Atualizar status.",
          ),
          duration: Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final out = await _service.savePaymentConfig(
        provider: _provider,
        clientId: _clientId.text.trim().isEmpty ? null : _clientId.text.trim(),
        clientSecret:
            _clientSecret.text.trim().isEmpty ? null : _clientSecret.text.trim(),
        accessToken:
            _accessToken.text.trim().isEmpty ? null : _accessToken.text.trim(),
        refreshToken:
            _refreshToken.text.trim().isEmpty ? null : _refreshToken.text.trim(),
      );
      if (!mounted) return;
      await _loadMpStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Salvo: ${out["provider"] ?? _provider} · "
            "token: ${out["has_access_token"] == true ? "sim" : "não"}",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mpLinked = _mpStatus?["has_access_token"] == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const AdminHeroIntro(
          icon: Icons.payments_outlined,
          title: "Pagamentos",
          subtitle:
              "Credenciais ficam na API desta academia. Mercado Pago: login oficial (OAuth). "
              "PayPal: Client ID e Secret da aplicação.",
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: "mercado_pago", label: Text("Mercado Pago")),
            ButtonSegment(value: "paypal", label: Text("PayPal")),
          ],
          selected: {_provider},
          onSelectionChanged: (s) => setState(() => _provider = s.first),
        ),
        const SizedBox(height: 20),
        if (_provider == "mercado_pago") ...[
          if (_loadingStatus)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: CircularProgressIndicator(color: AdminPanelStyle.accent),
              ),
            )
          else ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AdminPanelStyle.accent,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _linking || mpLinked ? null : _vincularMercadoPago,
              icon: _linking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.open_in_new, size: 22),
              label: Text(
                mpLinked
                    ? "Conta já vinculada"
                    : (_linking ? "Abrindo Mercado Pago…" : "Abrir Mercado Pago e vincular conta"),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mpLinked
                  ? "Para trocar de conta, desvincule na API ou use o suporte. Atualize o status se acabou de autorizar no site."
                  : "Fluxo oficial: o app abre o site do Mercado Pago para login e autorização. "
                      "Você não precisa colar token aqui.",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  mpLinked ? Icons.check_circle : Icons.link_off_outlined,
                  color: mpLinked ? Colors.greenAccent : Colors.white54,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mpLinked
                        ? "Mercado Pago conectado a esta academia."
                        : "Ainda não há vínculo — use o botão acima e depois Atualizar status.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadingStatus ? null : _loadMpStatus,
                  child: const Text("Atualizar status"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "O servidor precisa ter OAuth do Mercado Pago configurado (ex.: MERCADOPAGO_OAUTH_*). "
              "Depois da autorização no site, a API grava as credenciais desta academia.",
              style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 20),
            const Text(
              "Webhooks: o backend pode registrar notification_url na preferência MP; "
              "confira a URL da API na documentação do projeto.",
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: false,
              title: const Text(
                "Sem OAuth no servidor? Colar credencial manualmente",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Só use se POST /payment/mercado-pago/oauth/start não existir ou falhar.",
                style: TextStyle(fontSize: 11),
              ),
              children: [
                PasswordFieldWithVisibility(
                  controller: _accessToken,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Access token (API)",
                    hintText: "APP_USR-...",
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                PasswordFieldWithVisibility(
                  controller: _refreshToken,
                  decoration: const InputDecoration(
                    labelText: "Refresh token (opcional)",
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? "Salvando..." : "Salvar na API"),
                  ),
                ),
              ],
            ),
          ],
        ] else ...[
          TextField(
            controller: _clientId,
            decoration: const InputDecoration(labelText: "Client ID *"),
          ),
          const SizedBox(height: 12),
          PasswordFieldWithVisibility(
            controller: _clientSecret,
            decoration: const InputDecoration(labelText: "Client Secret *"),
          ),
          const SizedBox(height: 12),
          PasswordFieldWithVisibility(
            controller: _refreshToken,
            decoration: const InputDecoration(
              labelText: "Refresh token (opcional)",
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? "Salvando..." : "Salvar configuração"),
          ),
        ],
      ],
    );
  }
}
