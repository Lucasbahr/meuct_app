import 'package:dio/dio.dart';

/// Consulta pública ViaCEP (Brasil). Não usa o ApiClient da academia.
class ViaCepService {
  ViaCepService() : _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));

  final Dio _dio;

  /// [rawCep] pode conter máscara; usa só os 8 dígitos.
  Future<ViaCepResult?> lookup(String rawCep) async {
    final digits = rawCep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://viacep.com.br/ws/$digits/json/',
      );
      final data = res.data;
      if (data == null) return null;
      if (data['erro'] == true) return null;
      return ViaCepResult.fromJson(data);
    } on DioException {
      return null;
    }
  }
}

class ViaCepResult {
  ViaCepResult({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;

  factory ViaCepResult.fromJson(Map<String, dynamic> json) {
    String s(String k) => (json[k] ?? '').toString();
    return ViaCepResult(
      cep: s('cep'),
      logradouro: s('logradouro'),
      complemento: s('complemento'),
      bairro: s('bairro'),
      localidade: s('localidade'),
      uf: s('uf'),
    );
  }
}
