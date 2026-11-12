// Rafael Mendes Valente - 25002875
// Data: 07/10/26
// Horário: 19h15 - 23h15
// Descrição: Tela inicial do aplicativo. Exibe o logo e o nome,
// com o botão "Começar" e o link para login.
// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Direciona o início para autenticação antes de usar APIs privadas.

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../session/sessao.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _verdeBotao = Color(0xFF1E7B58);

  @override
  void initState() {
    super.initState();
    _restaurarSessao();
  }

  Future<void> _restaurarSessao() async {
    try {
      final conta = await AuthService().restaurarSessao();
      if (!mounted || conta == null) return;

      SessaoScope.of(context).entrar(
        login: conta.login,
        usuario: conta.usuario,
        token: conta.token,
        propriedade: conta.propriedade,
        preferencias: conta.usuario.preferencias,
      );
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(propriedade: conta.propriedade),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2A1F),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            width: double.infinity,
            height: double.infinity,
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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
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
                      'Alertas climáticos hiperlocais\n'
                      'para pequenos produtores rurais',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(230),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(flex: 5),
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
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
    return ClipRect(
      child: Align(
        heightFactor: 0.5,
        child: Image.asset('assets/images/logo PI4.png', width: 250),
      ),
    );
  }
}
