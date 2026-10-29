// Data: 28/10/2026
// Descrição: Contas do produtor usadas pelo login e pela criação de conta.
// Enquanto o backend não existe (P010), as contas ficam só na memória do app.

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
  // shortcut: contas em memória somem ao fechar o app; trocar pela chamada ao backend (P010).
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

  // Pede o link de recuperação de senha para o e-mail ou telefone informado.
  // shortcut: ainda não envia nada; trocar pela chamada ao backend (P010).
  static Future<void> recuperarSenha(String login) async {}
}
