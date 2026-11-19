// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Autentica o produtor e mantém o token de acesso da API.

import '../models/propriedade.dart';
import '../models/usuario.dart';
import 'api_client.dart';
import 'armazenamento_local_service.dart';

class Conta {
  const Conta({required this.login, required this.usuario, this.propriedade});

  final String login;
  final Usuario usuario;
  final Propriedade? propriedade;

  bool get temPropriedade => propriedade != null;
}

class AuthService {
  AuthService({ApiClient? api, ArmazenamentoLocalService? local})
    : _api = api ?? ApiClient(),
      _local = local ?? const ArmazenamentoLocalService();

  final ApiClient _api;
  final ArmazenamentoLocalService _local;

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
    await _api.salvarToken(response['token'] as String);

    try {
      final conta = await _montarConta(login.trim(), usuario);
      await _local.salvarConta(conta);
      return conta;
    } catch (_) {
      await _api.removerToken();
      rethrow;
    }
  }

  // Reabre a conta com o token salvo, sem pedir login de novo.
  // - Com internet: confere a conta na API e atualiza a cópia no celular.
  // - Sem internet: usa a conta guardada no celular, para o produtor ver os
  //   últimos alertas e o clima salvos (issue #74).
  // - Login expirado (401): apaga o token e a conta guardada.
  // Retorna null quando não há conta para abrir.
  Future<Conta?> restaurarSessao() async {
    if (!await _api.temToken()) return null;
    try {
      final usuario = Usuario.fromJson(
        await _api.get('/auth/me') as Map<String, dynamic>,
      );
      final conta = await _montarConta(
        usuario.email ?? usuario.telefone ?? '',
        usuario,
      );
      await _local.salvarConta(conta);
      return conta;
    } on ApiException catch (error) {
      // statusCode 0 = sem conexão ou a API demorou para responder.
      if (error.statusCode == 0) return _local.lerConta();
      if (error.statusCode == 401) {
        await _api.removerToken();
        await _local.apagarConta();
      }
      return null;
    }
  }

  Future<Conta> _montarConta(String login, Usuario usuario) async {
    final properties = await _api.get('/properties') as List<dynamic>;
    return Conta(
      login: login,
      usuario: usuario,
      propriedade: properties.isEmpty
          ? null
          : Propriedade.fromJson(properties.first as Map<String, dynamic>),
    );
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

  /// Roda antes de apagar o login, enquanto a API ainda aceita a conta.
  /// O main.dart usa para tirar o token de push do aparelho.
  static Future<void> Function()? antesDeSair;

  Future<void> sair() async {
    try {
      await antesDeSair?.call();
    } catch (_) {
      // Nada aqui pode impedir o produtor de sair.
    }
    await _api.removerToken();
    await _local.apagarConta();
  }
}
