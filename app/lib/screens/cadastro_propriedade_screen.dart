// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 13/10/2026
// Descrição: Tela de cadastro da propriedade do ClimAlerta. Contém os campos
// de nome da propriedade, tipo de cultivo, estágio da lavoura (opcional),
// tamanho da área (opcional) e a localização obtida pelo GPS ou marcada no
// mapa, a ilustração da paisagem rural e o botão "Salvar". Ao salvar,
// devolve a Propriedade preenchida para a tela anterior.

import 'package:flutter/material.dart';
// services.dart: formatadores que limitam o que pode ser digitado nos campos.
import 'package:flutter/services.dart';

import '../models/coordenada.dart';
import '../models/estagio_lavoura.dart';
import '../models/propriedade.dart';
import '../services/localizacao_service.dart';
import '../theme/app_colors.dart';
import '../widgets/seletor_localizacao.dart';
import 'selecionar_local_mapa_screen.dart';

// StatefulWidget: a tela guarda o que o produtor vai preenchendo.
class CadastroPropriedadeScreen extends StatefulWidget {
  const CadastroPropriedadeScreen({
    super.key,
    this.localizacaoService = const LocalizacaoService(),
  });

  // Serviço do GPS. Recebido pelo construtor para os testes poderem passar
  // um GPS falso; no app, usa o de verdade (valor padrão acima).
  final LocalizacaoService localizacaoService;

  @override
  State<CadastroPropriedadeScreen> createState() =>
      _CadastroPropriedadeScreenState();
}

class _CadastroPropriedadeScreenState extends State<CadastroPropriedadeScreen> {
  // Limites do nome da propriedade.
  static const int _tamanhoMinimoNome = 3;
  static const int _tamanhoMaximoNome = 60;

  // Chave do formulário: permite validar todos os campos de uma vez.
  final _formKey = GlobalKey<FormState>();
  // Guardam o texto digitado nos campos de nome e de área.
  final _nomeController = TextEditingController();
  final _areaController = TextEditingController();
  // Chave do campo de localização: permite ler a coordenada escolhida
  // na hora de salvar.
  final _localizacaoKey = GlobalKey<FormFieldState<Coordenada>>();

  // Escolhas das listas (nulas até o produtor escolher).
  TipoCultivo? _cultivo;
  EstagioLavoura? _estagio;
  // true enquanto o GPS está buscando (mostra a rodinha no botão).
  bool _buscandoLocalizacao = false;
  // Erro vindo do GPS (ex.: permissão negada), mostrado no cartão.
  String? _erroLocalizacao;

