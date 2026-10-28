// Rafael Mendes Valente - 25002875
// Data: 07/10/26
// Horário: 19h15 - 23h15
// Descrição: Tela inicial do aplicativo. Exibe o
// logo e o nome, com o botão
// "Começar" (cadastro da propriedade) e o link "Já tenho uma conta" (login)

import 'package:flutter/material.dart';
import 'cadastro_propriedade_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // Cores usadas na tela
  static const Color _verdeBotao = Color(0xFF1E7B58);

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
            // BoxFit.cover preenche a tela inteira sem distorcer a foto.
            // O colorFilter escurece a imagem para o texto branco ficar
            // legível sobre o céu claro
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/foto.Squash.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(90),
                  BlendMode.darken,
                ),
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
                    const Spacer(flex: 2),
                    _buildLogo(),
                    const SizedBox(height: 8),
                    const Text(
                      'ClimAlerta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                    const Spacer(flex: 5),
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
                        // O async/await faz o app esperar o usuário terminar
                        // o cadastro. A tela de cadastro devolve a
                        // Propriedade no pop; se o usuário voltar sem salvar,
                        // o resultado é null e nada acontece.
                        onPressed: () async {
                          final propriedade = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CadastroPropriedadeScreen(),
                            ),
                          );
                          // context.mounted confere se a tela ainda existe
                          // depois da espera, antes de usar o context.
                          if (propriedade == null || !context.mounted) return;
                          // pushReplacement troca a splash pelo dashboard,
                          // então o botão voltar não retorna para ela.
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              // Envia a propriedade cadastrada para o
                              // dashboard mostrar o nome dela.
                              builder: (_) =>
                                  DashboardScreen(propriedade: propriedade),
                            ),
                          );
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
                        'Criar conta / Já tenho uma conta',
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
    // O desenho ocupa só a faixa do meio da imagem; o resto é margem
    // transparente. O Align com heightFactor: 0.5 mostra apenas a metade
    // central da altura e o ClipRect corta o que sobra, deixando o nome
    // logo abaixo do desenho. Para mudar o tamanho, altere o width.
    return ClipRect(
      child: Align(
        heightFactor: 0.5,
        child: Image.asset(
          'assets/images/logo PI4.png',
          width: 250,
        ),
      ),
    );
  }
}
