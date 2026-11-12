// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Cliente HTTP comum para as rotas protegidas e públicas do backend.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, this.baseUrl})
    : _client = client ?? _sharedClient;

  static final http.Client _sharedClient = http.Client();
  static const _tokenKey = 'api_access_token';
  final http.Client _client;
  final String? baseUrl;

  Future<void> salvarToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
  }

  Future<void> removerToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }

  Future<bool> temToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey)?.isNotEmpty ?? false;
  }

  Future<Object?> get(String path, {Map<String, String>? queryParameters}) {
    return _send('GET', path, queryParameters: queryParameters);
  }

  Future<Object?> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
  }

  Future<Object?> patch(String path, {Object? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<Object?> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final apiBaseUrl = (baseUrl ?? ApiConfig.baseUrl).trim();
    if (apiBaseUrl.isEmpty) {
      throw StateError(
        'Defina API_URL ao iniciar o app, apontando para a API ClimAlerta.',
      );
    }

    final normalizedBase = apiBaseUrl.endsWith('/')
        ? apiBaseUrl
        : '$apiBaseUrl/';
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse(
      '$normalizedBase$normalizedPath',
    ).replace(queryParameters: queryParameters);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';

    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(const Duration(seconds: 15));
      final decoded = _decodeResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded is Map<String, dynamic>
            ? decoded['error'] as Map<String, dynamic>?
            : null;
        throw ApiException(
          statusCode: response.statusCode,
          code: error?['code'] as String? ?? 'HTTP_ERROR',
          message:
              error?['message'] as String? ??
              'A API respondeu com erro (${response.statusCode}).',
        );
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        code: 'REQUEST_TIMEOUT',
        message: 'A API demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: 'Não foi possível conectar à API. Verifique sua conexão.',
      );
    }
  }

  Object? _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        statusCode: response.statusCode,
        code: 'INVALID_RESPONSE',
        message: 'A API retornou uma resposta inválida.',
      );
    }
  }
}
