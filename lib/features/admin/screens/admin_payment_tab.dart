import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/payment/checkout_payment_urls.dart';
import '../../../shared/themes/app_button_styles.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../../widgets/password_field_with_visibility.dart';
import '../../marketplace/services/marketplace_service.dart';
import '../widgets/admin_shell.dart';

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
  Map<String, dynamic>? _gymPaymentConfig;

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

  static bool _hasProviderToken(Map<String, dynamic>? m) {
    if (m == null) return false;
    return m['has_access_token'] == true ||
        m['connected'] == true ||
        m['linked'] == true;
  }

  Future<void> _loadMpStatus() async {
    setState(() => _loadingStatus = true);
    try {
      Map<String, dynamic>? gym;
      try {
        gym = await _service.getPaymentConfig(provider: "mercado_pago");
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _gymPaymentConfig = gym;
        _loadingStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gymPaymentConfig = null;
        _loadingStatus = false;
      });
    }
  }

  Future<void> _vincularMercadoPago() async {
    setState(() => _linking = true);
    try {
      final optionalNext = CheckoutPaymentUrls.mercadoPagoGymOAuthNextUrlOrNull();
      final url = await _service.startMercadoPagoOAuth(
        nextUrl: optionalNext,
      );
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
            'Autorize no Mercado Pago e depois toque em Atualizar status.',
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

  static String? _firstString(Map<String, dynamic>? m, List<String> keys) {
    if (m == null) return null;
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  static String _maskKey(String? raw) {
    if (raw == null || raw.length < 14) return raw ?? '—';
    return '${raw.substring(0, 10)}…${raw.substring(raw.length - 4)}';
  }

  Widget _mpStatusRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool ok,
    required String okLabel,
    required String badLabel,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok
              ? AppColors.success.withValues(alpha: 0.45)
              : cs.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.verified_outlined : Icons.radio_button_unchecked,
                size: 20,
                color: ok ? AppColors.success : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ok ? okLabel : badLabel,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: ok ? AppColors.success : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mercadoPagoApiDetails(ColorScheme cs) {
    final s = _gymPaymentConfig;
    if (s == null || s.isEmpty) return const SizedBox.shrink();

    final userRef = _firstString(s, ['user_id', 'collector_id', 'seller_id', 'mp_user_id']);
    final nickname = _firstString(s, ['nickname', 'mp_nickname']);
    final live = s['live_mode'] ?? s['sandbox'];
    final pub = _firstString(s, ['public_key', 'mp_public_key']);
    final scope = _firstString(s, ['scope']);
    final conn = _firstString(s, ['connection_type', 'connection', 'link_type']);

    final lines = <(String, String)>[];
    if (userRef != null) lines.add(('Conta (ID)', userRef));
    if (nickname != null) lines.add(('Nome na conta', nickname));
    if (live != null) lines.add(('Modo', live.toString()));
    if (pub != null) lines.add(('Chave pública', _maskKey(pub)));
    if (scope != null) lines.add(('Escopos', scope));
    if (conn != null) lines.add(('Tipo de vínculo', conn));
    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes da conta',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 118,
                    child: Text(
                      t.$1,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t.$2,
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gymMpReady = _hasProviderToken(_gymPaymentConfig);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const AdminHeroIntro(
          icon: Icons.payments_outlined,
          title: "Pagamentos",
          subtitle:
              "Conecte Mercado Pago ou PayPal para a academia receber na própria conta. "
              "Na loja, os alunos pagam com o método que você configurar aqui.",
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            )
          else ...[
            _mpStatusRow(
              context,
              title: "Conta Mercado Pago da academia",
              subtitle:
                  "Necessária para o carrinho e pagamentos da loja.",
              ok: gymMpReady,
              okLabel: "Conta configurada. A loja pode cobrar com Mercado Pago.",
              badLabel:
                  "Ainda não configurada. Use o botão abaixo ou o token manual.",
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: AdminPanelStyle.filledPrimary(context).merge(
                const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size(double.infinity, 48)),
                ),
              ),
              onPressed: _linking ? null : _vincularMercadoPago,
              icon: _linking
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.open_in_new, size: 22),
              label: Text(
                _linking
                    ? "Abrindo Mercado Pago…"
                    : "Conectar conta Mercado Pago",
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Abra o link, autorize no app Mercado Pago e depois toque em «Atualizar status».',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            _mercadoPagoApiDetails(cs),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  gymMpReady ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: gymMpReady ? AppColors.success : cs.tertiary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gymMpReady
                        ? "A loja pode receber com Mercado Pago."
                        : "Configure a conta acima para o carrinho aceitar Mercado Pago.",
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadingStatus ? null : _loadMpStatus,
                  child: const Text("Atualizar status"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: false,
              title: const Text(
                "Credencial manual (avançado)",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Use apenas se a equipe de suporte orientar.',
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
                  child: FilledButton(
                    style: AppButtonStyles.tonalFilled(
                      Theme.of(context).colorScheme,
                    ),
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
