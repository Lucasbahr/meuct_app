import '../api/api_client.dart';

/// URLs de retorno/cancelamento após **checkout de pedido** no navegador (PayPal / Mercado Pago).
///
/// **Não** use isto para OAuth de vínculo da conta MP (`GET /mercadopago/connect`): esse fluxo
/// termina em `…/mercadopago/callback` na API — veja [mercadoPagoOAuthCallbackUrl]. O parâmetro
/// `next_url` nesse fluxo é opcional e exige `MERCADOPAGO_OAUTH_SUCCESS_URL_PREFIX` no servidor.
///
/// Por padrão usa a mesma origem da [ApiClient.baseUrl], que deve expor na API:
/// `GET /payment/mobile-return` e `GET /payment/mobile-cancel`.
///
/// Build customizado: `--dart-define=PAYMENT_RETURN_URL=https://...`
/// e `PAYMENT_CANCEL_URL=...` (ex.: universal link do app).
class CheckoutPaymentUrls {
  CheckoutPaymentUrls._();

  static const String _returnOverride = String.fromEnvironment(
    'PAYMENT_RETURN_URL',
    defaultValue: '',
  );
  static const String _cancelOverride = String.fromEnvironment(
    'PAYMENT_CANCEL_URL',
    defaultValue: '',
  );

  /// Opcional: query `next_url` em `GET /mercadopago/connect`. Só pode ser usado se no backend
  /// existir `MERCADOPAGO_OAUTH_SUCCESS_URL_PREFIX` e esta URL começar com esse prefixo.
  ///
  /// Build: `--dart-define=MP_OAUTH_NEXT_URL=https://app.seudominio.com/deep-link`
  static const String _mpOAuthNextOverride = String.fromEnvironment(
    'MP_OAUTH_NEXT_URL',
    defaultValue: '',
  );

  static String returnUrl() {
    final o = _returnOverride.trim();
    if (o.isNotEmpty) return o;
    return _resolvePath('/payment/mobile-return');
  }

  static String cancelUrl() {
    final o = _cancelOverride.trim();
    if (o.isNotEmpty) return o;
    return _resolvePath('/payment/mobile-cancel');
  }

  /// URL completa que deve ser cadastrada no app Mercado Pago como **Redirect URI** e em
  /// `MERCADOPAGO_OAUTH_REDIRECT_URI` no servidor (não é `payment/mobile-return`).
  static String mercadoPagoOAuthCallbackUrl() {
    return _resolvePath('/mercadopago/callback');
  }

  /// Valor para `next_url` somente se você definiu [MP_OAUTH_NEXT_URL]; caso contrário `null`
  /// (OAuth funciona sem redirecionar de volta para o app).
  static String? mercadoPagoUserOAuthNextUrlOrNull() {
    final o = _mpOAuthNextOverride.trim();
    if (o.isEmpty) return null;
    return o;
  }

  static String _resolvePath(String absolutePath) {
    final path = absolutePath.startsWith('/') ? absolutePath : '/$absolutePath';
    return Uri.parse(ApiClient.baseUrl.trim()).resolve(path).toString();
  }
}
