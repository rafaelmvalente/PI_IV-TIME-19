// Rafael Mendes Valente - 25002875
// Data: 28/10/2026
// Horário: 7h - 14h
// Descrição: Tela de criação de conta do aplicativo ClimAlerta. O produtor
// informa e-mail ou telefone, senha e confirmação de senha. Ao criar a conta,
// a tela devolve o e-mail/telefone cadastrado para que o login seja preenchido.
// Se o usuário já possuir uma conta, a tela informa que deve seguir para o login.
// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Envia o cadastro do produtor para a API de autenticação.

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class CriarContaResultado {
  final String? login;
  final bool irParaLogin;

  // Resultado usado quando uma conta é criada com sucesso.
  const CriarContaResultado.contaCriada(String valor)
    : login = valor,
      irParaLogin = false;

  // Resultado usado quando o usuário já possui uma conta.
  const CriarContaResultado.irParaLogin() : login = null, irParaLogin = true;
}

class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({super.key});

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  static const Color _verde = Color(0xFF1E7B58);
  static const Color _borda = Color(0xFFD5DBD8);

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  final _authService = AuthService();

  bool _ocultarSenha = true;
  bool _criando = false;

  @override
  void dispose() {
    // Libera os controladores quando a tela deixa de existir.
    _nomeController.dispose();
    _loginController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    // Valida os campos antes de tentar criar a conta.
    if (!_formKey.currentState!.validate()) return;

    final login = _loginController.text.trim();

    setState(() => _criando = true);
    try {
      await _authService.criarConta(
        nome: _nomeController.text.trim(),
        login: login,
        senha: _senhaController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(CriarContaResultado.contaCriada(login));
    } on ApiException catch (error) {
      if (!mounted) return;
      final message = error.code == 'DUPLICATE'
          ? 'Já existe uma conta com esse e-mail ou telefone.'
          : error.message;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível criar a conta: $error')),
      );
    } finally {
      if (mounted) setState(() => _criando = false);
    }
  }

  void _irParaLogin() {
    // Não navega diretamente para LoginScreen.
    // Apenas devolve o resultado para a tela anterior, que decide o destino.
    //
    // Se o cadastro foi aberto pela splash, a splash abre o login.
    // Se foi aberto pelo login, o login atual permanece aberto.
    Navigator.of(context).pop(const CriarContaResultado.irParaLogin());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // A seta volta à tela que abriu o cadastro.
                    // Ela não indica que o usuário já possui uma conta.
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Criar conta',
                      style: TextStyle(
                        color: _verde,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Informe seus dados para começar a receber alertas.',
                      style: TextStyle(color: Color(0xFF2B3A33), fontSize: 15),
                    ),

                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _nomeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoracao(
                        'Nome completo',
                        Icons.person_outline,
                      ),
                      validator: (valor) {
                        if ((valor ?? '').trim().length < 2) {
                          return 'Informe seu nome';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

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
                      decoration: _decoracao('Senha', Icons.lock_outline)
                          .copyWith(
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
                          return 'Informe uma senha';
                        }
                        if (valor.length < 8) {
                          return 'A senha deve ter pelo menos 8 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _confirmarController,
                      obscureText: _ocultarSenha,
                      decoration: _decoracao(
                        'Confirmar senha',
                        Icons.lock_outline,
                      ),
                      // O validator pode consultar outro campo: aqui compara
                      // a confirmação com o texto digitado na senha.
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return 'Confirme sua senha';
                        }
                        if (valor != _senhaController.text) {
                          return 'As senhas não conferem';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

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
                        onPressed: _criando ? null : _criar,
                        child: const Text(
                          'Criar conta',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Informa à tela anterior que o usuário quer entrar.
                    // O comportamento muda conforme a tela que abriu o cadastro.
                    Center(
                      child: TextButton(
                        onPressed: _irParaLogin,
                        child: const Text(
                          'Já tenho uma conta',
                          style: TextStyle(
                            color: _verde,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: _verde,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracao(String dica, IconData icone) {
    // Cria as bordas dos campos para manter o padrão visual da tela.
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
}
