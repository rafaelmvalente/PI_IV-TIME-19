// Data: 28/10/2026
// Descrição: Testes do AuthService (contas em memória).

import 'package:app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cria conta, recusa duplicada e entra com a senha certa', () {
    expect(AuthService.criarConta('joao@email.com', '123456'), isTrue);
    expect(AuthService.criarConta(' JOAO@email.com ', 'outra'), isFalse);

    expect(AuthService.entrar('joao@email.com', 'errada'), isNull);
    expect(AuthService.entrar('naoexiste', '123456'), isNull);

    final conta = AuthService.entrar('Joao@Email.com', '123456');
    expect(conta, isNotNull);
    expect(conta!.temPropriedade, isFalse);

    AuthService.marcarPropriedadeCadastrada(conta);
    expect(AuthService.entrar('joao@email.com', '123456')!.temPropriedade, isTrue);
  });
}
