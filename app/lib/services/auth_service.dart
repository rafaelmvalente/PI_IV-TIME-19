// Data: 28/10/2026
// Descrição: Mantém em memória as contas usadas pelo login e pelo cadastro.

import '../models/propriedade.dart';

class Conta {
  final String login;
  final String senha;
  bool temPropriedade;
  Propriedade? propriedade;

  Conta({
    required this.login,
    required this.senha,
    this.temPropriedade = false,
    this.propriedade,
  });
}

class AuthService {
  // As contas permanecem disponíveis até o encerramento do aplicativo.
  static final Map<String, Conta> _contas = {};

  // Retorna false se já existir uma conta com esse e-mail ou telefone.
  static bool criarConta(String login, String senha) {
    final chave = login.trim().toLowerCase();
    if (_contas.containsKey(chave)) return false;

    _contas[chave] = Conta(login: login.trim(), senha: senha);
    return true;
  }

  // Retorna a conta se o login e a senha conferirem; caso contrário, null.
  static Conta? entrar(String login, String senha) {
    final conta = _contas[login.trim().toLowerCase()];
    if (conta == null || conta.senha != senha) return null;
    return conta;
  }

  static void marcarPropriedadeCadastrada(
    Conta conta, {
    Propriedade? propriedade,
  }) {
    conta.temPropriedade = true;
    conta.propriedade = propriedade;
  }

  // Guarda a propriedade editada na conta (tela de Perfil).
  static void atualizarPropriedade(String login, Propriedade propriedade) {
    final conta = _contas[login.trim().toLowerCase()];
    if (conta == null) return;
    conta.temPropriedade = true;
    conta.propriedade = propriedade;
  }

  // Representa a solicitação de recuperação de senha pelo login informado.
  static Future<void> recuperarSenha(String login) async {}
}
