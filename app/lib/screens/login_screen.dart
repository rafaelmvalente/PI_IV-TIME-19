// Rafael Mendes Valente - 25002875
// Data: 08/10/26
// Horário: 00h00 - 06h00
// Descrição: Tela de login do aplicativo ClimAlerta. Contém os campos de
// e-mail/telefone e senha (com opção de mostrar/ocultar a senha), o link
// "Esqueceu sua senha?", o botão "Entrar" e o botão "Criar conta". Após o
// login, verifica se a conta já possui propriedade e, se não tiver, pergunta
// se o produtor quer cadastrar agora.

import 'package:flutter/material.dart';

import '../models/propriedade.dart';
import '../services/auth_service.dart';
import 'cadastro_propriedade_screen.dart';
import 'criar_conta_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _verde = Color(0xFF1E7B58);
  static const Color _borda = Color(0xFFD5DBD8);

  // A chave permite acionar a validação de todos os campos do Form de uma vez
  final _formKey = GlobalKey<FormState>();

  // Os controllers dão acesso ao texto digitado em cada campo.
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _ocultarSenha = true;

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // A propriedade é opcional: quem já tinha cadastro antes não a envia, e o
  // dashboard mostra o nome de exemplo.
  void _abrirDashboard({Propriedade? propriedade}) {
    // pushReplacement troca a tela atual, então o botão "voltar" não
    // retorna ao login depois de entrar.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(propriedade: propriedade),
      ),
    );
  }

  Future<void> _entrar() async {
    // validate() executa o "validator" de cada campo e retorna false se
    // algum deles devolver uma mensagem de erro
    if (!_formKey.currentState!.validate()) return;

    final conta = AuthService.entrar(
      _loginController.text,
      _senhaController.text,
    );

    if (conta == null) {
      _mostrarMensagem('E-mail/telefone ou senha incorretos');
      return;
    }

    if (conta.temPropriedade) {
      _abrirDashboard();
    } else {
      await _perguntarCadastroPropriedade(conta);
    }
  }

  // Pergunta se o produtor quer cadastrar a propriedade agora. Os "await"
  // fazem a função esperar a resposta do usuário. Depois de cada espera é
  // preciso conferir "mounted" (a tela ainda existe?) antes de usar o
  // context, senão o Flutter pode dar erro se a tela já tiver sido fechada.
  Future<void> _perguntarCadastroPropriedade(Conta conta) async {
    final querCadastrar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cadastrar propriedade'),
        content: const Text(
          'Você ainda não possui uma propriedade cadastrada. '
          'Deseja cadastrar agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    Propriedade? propriedade;

    if (querCadastrar == true) {
      // O tipo entre < > precisa ser igual ao que a tela de cadastro devolve
      // no pop. Ela devolve a Propriedade preenchida (e não um bool), então
      // o tipo aqui é Propriedade. Se o usuário voltar sem salvar, o
      // resultado é null.
      propriedade = await Navigator.of(context).push<Propriedade>(
        MaterialPageRoute(builder: (_) => const CadastroPropriedadeScreen()),
      );

      if (!mounted) return;

      if (propriedade != null) {
        AuthService.marcarPropriedadeCadastrada(conta);
      }
    }

    _abrirDashboard(propriedade: propriedade);
  }

  Future<void> _criarConta() async {
    // A tela de criar conta devolve o e-mail/telefone cadastrado, ou null se
    // o usuário voltou sem criar.
    final login = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CriarContaScreen()),
    );

    if (!mounted || login == null) return;

    _loginController.text = login;
    _mostrarMensagem('Conta criada! Digite sua senha para entrar.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          // LayoutBuilder informa a altura disponível da tela. O minHeight
          // faz a coluna ocupar no mínimo a tela inteira, e o spaceBetween
          // empurra a paisagem para o fundo. Em telas baixas, a paisagem
          // fica depois do botão "Criar conta" e rola junto, sem sobrepor.
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // SingleChildScrollView evita o erro de "overflow" quando o
                // teclado abre e diminui a área visível da tela
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 48),
                                _buildLogo(),
                                const Text(
                                  'ClimAlerta',
                                  style: TextStyle(
                                    color: _verde,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Acesse sua conta',
                                  style: TextStyle(
                                    color: Color(0xFF2B3A33),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 48),
                                TextFormField(
                                  controller: _loginController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _decoracao(
                                    'E-mail ou telefone',
                                    Icons.mail_outline,
                                  ),
                                  validator: (valor) {
                                    if (valor == null || valor.trim().isEmpty) {
                                      return 'Informe seu e-mail ou telefone';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _senhaController,
                                  obscureText: _ocultarSenha,
                                  decoration:
                                      _decoracao(
                                        'Senha',
                                        Icons.lock_outline,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _ocultarSenha
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _ocultarSenha =
                                                  !_ocultarSenha,
                                            );
                                          },
                                        ),
                                      ),
                                  validator: (valor) {
                                    if (valor == null || valor.isEmpty) {
                                      return 'Informe sua senha';
                                    }
                                    return null;
                                  },
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _mostrarMensagem('Em breve'),
                                    child: const Text(
                                      'Esqueceu sua senha?',
                                      style: TextStyle(
                                        color: _verde,
                                        fontSize: 13,
                                        decoration: TextDecoration.underline,
                                        decorationColor: _verde,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _verde,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _entrar,
                                    child: const Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'ou',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _verde,
                                      side: const BorderSide(color: _verde),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _criarConta,
                                    child: const Text(
                                      'Criar conta',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/paisagem_casa.png',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Os dois campos têm o mesmo visual, então o estilo fica em um único método.
  InputDecoration _decoracao(String dica, IconData icone) {
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cor),
    );

    return InputDecoration(
      hintText: dica,
      prefixIcon: Icon(icone, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: borda(_borda),
      focusedBorder: borda(_verde),
      errorBorder: borda(Colors.red.shade400),
      focusedErrorBorder: borda(Colors.red.shade400),
    );
  }

  /// Logo menor que o da splash. Assim como lá, o Align com
  /// heightFactor: 0.5 mostra só a faixa central da imagem, onde fica o
  /// desenho, e o ClipRect corta a margem transparente. Para mudar o
  /// tamanho, altere o width.
  Widget _buildLogo() {
    return ClipRect(
      child: Align(
        heightFactor: 0.5,
        child: Image.asset('assets/images/logo PI4.png', width: 170),
      ),
    );
  }
}