  // Ao fechar a tela, libera os controllers da memória.
  @override
  void dispose() {
    _nomeController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  // ---------- Validações ----------
  // Cada validador devolve o texto do erro ou null quando está tudo certo.
  // O Form chama todos eles ao apertar "Salvar".

  // Nome obrigatório e com pelo menos 3 letras.
  String? _validarNome(String? valor) {
    // trim() tira espaços: "   " conta como vazio.
    final nome = valor?.trim() ?? '';
    if (nome.isEmpty) return 'Informe o nome da propriedade';
    if (nome.length < _tamanhoMinimoNome) {
      return 'O nome deve ter pelo menos $_tamanhoMinimoNome letras';
    }
    return null;
  }

  // Cultivo obrigatório: o backend precisa dele para calcular o risco.
  String? _validarCultivo(TipoCultivo? valor) {
    return valor == null ? 'Selecione o tipo de cultivo' : null;
  }

  // Área é opcional: vazia passa. Preenchida, precisa ser um número maior que 0.
  String? _validarArea(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return null;
    final area = _converterArea(texto);
    if (area == null || area <= 0) return 'Informe uma área válida';
    return null;
  }

  // Localização obrigatória: sem ela não há como buscar a previsão do tempo.
  String? _validarLocalizacao(Coordenada? valor) {
    return valor == null ? 'Registre a localização da propriedade' : null;
  }

  // Converte o texto da área em número. Aceita vírgula (padrão brasileiro,
  // "2,5") trocando por ponto ("2.5"), que é o que o Dart entende.
  // tryParse devolve null em vez de dar erro se o texto não for número.
  double? _converterArea(String texto) {
    if (texto.trim().isEmpty) return null;
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  // ---------- Localização ----------

  // Botão "Usar minha localização": pede a posição ao GPS e coloca no campo.
  // "campo" é o FormField da localização, onde a coordenada fica guardada.
  Future<void> _buscarLocalizacao(FormFieldState<Coordenada> campo) async {
    // Liga a rodinha e apaga o erro da tentativa anterior.
    setState(() {
      _buscandoLocalizacao = true;
      _erroLocalizacao = null;
    });

    try {
      final coordenada = await widget.localizacaoService
          .obterLocalizacaoAtual();
      // A tela pode ter sido fechada enquanto o GPS buscava.
      if (!mounted) return;
      // didChange grava a coordenada no campo; validate() tira a mensagem
      // de "Registre a localização" se ela estava aparecendo.
      campo.didChange(coordenada);
      campo.validate();
    } on LocalizacaoException catch (erro) {
      // Erros conhecidos (GPS desligado, permissão negada, demora):
      // mostra a mensagem pronta do serviço.
      if (!mounted) return;
      setState(() => _erroLocalizacao = erro.mensagem);
    } on Exception {
      // Qualquer outro erro inesperado do GPS: mensagem genérica.
      if (!mounted) return;
      setState(() {
        _erroLocalizacao =
            'Não foi possível obter a localização. '
            'Tente novamente.';
      });
    } finally {
      // Com sucesso ou erro, desliga a rodinha.
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  // Alternativa ao GPS: a tela do mapa devolve uma Coordenada, o mesmo tipo
  // que o GPS devolve, então o resto do cadastro não muda.
  Future<void> _marcarNoMapa(FormFieldState<Coordenada> campo) async {
    // Abre a tela do mapa e espera ela fechar. Se já existe localização,
    // o mapa abre nela.
    final coordenada = await Navigator.of(context).push<Coordenada>(
      MaterialPageRoute(
        builder: (_) =>
            SelecionarLocalMapaScreen(localizacaoInicial: campo.value),
      ),
    );
    // null = o produtor voltou sem confirmar: mantém o que já estava.
    if (coordenada == null || !mounted) return;
    // Um local escolhido no mapa resolve qualquer erro anterior do GPS.
    setState(() => _erroLocalizacao = null);
    campo.didChange(coordenada);
    campo.validate();
  }

  // ---------- Salvar ----------

  // Valida o formulário e, se estiver tudo certo, devolve a Propriedade
  // para a tela que abriu o cadastro (quem envia para a API é ela).
  void _salvar() {
    // Fecha o teclado.
    FocusScope.of(context).unfocus();
    // Roda todos os validadores; se algum falhar, as mensagens aparecem
    // embaixo dos campos e o cadastro não continua.
    if (!_formKey.currentState!.validate()) return;

    // Os "!" são seguros: a validação acima garantiu que cultivo e
    // localização foram preenchidos.
    final propriedade = Propriedade(
      nome: _nomeController.text.trim(),
      cultivo: _cultivo!,
      localizacao: _localizacaoKey.currentState!.value!,
      areaHectares: _converterArea(_areaController.text),
      estagio: _estagio,
    );

    // Fecha a tela levando a propriedade preenchida.
    Navigator.of(context).pop(propriedade);
  }

  // ---------- Tela ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      // Barra de cima com o título e a seta de voltar.
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        // Evita a barra mudar de cor quando o conteúdo rola por baixo.
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textoEscuro,
        elevation: 0,
        title: const Text(
          'Cadastrar propriedade',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      // Form: agrupa os campos para validar todos juntos com o _formKey.
      body: _layoutComPaisagem(
        Form(
          key: _formKey,
          child: Column(
            // stretch: os campos ocupam toda a largura.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // Campos na ordem em que aparecem, com espaços entre eles.
            children: [
              _textoIntroducao(),
              const SizedBox(height: 24),
              _campoNome(),
              const SizedBox(height: 20),
              _campoCultivo(),
              const SizedBox(height: 20),
              _campoEstagio(),
              const SizedBox(height: 20),
              _campoArea(),
              const SizedBox(height: 20),
              _campoLocalizacao(),
              const SizedBox(height: 32),
              _botaoSalvar(),
            ],
          ),
        ),
      ),
    );
  }

  // Mesmo esquema da tela de login: o minHeight faz a coluna ocupar no
  // mínimo a tela inteira e o spaceBetween empurra a paisagem para o fundo.
  // Em telas baixas ela fica depois do botão "Salvar" e rola junto, sem
  // sobrepor.
  Widget _layoutComPaisagem(Widget formulario) {
    return SafeArea(
      child: Center(
        // Largura máxima de 430: no computador ou tablet o formulário não
        // fica esticado de ponta a ponta da tela.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          // LayoutBuilder informa a altura disponível (constraints.maxHeight).
          child: LayoutBuilder(
            // SingleChildScrollView: permite rolar quando o teclado abre ou
            // a tela é pequena.
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
                      child: formulario,
                    ),
                    // Ilustração dos morros no rodapé, na largura toda.
                    Image.asset(
                      'assets/images/paisagem_morros.png',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Frase de apresentação no topo do formulário.
  Widget _textoIntroducao() {
    return const Text(
      'Informe os dados da sua propriedade para receber alertas '
      'personalizados.',
      style: TextStyle(
        color: AppColors.textoSecundario,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  // Campo de texto do nome da propriedade.
  Widget _campoNome() {
    return _CampoComRotulo(
      rotulo: 'Nome da propriedade',
      child: TextFormField(
        controller: _nomeController,
        // Deixa maiúscula a primeira letra de cada palavra ("Sítio Boa Vista").
        textCapitalization: TextCapitalization.words,
        // O "Enter" do teclado pula para o próximo campo.
        textInputAction: TextInputAction.next,
        // Não deixa digitar mais que 60 caracteres.
        inputFormatters: [LengthLimitingTextInputFormatter(_tamanhoMaximoNome)],
        decoration: _decoracao('Ex.: Sítio Boa Vista'),
        validator: _validarNome,
      ),
    );
  }

  // Lista de escolha do tipo de cultivo (obrigatório).
  Widget _campoCultivo() {
    return _CampoComRotulo(
      rotulo: 'Tipo de cultivo',
      child: DropdownButtonFormField<TipoCultivo>(
        initialValue: _cultivo,
        // A lista ocupa toda a largura do campo.
        isExpanded: true,
        hint: const Text('Selecione o tipo de cultivo'),
        icon: const Icon(Icons.keyboard_arrow_down),
        decoration: _decoracao(null),
        // Uma opção para cada valor do enum TipoCultivo, mostrando o rótulo.
        items: [
          for (final cultivo in TipoCultivo.values)
            DropdownMenuItem(value: cultivo, child: Text(cultivo.rotulo)),
        ],
        // Guarda a escolha para usar ao salvar.
        onChanged: (valor) => setState(() => _cultivo = valor),
        validator: _validarCultivo,
      ),
    );
  }

  // Lista de escolha do estágio da lavoura (opcional, por isso sem validator).
  Widget _campoEstagio() {
    return _CampoComRotulo(
      rotulo: 'Estágio da lavoura',
      complemento: '(opcional)',
      child: DropdownButtonFormField<EstagioLavoura>(
        initialValue: _estagio,
        isExpanded: true,
        hint: const Text('Selecione o estágio atual'),
        icon: const Icon(Icons.keyboard_arrow_down),
        decoration: _decoracao(null),
        items: [
          for (final estagio in EstagioLavoura.values)
            DropdownMenuItem(value: estagio, child: Text(estagio.rotulo)),
        ],
        onChanged: (valor) => setState(() => _estagio = valor),
      ),
    );
  }

  // Campo numérico da área em hectares (opcional).
  Widget _campoArea() {
    return _CampoComRotulo(
      rotulo: 'Tamanho da área',
      complemento: '(opcional)',
      child: TextFormField(
        controller: _areaController,
        // Abre o teclado numérico com vírgula/ponto.
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        // O "Enter" do teclado fecha o teclado (é o último campo de texto).
        textInputAction: TextInputAction.done,
        // Só deixa digitar até 6 dígitos inteiros e até 2 casas decimais,
        // com vírgula ou ponto (ex.: 123456,75). O resto é ignorado.
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}([.,]\d{0,2})?')),
        ],
        // "ha" aparece fixo no fim do campo, indicando hectares.
        decoration: _decoracao('Ex.: 5 hectares').copyWith(suffixText: 'ha'),
        validator: _validarArea,
      ),
    );
  }

  // Campo da localização. Não é um campo de texto: é um FormField "manual"
  // que guarda uma Coordenada e desenha o cartão SeletorLocalizacao.
  // Assim a localização entra na validação do Form como os outros campos.
  Widget _campoLocalizacao() {
    return _CampoComRotulo(
      rotulo: 'Localização da propriedade',
      child: FormField<Coordenada>(
        key: _localizacaoKey,
        validator: _validarLocalizacao,
        // builder redesenha o cartão sempre que o valor ou o erro mudam.
        builder: (campo) => SeletorLocalizacao(
          localizacao: campo.value,
          carregando: _buscandoLocalizacao,
          // Prioridade para o erro do GPS; se não houver, mostra o erro da
          // validação ("Registre a localização...").
          mensagemErro: _erroLocalizacao ?? campo.errorText,
          onBuscar: () => _buscarLocalizacao(campo),
          onMarcarNoMapa: () => _marcarNoMapa(campo),
        ),
      ),
    );
  }

  // Botão verde "Salvar" no fim do formulário.
  Widget _botaoSalvar() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verde,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _salvar,
        child: const Text(
          'Salvar',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Visual comum de todos os campos: fundo branco, cantos arredondados e
  // borda que muda de cor (cinza normal, verde com foco, vermelha com erro).
  // "dica" é o texto cinza que aparece dentro do campo vazio.
  InputDecoration _decoracao(String? dica) {
    // Função interna para não repetir o mesmo código nas quatro bordas.
    OutlineInputBorder borda(Color cor, {double largura = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cor, width: largura),
      );
    }

    return InputDecoration(
      hintText: dica,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: borda(AppColors.borda),
      focusedBorder: borda(AppColors.verde, largura: 1.5),
      errorBorder: borda(AppColors.erro),
      focusedErrorBorder: borda(AppColors.erro, largura: 1.5),
    );
  }
}

// Coloca um título em negrito em cima de cada campo, com um complemento
// opcional em cinza (ex.: "Tamanho da área (opcional)").
class _CampoComRotulo extends StatelessWidget {
  const _CampoComRotulo({
    required this.rotulo,
    required this.child,
    this.complemento,
  });

  final String rotulo;
  final String? complemento;
  // O campo em si (texto, lista ou localização).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text.rich: um texto com dois estilos na mesma linha (título em
        // negrito + complemento cinza).
        Text.rich(
          TextSpan(
            text: rotulo,
            style: const TextStyle(
              color: AppColors.textoEscuro,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            children: [
              if (complemento != null)
                TextSpan(
                  text: ' $complemento',
                  style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
