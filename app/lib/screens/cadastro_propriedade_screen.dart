// Vinicius Santuci Virgolino - 25000294
// Data: 13/10/26
// Horário:
// Descrição: Tela de cadastro da propriedade do ClimAlerta. Contém os campos
// de nome da propriedade, tipo de cultivo, tamanho da área (opcional) e a
// localização obtida pelo GPS, a ilustração da paisagem rural e o botão
// "Salvar". Ao salvar, devolve a Propriedade preenchida para a tela anterior.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/coordenada.dart';
import '../models/propriedade.dart';
import '../services/localizacao_service.dart';
import '../theme/app_colors.dart';
import '../widgets/seletor_localizacao.dart';

class CadastroPropriedadeScreen extends StatefulWidget {
  const CadastroPropriedadeScreen({
    super.key,
    this.localizacaoService = const LocalizacaoService(),
  });

  final LocalizacaoService localizacaoService;

  @override
  State<CadastroPropriedadeScreen> createState() =>
      _CadastroPropriedadeScreenState();
}

class _CadastroPropriedadeScreenState extends State<CadastroPropriedadeScreen> {
  static const int _tamanhoMinimoNome = 3;
  static const int _tamanhoMaximoNome = 60;

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _areaController = TextEditingController();
  final _localizacaoKey = GlobalKey<FormFieldState<Coordenada>>();

  TipoCultivo? _cultivo;
  bool _buscandoLocalizacao = false;
  String? _erroLocalizacao;

  @override
  void dispose() {
    _nomeController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  String? _validarNome(String? valor) {
    final nome = valor?.trim() ?? '';
    if (nome.isEmpty) return 'Informe o nome da propriedade';
    if (nome.length < _tamanhoMinimoNome) {
      return 'O nome deve ter pelo menos $_tamanhoMinimoNome letras';
    }
    return null;
  }

  String? _validarCultivo(TipoCultivo? valor) {
    return valor == null ? 'Selecione o tipo de cultivo' : null;
  }

  String? _validarArea(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return null;
    final area = _converterArea(texto);
    if (area == null || area <= 0) return 'Informe uma área válida';
    return null;
  }

  String? _validarLocalizacao(Coordenada? valor) {
    return valor == null ? 'Registre a localização da propriedade' : null;
  }

  double? _converterArea(String texto) {
    if (texto.trim().isEmpty) return null;
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  Future<void> _buscarLocalizacao(FormFieldState<Coordenada> campo) async {
    setState(() {
      _buscandoLocalizacao = true;
      _erroLocalizacao = null;
    });

    try {
      final coordenada = await widget.localizacaoService
          .obterLocalizacaoAtual();
      if (!mounted) return;
      campo.didChange(coordenada);
      campo.validate();
    } on LocalizacaoException catch (erro) {
      if (!mounted) return;
      setState(() => _erroLocalizacao = erro.mensagem);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _erroLocalizacao =
            'Não foi possível obter a localização. '
            'Tente novamente.';
      });
    } finally {
      if (mounted) setState(() => _buscandoLocalizacao = false);
    }
  }

  void _salvar() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final propriedade = Propriedade(
      nome: _nomeController.text.trim(),
      cultivo: _cultivo!,
      localizacao: _localizacaoKey.currentState!.value!,
      areaHectares: _converterArea(_areaController.text),
    );

    Navigator.of(context).pop(propriedade);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textoEscuro,
        elevation: 0,
        title: const Text(
          'Cadastrar propriedade',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            // Mesmo esquema da tela de login: o minHeight faz a coluna ocupar
            // no mínimo a tela inteira e o spaceBetween empurra a paisagem
            // para o fundo. Em telas baixas ela fica depois do botão
            // "Salvar" e rola junto, sem sobrepor.
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
                          padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Informe os dados da sua propriedade para receber '
                                  'alertas personalizados.',
                                  style: TextStyle(
                                    color: AppColors.textoSecundario,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _CampoComRotulo(
                                  rotulo: 'Nome da propriedade',
                                  child: TextFormField(
                                    controller: _nomeController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(
                                        _tamanhoMaximoNome,
                                      ),
                                    ],
                                    decoration: _decoracao(
                                      'Ex.: Sítio Boa Vista',
                                    ),
                                    validator: _validarNome,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _CampoComRotulo(
                                  rotulo: 'Tipo de cultivo',
                                  child: DropdownButtonFormField<TipoCultivo>(
                                    initialValue: _cultivo,
                                    hint: const Text(
                                      'Selecione o tipo de cultivo',
                                    ),
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    decoration: _decoracao(null),
                                    items: [
                                      for (final cultivo in TipoCultivo.values)
                                        DropdownMenuItem(
                                          value: cultivo,
                                          child: Text(cultivo.rotulo),
                                        ),
                                    ],
                                    onChanged: (valor) =>
                                        setState(() => _cultivo = valor),
                                    validator: _validarCultivo,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _CampoComRotulo(
                                  rotulo: 'Tamanho da área',
                                  complemento: '(opcional)',
                                  child: TextFormField(
                                    controller: _areaController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textInputAction: TextInputAction.done,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d{0,6}([.,]\d{0,2})?'),
                                      ),
                                    ],
                                    decoration: _decoracao(
                                      'Ex.: 5 hectares',
                                    ).copyWith(suffixText: 'ha'),
                                    validator: _validarArea,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _CampoComRotulo(
                                  rotulo: 'Localização da propriedade',
                                  child: FormField<Coordenada>(
                                    key: _localizacaoKey,
                                    validator: _validarLocalizacao,
                                    builder: (campo) => SeletorLocalizacao(
                                      localizacao: campo.value,
                                      carregando: _buscandoLocalizacao,
                                      mensagemErro:
                                          _erroLocalizacao ?? campo.errorText,
                                      onBuscar: () => _buscarLocalizacao(campo),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
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
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/paisagem_morros.png',
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
        ),
      ),
    );
  }

  InputDecoration _decoracao(String? dica) {
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

class _CampoComRotulo extends StatelessWidget {
  const _CampoComRotulo({
    required this.rotulo,
    required this.child,
    this.complemento,
  });

  final String rotulo;
  final String? complemento;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
