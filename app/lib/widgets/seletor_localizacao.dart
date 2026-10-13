// Vinicius Santuci Virgolino - 25000294
// Data: 13/10/26
// Descrição: Cartão que mostra a localização da propriedade e o botão para
// capturá-la pelo GPS. Exibe os estados: sem localização, buscando,
// localização registrada e erro.

import 'package:flutter/material.dart';

import '../models/coordenada.dart';
import '../theme/app_colors.dart';

class SeletorLocalizacao extends StatelessWidget {
  const SeletorLocalizacao({
    super.key,
    required this.localizacao,
    required this.carregando,
    required this.onBuscar,
    this.mensagemErro,
  });

  final Coordenada? localizacao;
  final bool carregando;
  final VoidCallback onBuscar;
  final String? mensagemErro;

  @override
  Widget build(BuildContext context) {
    final temErro = mensagemErro != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: temErro ? AppColors.erro : AppColors.borda,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusLocalizacao(localizacao: localizacao),
              const SizedBox(height: 12),
              _BotaoLocalizacao(
                carregando: carregando,
                jaPossuiLocalizacao: localizacao != null,
                onPressed: onBuscar,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          mensagemErro ??
              'Faça o cadastro estando na propriedade para que os alertas '
                  'sejam precisos.',
          style: TextStyle(
            fontSize: 12,
            color: temErro ? AppColors.erro : AppColors.textoSecundario,
          ),
        ),
      ],
    );
  }
}

class _StatusLocalizacao extends StatelessWidget {
  const _StatusLocalizacao({required this.localizacao});

  final Coordenada? localizacao;

  @override
  Widget build(BuildContext context) {
    final registrada = localizacao != null;

    return Row(
      children: [
        Icon(
          registrada ? Icons.check_circle : Icons.location_on_outlined,
          color: registrada ? AppColors.verde : AppColors.textoSecundario,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                registrada
                    ? 'Localização registrada'
                    : 'Nenhuma localização definida',
                style: const TextStyle(
                  color: AppColors.textoEscuro,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (registrada)
                Text(
                  localizacao!.descricao,
                  style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BotaoLocalizacao extends StatelessWidget {
  const _BotaoLocalizacao({
    required this.carregando,
    required this.jaPossuiLocalizacao,
    required this.onPressed,
  });

  final bool carregando;
  final bool jaPossuiLocalizacao;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.verde,
          side: const BorderSide(color: AppColors.verde),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: carregando ? null : onPressed,
        icon: carregando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: Text(
          carregando
              ? 'Buscando localização...'
              : jaPossuiLocalizacao
                  ? 'Atualizar localização'
                  : 'Usar minha localização',
        ),
      ),
    );
  }
}