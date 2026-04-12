import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/payment/checkout_payment_urls.dart';
import '../../../shared/themes/app_button_styles.dart';
import '../../../shared/themes/app_tokens.dart';
import '../../../widgets/password_field_with_visibility.dart';
import '../../marketplace/services/marketplace_service.dart';
import '../widgets/admin_shell.dart';

/// Pagamentos: Mercado Pago via OAuth (URL devolvida pela API) ou token manual; PayPal com Client ID/Secret.
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

  static Map<String, dynamic>? _mergeMercadoPagoStatus(
    Map<String, dynamic>? gym,
    Map<String, dynamic>? userOAuth,
  ) {
    if (gym == null && userOAuth == null) return null;
    final out = <String, dynamic>{
      if (gym != null) ...gym,
    };
    final gymLinked = gym?['has_access_token'] == true ||
        gym?['connected'] == true ||
        gym?['linked'] == true;
    final userLinked = userOAuth?['has_access_token'] == true ||
        userOAuth?['connected'] == true ||
        userOAuth?['linked'] == true;
    out['has_access_token'] = gymLinked || userLinked;
    if (userOAuth != null && userOAuth['oauth_flow'] != null) {
      out['oauth_flow'] = userOAuth['oauth_flow'];
    }
    return out;
  }

  Future<void> _loadMpStatus() async {
    setState(() => _loadingStatus = true);
    try {
      Map<String, dynamic>? gym;
      Map<String, dynamic>? userOAuth;
      try {
        gym = await _service.getPaymentConfig(provider: "mercado_pago");
      } catch (_) {}
      try {
        userOAuth = await _service.getMercadoPagoUserOAuthStatus();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _mpStatus = _mergeMercadoPagoStatus(gym, userOAuth);
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
      final optionalNext = CheckoutPaymentUrls.mercadoPagoUserOAuthNextUrlOrNull();
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
            'Autorize no Mercado Pago. O navegador abre a página da API (/mercadopago/callback); '
            'depois volte ao app e toque em "Atualizar status".',
          ),
          duration: Duration(seconds: 7),
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

  Widget _mercadoPagoApiDetails(ColorScheme cs) {
    final s = _mpStatus;
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
            'Dados da API (sem segredos)',
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
    final mpLinked = _mpStatus?['has_access_token'] == true ||
        _mpStatus?['connected'] == true ||
        _mpStatus?['linked'] == true;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const AdminHeroIntro(
          icon: Icons.payments_outlined,
          title: "Pagamentos",
          subtitle:
              "Mercado Pago: o app chama GET /mercadopago/connect (URL em data.url), opcionalmente com "
              "next_url. O redirect do app MP deve apontar para /mercadopago/callback na API. "
              "PayPal: Client ID e Secret.",
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
            FilledButton.icon(
              style: AdminPanelStyle.filledPrimary(context).merge(
                const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size(double.infinity, 48)),
                ),
              ),
              onPressed: _linking || mpLinked ? null : _vincularMercadoPago,
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
                mpLinked
                    ? "Conta já vinculada"
                    : (_linking ? "Abrindo Mercado Pago…" : "Abrir Mercado Pago e vincular conta"),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mpLinked
                  ? 'Para trocar de conta, use o painel da API ou suporte. Toque em "Atualizar status" após autorizar no MP.'
                  : 'A API devolve a URL em data.url (ou formatos legados). Opcional: token manual na academia abaixo.',
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
                  mpLinked ? Icons.check_circle : Icons.link_off_outlined,
                  color: mpLinked ? AppColors.success : cs.onSurfaceVariant,
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
            const SizedBox(height: 8),
            Text(
              'No app Mercado Pago, Redirect URI = OAuth da API (não é o retorno do checkout):\n'
              '${CheckoutPaymentUrls.mercadoPagoOAuthCallbackUrl()}\n'
              '(servidor: MERCADOPAGO_OAUTH_REDIRECT_URI igual a essa URL). '
              'Retorno do pedido pós-pagamento continua em ${CheckoutPaymentUrls.returnUrl()} '
              '(PAYMENT_RETURN_URL /payment/mobile-return). '
              'Se quiser next_url no OAuth, use --dart-define=MP_OAUTH_NEXT_URL=... '
              'e o mesmo prefixo em MERCADOPAGO_OAUTH_SUCCESS_URL_PREFIX no backend.',
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                fontSize: 11,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Webhooks: o backend pode registrar notification_url na preferência MP; "
              "confira a URL da API na documentação do projeto.",
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                fontSize: 11,
              ),
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
                'Só se o fluxo OAuth não estiver disponível ou a API pedir credencial manual.',
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
