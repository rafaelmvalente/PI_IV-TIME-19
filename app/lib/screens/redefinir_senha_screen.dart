// Caique Vasconcelos Naimi - 25004208
// Data: 17/11/2026
// Descrição: Tela para criar a senha nova. O produtor cola o link que recebeu
// por e-mail (ou só o código dele) e digita a senha nova duas vezes. Quem abre
// a tela passa em [onRedefinir] a chamada AuthService.redefinirSenha.

import 'package:flutter/material.dart';

import '../services/api_client.dart';

class RedefinirSenhaScreen extends StatefulWidget {
  const RedefinirSenhaScreen({super.key, required this.onRedefinir});

  final Future<void> Function(String token, String novaSenha) onRedefinir;

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

// O e-mail manda um link com ?token=...; aceita o link inteiro ou só o código.
String extrairToken(String texto) {
  final limpo = texto.trim();
  return Uri.tryParse(limpo)?.queryParameters['token'] ?? limpo;
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _ocultarSenha = true;
  bool _salvando = false;
  bool _alterada = false;
  String? _erro;

  @override
  void dispose() {
    _codigo.dispose();
    _senha.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  String? _validarCodigo(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Cole o link ou o código que chegou no e-mail';
    // O backend gera códigos de 64 caracteres e recusa menos de 32.
    if (extrairToken(texto).length < 32) {
      return 'Link incompleto. Copie o link inteiro do e-mail';
    }
    return null;
  }

  String? _validarSenha(String? valor) {
    final senha = valor ?? '';
    if (senha.length < 8) return 'A senha precisa ter pelo menos 8 caracteres';
    if (senha.length > 128) return 'A senha pode ter no máximo 128 caracteres';
    return null;
  }

  String? _validarConfirmacao(String? valor) =>
      valor == _senha.text ? null : 'As senhas não são iguais';

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.onRedefinir(extrairToken(_codigo.text), _senha.text);
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _alterada = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = _mensagemDeErro(error);
      });
    }
  }

  String _mensagemDeErro(Object error) {
    if (error is ApiException && error.code == 'INVALID_RESET_TOKEN') {
      return 'Este link expirou ou já foi usado. Ele vale por 15 minutos. '
          'Volte e peça um link novo.';
    }
    if (error is ApiException && error.statusCode == 0) {
      return 'Sem conexão com a internet. Confira e tente de novo.';
    }
    return 'Não foi possível trocar a senha agora. Tente de novo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar senha nova')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _alterada ? _buildSucesso(context) : _buildFormulario(context),
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
          Text('Criar senha nova', style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Copie o link que enviamos para o seu e-mail e cole abaixo. '
            'Depois digite a senha nova duas vezes.',
            style: textTheme.bodyLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codigo,
            enabled: !_salvando,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Link ou código do e-mail',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            validator: _validarCodigo,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _senha,
            enabled: !_salvando,
            obscureText: _ocultarSenha,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Senha nova',
              helperText: 'Pelo menos 8 caracteres',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _ocultarSenha ? 'Mostrar senha' : 'Esconder senha',
                icon: Icon(
                  _ocultarSenha
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
              ),
            ),
            validator: _validarSenha,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmacao,
            enabled: !_salvando,
            obscureText: _ocultarSenha,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Repita a senha nova',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
            validator: _validarConfirmacao,
            onFieldSubmitted: (_) => _salvar(),
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
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Text('Salvar senha nova', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildSucesso(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.check_circle_outline, size: 72, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          'Senha alterada',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Pronto! Agora entre com a sua senha nova.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 32),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          // Devolve true para a tela de recuperação também fechar.
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Voltar para o login', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
