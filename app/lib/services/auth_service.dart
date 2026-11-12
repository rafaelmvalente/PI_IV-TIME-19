// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Autentica o produtor e mantém o token de acesso da API.

import '../models/propriedade.dart';
import '../models/usuario.dart';
import 'api_client.dart';

class Conta {
  const Conta({
    required this.login,
    required this.usuario,
    required this.token,
    this.propriedade,
  });

  final String login;
  final Usuario usuario;
  final String token;
  final Propriedade? propriedade;

  bool get temPropriedade => propriedade != null;
}

class AuthService {
  AuthService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<void> criarConta({
    required String nome,
    required String login,
    required String senha,
  }) async {
    final normalizedLogin = login.trim();
    final body = <String, Object>{
      'nome': nome.trim(),
      'senha': senha,
      if (normalizedLogin.contains('@'))
        'email': normalizedLogin
      else
        'telefone': normalizedLogin,
    };
    await _api.post('/auth/register', body: body);
  }

  Future<Conta?> entrar(String login, String senha) async {
    final response =
        await _api.post(
              '/auth/login',
              body: {'login': login.trim(), 'senha': senha},
            )
            as Map<String, dynamic>;
    final usuario = Usuario.fromJson(
      response['usuario'] as Map<String, dynamic>,
    );
    final token = response['token'] as String;
    await _api.salvarToken(token);

    try {
      final properties = await _api.get('/properties') as List<dynamic>;
      return Conta(
        login: login.trim(),
        usuario: usuario,
        token: token,
        propriedade: properties.isEmpty
            ? null
            : Propriedade.fromJson(properties.first as Map<String, dynamic>),
      );
    } catch (_) {
      await _api.removerToken();
      rethrow;
    }
  }

  Future<Conta?> restaurarSessao() async {
    final token = await _api.obterToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _api.get('/auth/me') as Map<String, dynamic>;
      final usuario = Usuario.fromJson(response);
      final properties = await _api.get('/properties') as List<dynamic>;
      return Conta(
        login: usuario.email ?? usuario.telefone ?? '',
        usuario: usuario,
        token: token,
        propriedade: properties.isEmpty
            ? null
            : Propriedade.fromJson(properties.first as Map<String, dynamic>),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _api.removerToken();
        return null;
      }
      rethrow;
    }
  }

  Future<void> recuperarSenha(String login) async {
    await _api.post('/auth/forgot-password', body: {'login': login.trim()});
  }

  Future<void> redefinirSenha({
    required String token,
    required String novaSenha,
  }) async {
    await _api.post(
      '/auth/reset-password',
      body: {'token': token, 'novaSenha': novaSenha},
    );
  }

  Future<void> atualizarPreferencias(Map<String, bool> preferencias) async {
    await _api.patch('/auth/me/preferences', body: preferencias);
  }

  Future<void> sair() => _api.removerToken();
}
