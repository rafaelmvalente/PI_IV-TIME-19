// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Login, criação de conta, recuperação de senha e sessão do
// produtor, consumindo o backend (endpoints a definir, P010).

import '../models/usuario.dart';

class AuthService {
  const AuthService();

  // TODO(P020): enviar login/senha ao backend e guardar o token (flutter_secure_storage).
  Future<Usuario> entrar(String login, String senha) {
    throw UnimplementedError('P020: login ainda não implementado');
  }

  // TODO(P025): enviar os dados da nova conta ao backend.
  Future<Usuario> criarConta({
    required String nome,
    required String login,
    required String senha,
  }) {
    throw UnimplementedError('P025: criação de conta ainda não implementada');
  }

  // TODO(P039): pedir ao backend a recuperação de senha.
  Future<void> recuperarSenha(String login) {
    throw UnimplementedError('P039: recuperação de senha não implementada');
  }

  // TODO(P020): apagar o token salvo.
  Future<void> sair() {
    throw UnimplementedError('P020: logout ainda não implementado');
  }
}
