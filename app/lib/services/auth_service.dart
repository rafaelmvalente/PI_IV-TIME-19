// Data: 28/10/2026
// Descrição: Contas do produtor usadas pelo login e pela criação de conta.
// Enquanto o backend não existe (P010), as contas ficam só na memória do app.

class Conta {
  final String login;
  final String senha;
  bool temPropriedade;

  Conta({
    required this.login,
    required this.senha,
    this.temPropriedade = false,
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

  static void marcarPropriedadeCadastrada(Conta conta) {
    conta.temPropriedade = true;
  }
}
