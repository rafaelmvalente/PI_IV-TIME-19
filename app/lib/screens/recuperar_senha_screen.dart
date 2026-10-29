// Caio Ávila Marchi - 25008101
// Data: 28/10/2026
// Descrição: Tela de recuperação de senha. O produtor informa o e-mail ou
// telefone da conta e recebe o link para criar uma senha nova. Quem abre a
// tela passa em [onEnviar] a chamada que faz o envio (AuthService.recuperarSenha).
// Sem [onEnviar], a tela avisa que o serviço não está disponível.

import 'package:flutter/material.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key, this.loginInicial, this.onEnviar});

  /// E-mail ou telefone já digitado na tela de login.
  final String? loginInicial;
  final Future<void> Function(String login)? onEnviar;

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _login;
  bool _enviando = false;
  bool _enviado = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _login = TextEditingController(text: widget.loginInicial ?? '');
  }

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  String? _validarLogin(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Digite o e-mail ou telefone da sua conta';

    final ehEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    final ehTelefone =
        !texto.contains('@') && digitos.length >= 10 && digitos.length <= 13;

    return (ehEmail || ehTelefone) ? null : 'Digite um e-mail ou telefone válido';
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final enviar = widget.onEnviar;
    if (enviar == null) {
      setState(() {
        _erro = 'Este serviço ainda não está disponível. '
            'Tente novamente mais tarde.';
      });
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await enviar(_login.text.trim());
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _enviado = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro = 'Não foi possível enviar agora. '
            'Confira sua internet e tente de novo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _enviado ? _buildConfirmacao(context) : _buildFormulario(context),
        ),
      ),
    );
  }

  Widget _buildFormulario(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Esqueceu sua senha?', style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Digite o e-mail ou telefone da sua conta. Vamos enviar um link '
            'para você criar uma senha nova.',
            style: textTheme.bodyLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _login,
            enabled: !_enviando,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'E-mail ou telefone',
              prefixIcon: Icon(Icons.mail_outline),
              border: OutlineInputBorder(),
            ),
            validator: _validarLogin,
            onFieldSubmitted: (_) => _enviar(),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _erro!,
                      style: TextStyle(fontSize: 16, color: scheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Text(
                    'Enviar link de recuperação',
                    style: TextStyle(fontSize: 18),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmacao(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.mark_email_read_outlined, size: 72, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          'Verifique seu e-mail ou telefone',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Se existir uma conta com ${_login.text.trim()}, enviamos o link '
          'para criar uma senha nova. Olhe também a caixa de spam.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 32),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar para o login', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
