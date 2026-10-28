
 // Rafael Mendes Valente - 25002875
// Data: 08/10/26
// Horário: 00h00 - 06h00
// Descrição: Tela de login do aplicativo ClimAlerta.

import 'package:flutter/material.dart';
import 'cadastro_propriedade_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _entrar() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CadastroPropriedadeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
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
                                onPressed: () {},
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
                                onPressed: () {},
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
    );
  }

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

  Widget _buildLogo() {
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
