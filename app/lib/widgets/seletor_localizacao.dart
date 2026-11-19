// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 13/10/2026
// Descrição: Cartão que mostra a localização da propriedade e os botões para
// capturá-la pelo GPS ou marcá-la no mapa. Exibe os estados: sem
// localização, buscando, localização registrada e erro.

import 'package:flutter/material.dart';

import '../models/coordenada.dart';
import '../theme/app_colors.dart';

// Cartão usado na tela de cadastro da propriedade.
// É StatelessWidget: não guarda nada. Quem controla os dados (localização,
// carregando, erro) é a tela de cadastro, que redesenha o cartão quando
// algo muda. Os botões só avisam a tela pelos callbacks (onBuscar e
// onMarcarNoMapa).
class SeletorLocalizacao extends StatelessWidget {
  const SeletorLocalizacao({
    super.key,
    required this.localizacao,
    required this.carregando,
    required this.onBuscar,
    required this.onMarcarNoMapa,
    this.mensagemErro,
  });

  // Local já escolhido. Nulo enquanto o produtor não definiu a localização.
  final Coordenada? localizacao;
  // true enquanto o GPS está buscando: desativa os botões e mostra a rodinha.
  final bool carregando;
  // Chamado ao tocar em "Usar minha localização" (GPS).
  final VoidCallback onBuscar;
  // Alternativa para quando o GPS falha ou o produtor não está na propriedade.
  final VoidCallback onMarcarNoMapa;
  // Texto do erro do GPS. Quando vem preenchido, o cartão fica vermelho.
  final String? mensagemErro;

  @override
  Widget build(BuildContext context) {
    // Atalho usado em várias partes abaixo para pintar o cartão de vermelho.
    final temErro = mensagemErro != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caixa branca com borda: cinza no normal, vermelha quando há erro.
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
            // stretch: os botões ocupam toda a largura do cartão.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Linha de cima: ícone + "Localização registrada" ou "Nenhuma...".
              _StatusLocalizacao(localizacao: localizacao),
              const SizedBox(height: 12),
              // Botão principal: pega a localização pelo GPS.
              _BotaoLocalizacao(
                carregando: carregando,
                jaPossuiLocalizacao: localizacao != null,
                onPressed: onBuscar,
              ),
              const SizedBox(height: 8),
              // Botão secundário: abre o mapa para marcar o local com o dedo.
              SizedBox(
                height: 44,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.verde,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // onPressed nulo desativa o botão: não deixa abrir o mapa
                  // enquanto o GPS ainda está buscando.
                  onPressed: carregando ? null : onMarcarNoMapa,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Marcar no mapa'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Texto pequeno embaixo do cartão: mostra o erro, se houver
        // (o operador ?? usa a dica quando mensagemErro é nula).
        Text(
          mensagemErro ??
              'Use o GPS estando na propriedade ou marque o local no mapa '
                  'para que os alertas sejam precisos.',
          style: TextStyle(
            fontSize: 12,
            color: temErro ? AppColors.erro : AppColors.textoSecundario,
          ),
        ),
      ],
    );
  }
}

// Parte de cima do cartão: diz se já existe localização e mostra as
// coordenadas. O "_" no nome deixa a classe visível só neste arquivo.
class _StatusLocalizacao extends StatelessWidget {
  const _StatusLocalizacao({required this.localizacao});

  final Coordenada? localizacao;

  @override
  Widget build(BuildContext context) {
    final registrada = localizacao != null;

    return Row(
      children: [
        // Ícone de "ok" verde quando já tem local; pino cinza quando não tem.
        Icon(
          registrada ? Icons.check_circle : Icons.location_on_outlined,
          color: registrada ? AppColors.verde : AppColors.textoSecundario,
        ),
        const SizedBox(width: 10),
        // Expanded: o texto ocupa o resto da linha e quebra se for longo.
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
              // As coordenadas só aparecem quando existem. O "!" é seguro
              // aqui porque o "if (registrada)" já garantiu que não é nulo.
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

// Botão do GPS. Muda o texto e o ícone conforme o estado:
// - buscando: rodinha girando e "Buscando localização...";
// - já tem local: "Atualizar localização";
// - ainda não tem: "Usar minha localização".
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
      // OutlinedButton: botão só com contorno verde, sem fundo.
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.verde,
          side: const BorderSide(color: AppColors.verde),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // Desativado enquanto busca, para não abrir duas buscas de GPS.
        onPressed: carregando ? null : onPressed,
        // Durante a busca, troca o ícone por uma rodinha de carregamento.
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
