import '../api/api_client.dart';

/// URLs de retorno/cancelamento após checkout no navegador (PayPal / Mercado Pago).
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

  static String _resolvePath(String absolutePath) {
    final path = absolutePath.startsWith('/') ? absolutePath : '/$absolutePath';
    return Uri.parse(ApiClient.baseUrl.trim()).resolve(path).toString();
  }
}
