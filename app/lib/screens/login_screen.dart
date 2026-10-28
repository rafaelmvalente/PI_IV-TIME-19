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
  const LoginScreen({super.key, this.loginInicial});

  final String? loginInicial;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _verde = Color(0xFF1E7B58);
  static const Color _borda = Color(0xFFD5DBD8);

  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _ocultarSenha = true;

  @override
  void initState() {
    super.initState();

    // Permite preencher o campo de login quando outra tela
    // envia o e-mail ou telefone pelo parâmetro loginInicial.
    _loginController.text = widget.loginInicial ?? '';
  }

  @override
  void dispose() {
    // Libera os controladores quando a tela deixa de existir.
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  void _abrirDashboard({Propriedade? propriedade}) {
    // Substitui a tela de login pelo dashboard.
    // Assim, o botão de voltar não retorna ao login após entrar.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(propriedade: propriedade),
      ),
    );
  }

  Future<void> _entrar() async {
    // Valida os campos antes de conferir os dados da conta.
    if (!_formKey.currentState!.validate()) return;

    final conta = AuthService.entrar(
      _loginController.text,
      _senhaController.text,
    );

    if (conta == null) {
      _mostrarMensagem('E-mail/telefone ou senha incorretos');
      return;
    }

    if (!mounted) return;

    // Se a conta já possui propriedade cadastrada, abre o dashboard.
    // Caso contrário, pergunta se o usuário deseja cadastrar uma.
    if (conta.temPropriedade) {
      _abrirDashboard();
    } else {
      await _perguntarCadastroPropriedade(conta);
    }
  }

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
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (querCadastrar == true) {
      // Abre o cadastro e espera receber a propriedade salva.
      final propriedade = await Navigator.of(context).push<Propriedade>(
        MaterialPageRoute(
          builder: (_) => const CadastroPropriedadeScreen(),
        ),
      );

      if (!mounted) return;

      // Se o usuário voltar sem salvar a propriedade,
      // permanece na tela de login.
      if (propriedade == null) return;

      AuthService.marcarPropriedadeCadastrada(conta);

      _abrirDashboard(propriedade: propriedade);
      return;
    }

    // Se o usuário escolher "Agora não", segue para o dashboard
    // sem uma propriedade carregada nesta navegação.
    if (querCadastrar == false) {
      _abrirDashboard();
    }
  }

  Future<void> _criarConta() async {
    // Abre a tela de criação de conta e espera seu resultado.
    final resultado =
        await Navigator.of(context).push<CriarContaResultado>(
      MaterialPageRoute(
        builder: (_) => const CriarContaScreen(),
      ),
    );

    if (!mounted || resultado == null) return;

    // Se o usuário clicou em "Já tenho uma conta", o cadastro
    // apenas fecha. O login atual já está aberto, então não
    // precisamos abrir outra instância da tela de login.
    if (resultado.irParaLogin) return;

    // Quando a conta é criada, recebe o e-mail ou telefone.
    final login = resultado.login;
    if (login == null) return;

    // Preenche o login e limpa a senha para que o usuário a digite.
    _loginController.text = login;
    _senhaController.clear();

    _mostrarMensagem(
      'Conta criada! Digite sua senha para entrar.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                          ),
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
                                    if (valor == null ||
                                        valor.trim().isEmpty) {
                                      return 'Informe seu e-mail ou telefone';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _senhaController,
                                  obscureText: _ocultarSenha,
                                  decoration: _decoracao(
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
                                        setState(() {
                                          _ocultarSenha = !_ocultarSenha;
                                        });
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
                                    onPressed: () {
                                      _mostrarMensagem('Em breve');
                                    },
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
                                      side: const BorderSide(
                                        color: _verde,
                                      ),
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

  InputDecoration _decoracao(String dica, IconData icone) {
    // Define o formato e as cores das bordas dos campos.
    OutlineInputBorder borda(Color cor) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cor),
        );

    return InputDecoration(
      hintText: dica,
      prefixIcon: Icon(
        icone,
        color: Colors.grey.shade600,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: borda(_borda),
      focusedBorder: borda(_verde),
      errorBorder: borda(Colors.red.shade400),
      focusedErrorBorder: borda(Colors.red.shade400),
    );
  }

  Widget _buildLogo() {
    // O ClipRect e o Align exibem apenas a parte central da imagem do logo,
    // reduzindo o espaço transparente que existe no arquivo original.
    return ClipRect(
      child: Align(
        heightFactor: 0.5,
        child: Image.asset(
          'assets/images/logo PI4.png',
          width: 170,
        ),
      ),
    );
  }
}
