// Rafael Mendes Valente - 25002875
// Data: 08/10/26
// Horário: 00h00 - 06h00
// Descrição: Tela de login do aplicativo ClimAlerta. Contém os campos de
// e-mail/telefone e senha (com opção de mostrar/ocultar a senha), o link
// "Esqueceu sua senha?", o botão "Entrar" e o botão "Criar conta"

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _verde = Color(0xFF1E7B58);
  static const Color _verdeFolha = Color(0xFF6FBF73);
  static const Color _amareloSol = Color(0xFFF2C94C);
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

  void _entrar() {
    // validate() executa o "validator" de cada campo e retorna false se
    // algum deles devolver uma mensagem de erro
    if (_formKey.currentState!.validate()) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          // Stack: o desenho dos morros fica no fundo e o formulário por cima
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _Morros(),
              ),
              // SingleChildScrollView evita o erro de "overflow" quando o
              // teclado abre e diminui a área visível da tela
              SafeArea(
                child: SingleChildScrollView(
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
                        const SizedBox(height: 32),
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
                                setState(() => _ocultarSenha = !_ocultarSenha);
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
                        const Text('ou', style: TextStyle(color: Colors.grey)),
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
                            onPressed: () {
                            },
                            child: const Text(
                              'Criar conta',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

  /// Logo menor que o da splash: sol amarelo atrás de uma folha verde.
  Widget _buildLogo() {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 2,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _amareloSol,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            child: Icon(Icons.eco, size: 60, color: _verdeFolha),
          ),
        ],
      ),
    );
  }
}

/// Desenho decorativo dos morros no rodapé da tela.
class _Morros extends StatelessWidget {
  const _Morros();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 170,
      width: double.infinity,
      child: CustomPaint(painter: _MorrosPainter()),
    );
  }
}

class _MorrosPainter extends CustomPainter {
  const _MorrosPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final morroDeTras = Path()
      ..moveTo(0, h * 0.45)
      ..quadraticBezierTo(w * 0.25, h * 0.05, w * 0.55, h * 0.40)
      ..quadraticBezierTo(w * 0.80, h * 0.62, w, h * 0.30)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final morroDaFrente = Path()
      ..moveTo(0, h * 0.75)
      ..quadraticBezierTo(w * 0.30, h * 0.50, w * 0.60, h * 0.72)
      ..quadraticBezierTo(w * 0.85, h * 0.88, w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    // A ordem importa: o que é desenhado depois fica por cima.
    canvas.drawPath(morroDeTras, Paint()..color = const Color(0xFFCFE8D5));
    canvas.drawPath(morroDaFrente, Paint()..color = const Color(0xFFA9D3B4));
  }

  // As cores e formas nunca mudam, então não precisa redesenhar.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
