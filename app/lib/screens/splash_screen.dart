// Rafael Mendes Valente - 25002875
// Data: 07/10/26
// Horário: 19h15 - 23h15
// Descrição: Tela inicial do aplicativo. Exibe o
// logo e o nome, com o botão
// "Começar" (cadastro da propriedade) e o link "Já tenho uma conta" (login)

import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // Cores usadas na tela
  static const Color _verdeBotao = Color(0xFF1E7B58);
  static const Color _verdeFolha = Color(0xFF6FBF73);
  static const Color _amareloSol = Color(0xFFF2C94C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2A1F),
      body: Center(
        // Limita a largura e o Center deixa a tela
        // centralizada, simulando um celular
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF5C7F96),
                  Color(0xFFC9A27A),
                  Color(0xFF4F6B3A),
                  Color(0xFF1F3320),
                ],
                stops: [0.0, 0.45, 0.7, 1.0],
              ),
            ),
            // SafeArea evita que o conteúdo fique embaixo da
            // barra de status do celular
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    // Os Spacers dividem o espaço livre da tela de forma
                    // proporcional. Assim o logo fica na
                    // parte de cima e os botões na parte de baixo
                    const Spacer(flex: 3),
                    _buildLogo(),
                    const SizedBox(height: 12),
                    const Text(
                      'ClimAlerta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Alertas climáticos hiperlocais\npara pequenos produtores rurais',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        // withAlpha(230) deixa o branco levemente
                        // transparente (0 a 255), suavizando o texto.
                        color: Colors.white.withAlpha(230),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(flex: 4),
                    // Botão principal. O SizedBox com width: double.infinity
                    // faz o botão ocupar toda a largura disponível.
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _verdeBotao,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                        },
                        child: const Text(
                          'Começar',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      // Navigator.push coloca a tela de login por cima da
                      // splash. O botão de voltar retorna para a splash.
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Já tenho uma conta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: _amareloSol,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            child: Icon(Icons.eco, size: 72, color: _verdeFolha),
          ),
        ],
      ),
    );
  }
}
