// Estrutura criada em 28/10/26 — implementação pendente (responsável: a definir)
// Descrição: Tela de criação de conta do produtor (nome, e-mail ou telefone, senha).

import 'package:flutter/material.dart';

import '../widgets/tela_em_construcao.dart';

class CriarContaScreen extends StatelessWidget {
  const CriarContaScreen({super.key});

  // TODO(P025): formulário com validação, chamar AuthService.criarConta e seguir para o cadastro da propriedade. Ligar ao botão "Criar conta" da LoginScreen.
  @override
  Widget build(BuildContext context) {
    return const TelaEmConstrucao(titulo: 'Criar conta');
  }
}
