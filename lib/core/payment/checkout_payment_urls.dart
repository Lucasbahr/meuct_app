import '../api/api_client.dart';

/// URLs de retorno do checkout (navegador externo) e utilitários de OAuth Mercado Pago.
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

  static String mercadoPagoOAuthCallbackUrl() {
    return _resolvePath('/payment/mercado-pago/oauth/callback');
  }

  static String? mercadoPagoGymOAuthNextUrlOrNull() {
    final o = _mpOAuthNextOverride.trim();
    if (o.isEmpty) return null;
    return o;
  }

  static String _resolvePath(String absolutePath) {
    final path = absolutePath.startsWith('/') ? absolutePath : '/$absolutePath';
    return Uri.parse(ApiClient.baseUrl.trim()).resolve(path).toString();
  }
}
