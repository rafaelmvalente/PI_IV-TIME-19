// Caio Ávila Marchi - 25008101
// Data: 28/10/2026
// Descrição: Tela 9 do relatório — Perfil / Configurações. Mostra a conta, os
// dados da propriedade (com edição), as preferências de alerta (texto, voz e
// SMS), o acesso ao modo offline e a opção de sair da conta. Lê tudo da
// sessão (SessaoScope).
// Data: 11/11/2026
// Descrição: Persiste propriedade, preferências e saída pela API autenticada.

import 'package:flutter/material.dart';

import '../models/estagio_lavoura.dart';
import '../models/preferencias_alerta.dart';
import '../models/propriedade.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/propriedade_service.dart';
import '../session/sessao.dart';
import 'cadastro_propriedade_screen.dart';
import 'modo_offline_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({
    super.key,
    this.sessao,
    this.onSair,
    this.onTentarNovamente,
    this.salvarPropriedade,
    this.salvarPreferencias,
    this.salvarTelefone,
    this.sairDaConta,
  });

  /// Para testes: se vier nulo, usa a sessão do SessaoScope.
  final SessaoController? sessao;

  /// Chamado depois de sair. Se for nulo, volta para a primeira rota do app.
  final VoidCallback? onSair;

  /// Mostrado no estado de erro. Sem ele, o botão "Tentar novamente" some.
  final VoidCallback? onTentarNovamente;
  final Future<Propriedade> Function(Propriedade)? salvarPropriedade;
  final Future<void> Function(PreferenciasAlerta)? salvarPreferencias;
  final Future<String> Function(String telefone)? salvarTelefone;
  final Future<void> Function()? sairDaConta;

  @override
  Widget build(BuildContext context) {
    final controller = sessao ?? SessaoScope.of(context);
    return Scaffold(
      // Sem seta de voltar: o Perfil é uma aba do dashboard, e voltar
      // fecharia o app sem sair da conta.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Perfil e configurações'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => _corpo(controller),
        ),
      ),
    );
  }

  Widget _corpo(SessaoController s) {
    if (s.carregando) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Carregando'),
      );
    }
    if (s.erro != null) {
      return _MensagemEstado(
        icone: Icons.error_outline,
        titulo: 'Não foi possível carregar',
        texto: s.erro!,
        rotuloBotao: 'Tentar novamente',
        onPressed: onTentarNovamente,
      );
    }
    final login = s.login;
    if (login == null) {
      return const _MensagemEstado(
        icone: Icons.person_off_outlined,
        titulo: 'Você não está logado',
        texto: 'Entre na sua conta para ver seu perfil.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _CabecalhoConta(login: login),
        const SizedBox(height: 24),
        _SecaoPropriedade(sessao: s, salvarPropriedade: salvarPropriedade),
        const SizedBox(height: 24),
        _SecaoAlertas(
          sessao: s,
          salvarPreferencias: salvarPreferencias,
          salvarTelefone: salvarTelefone,
        ),
        const SizedBox(height: 32),
        _BotaoSair(sessao: s, onSair: onSair, sairDaConta: sairDaConta),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _numeroTexto(double valor) {
  final texto = valor == valor.roundToDouble()
      ? valor.toStringAsFixed(0)
      : valor.toString();
  return texto.replaceAll('.', ',');
}

String _coordenadaTexto(num? valor) =>
    valor == null ? '?' : valor.toStringAsFixed(4);

String _textoLocalizacao(Propriedade p) {
  return 'Latitude ${_coordenadaTexto(p.localizacao.latitude)}, '
      'longitude ${_coordenadaTexto(p.localizacao.longitude)}';
}

// ---------------------------------------------------------------------------
// Estado vazio / erro
// ---------------------------------------------------------------------------

class _MensagemEstado extends StatelessWidget {
  const _MensagemEstado({
    required this.icone,
    required this.titulo,
    required this.texto,
    this.rotuloBotao,
    this.onPressed,
  });

  final IconData icone;
  final String titulo;
  final String texto;
  final String? rotuloBotao;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(fontSize: 18),
            ),
            if (rotuloBotao != null && onPressed != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onPressed, child: Text(rotuloBotao!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cabeçalho
// ---------------------------------------------------------------------------

class _CabecalhoConta extends StatelessWidget {
  const _CabecalhoConta({required this.login});

  final String login;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: scheme.primary,
          child: Icon(Icons.person, size: 40, color: scheme.onPrimary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Minha conta', style: textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(login, style: textTheme.bodyLarge?.copyWith(fontSize: 18)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Propriedade
// ---------------------------------------------------------------------------

class _LinhaDado extends StatelessWidget {
  const _LinhaDado({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: textTheme.bodyMedium?.copyWith(fontSize: 16)),
          Text(
            valor,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecaoPropriedade extends StatelessWidget {
  const _SecaoPropriedade({required this.sessao, this.salvarPropriedade});

  final SessaoController sessao;
  final Future<Propriedade> Function(Propriedade)? salvarPropriedade;

  void _editar(BuildContext context) {
    final atual = sessao.propriedade;
    if (atual == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _EditarPropriedadeSheet(propriedade: atual, onSalvar: _salvar),
    );
  }

  Future<void> _salvar(Propriedade nova) async {
    if (salvarPropriedade != null) {
      sessao.definirPropriedade(await salvarPropriedade!(nova));
      return;
    }
    final atual = sessao.propriedade;
    final service = const PropriedadeService();
    final salva = atual?.id == null
        ? await service.salvar(nova)
        : await service.atualizar(atual!.id!, nova);
    sessao.definirPropriedade(salva);
  }

  // Para quem escolheu "Agora não" no login e quer cadastrar depois.
  Future<void> _cadastrar(BuildContext context) async {
    final nova = await Navigator.of(context).push<Propriedade>(
      MaterialPageRoute(builder: (_) => const CadastroPropriedadeScreen()),
    );
    if (nova != null) {
      try {
        await _salvar(nova);
      } on ApiException catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível salvar: $error')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final p = sessao.propriedade;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Minha propriedade', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        if (p == null) ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Você ainda não cadastrou uma propriedade.',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => _cadastrar(context),
            icon: const Icon(Icons.add_home_outlined),
            label: const Text(
              'Cadastrar propriedade',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LinhaDado(rotulo: 'Nome', valor: p.nome),
                  _LinhaDado(rotulo: 'Cultivo', valor: p.cultivo.rotulo),
                  _LinhaDado(
                    rotulo: 'Área',
                    valor: p.areaHectares == null
                        ? 'Não informada'
                        : '${_numeroTexto(p.areaHectares!)} ha',
                  ),
                  _LinhaDado(
                    rotulo: 'Estágio',
                    valor: p.estagio?.rotulo ?? 'Não informado',
                  ),
                  _LinhaDado(
                    rotulo: 'Localização',
                    valor: _textoLocalizacao(p),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => _editar(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text(
              'Editar propriedade',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ],
    );
  }
}

class _EditarPropriedadeSheet extends StatefulWidget {
  const _EditarPropriedadeSheet({
    required this.propriedade,
    required this.onSalvar,
  });

  final Propriedade propriedade;
  final Future<void> Function(Propriedade) onSalvar;

  @override
  State<_EditarPropriedadeSheet> createState() =>
      _EditarPropriedadeSheetState();
}

class _EditarPropriedadeSheetState extends State<_EditarPropriedadeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _area;
  late TipoCultivo _cultivo;
  EstagioLavoura? _estagio;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.propriedade;
    _estagio = p.estagio;
    _nome = TextEditingController(text: p.nome);
    _area = TextEditingController(
      text: p.areaHectares == null ? '' : _numeroTexto(p.areaHectares!),
    );
    _cultivo = p.cultivo;
  }

  @override
  void dispose() {
    _nome.dispose();
    _area.dispose();
    super.dispose();
  }

  String? _validarArea(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return null;
    final numero = double.tryParse(texto.replaceAll(',', '.'));
    if (numero == null || numero <= 0) return 'Digite um número maior que zero';
    return null;
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final textoArea = _area.text.trim();
    // A localização não muda aqui: ela é definida no cadastro da propriedade.
    final nova = Propriedade(
      id: widget.propriedade.id,
      nome: _nome.text.trim(),
      cultivo: _cultivo,
      localizacao: widget.propriedade.localizacao,
      areaHectares: textoArea.isEmpty
          ? null
          : double.parse(textoArea.replaceAll(',', '.')),
      estagio: _estagio,
    );
    setState(() => _salvando = true);
    try {
      await widget.onSalvar(nova);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Dados da propriedade', style: textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nome,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Nome da propriedade',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Digite o nome da propriedade'
                    : null,
              ),
              const SizedBox(height: 16),
              Text('Cultivo', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in TipoCultivo.values)
                    ChoiceChip(
                      label: Text(
                        c.rotulo,
                        style: const TextStyle(fontSize: 18),
                      ),
                      selected: _cultivo == c,
                      onSelected: (_) => setState(() => _cultivo = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Estágio da lavoura', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in EstagioLavoura.values)
                    ChoiceChip(
                      label: Text(
                        e.rotulo,
                        style: const TextStyle(fontSize: 18),
                      ),
                      selected: _estagio == e,
                      onSelected: (_) => setState(() => _estagio = e),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _area,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Área em hectares (opcional)',
                  border: OutlineInputBorder(),
                ),
                validator: _validarArea,
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: _salvando ? null : _salvar,
                child: const Text(
                  'Salvar alterações',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preferências de alerta
// ---------------------------------------------------------------------------

class _SecaoAlertas extends StatelessWidget {
  const _SecaoAlertas({
    required this.sessao,
    this.salvarPreferencias,
    this.salvarTelefone,
  });

  final SessaoController sessao;
  final Future<void> Function(PreferenciasAlerta)? salvarPreferencias;
  final Future<String> Function(String telefone)? salvarTelefone;

  // O SMS precisa de um telefone na conta. Quem entrou pelo e-mail ainda não
  // tem: pede o número antes de ligar.
  Future<void> _alterarSms(
    BuildContext context,
    PreferenciasAlerta prefs,
    bool ligar,
  ) async {
    if (ligar && sessao.telefone == null) {
      final telefone = await _pedirTelefone(context);
      if (telefone == null || !context.mounted) return;
      try {
        final salvo = await (salvarTelefone ?? AuthService().atualizarTelefone)(
          telefone,
        );
        sessao.definirTelefone(salvo);
      } on ApiException catch (error) {
        if (context.mounted) _avisar(context, error.message);
        return;
      } catch (error) {
        if (context.mounted) {
          _avisar(context, 'Não foi possível salvar o telefone: $error');
        }
        return;
      }
    }
    if (context.mounted) await _alterar(context, prefs.copyWith(sms: ligar));
  }

  Future<String?> _pedirTelefone(BuildContext context) {
    var digitado = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Qual telefone recebe o SMS?'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(hintText: '(19) 98765-4321'),
          onChanged: (valor) => digitado = valor.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(digitado.isEmpty ? null : digitado),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _avisar(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _alterar(BuildContext context, PreferenciasAlerta novas) async {
    if (!novas.algumAtivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mantenha pelo menos um jeito de receber alertas ligado.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
      return;
    }
    try {
      if (salvarPreferencias == null) {
        await AuthService().atualizarPreferencias(novas.toJson());
      } else {
        await salvarPreferencias!(novas);
      }
      if (context.mounted) sessao.atualizarPreferencias(novas);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível salvar as preferências: $error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final prefs = sessao.preferencias;
    const estiloTitulo = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    const estiloDescricao = TextStyle(fontSize: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Como receber alertas', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Texto', style: estiloTitulo),
                subtitle: const Text(
                  'Aviso escrito no celular',
                  style: estiloDescricao,
                ),
                value: prefs.texto,
                onChanged: (v) => _alterar(context, prefs.copyWith(texto: v)),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Voz', style: estiloTitulo),
                subtitle: const Text(
                  'Aviso falado, para ouvir',
                  style: estiloDescricao,
                ),
                value: prefs.voz,
                onChanged: (v) => _alterar(context, prefs.copyWith(voz: v)),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('SMS', style: estiloTitulo),
                subtitle: Text(
                  sessao.telefone == null
                      ? 'Alertas críticos por mensagem, mesmo sem internet'
                      : 'Alertas críticos por mensagem para ${sessao.telefone}',
                  style: estiloDescricao,
                ),
                value: prefs.sms,
                onChanged: (v) => _alterarSms(context, prefs, v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ModoOfflineScreen(
                semConexao: false,
                smsAtivo: prefs.sms,
                telefone: sessao.telefone,
              ),
            ),
          ),
          icon: const Icon(Icons.wifi_off_outlined),
          label: const Text(
            'Como funciona sem internet',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sair
// ---------------------------------------------------------------------------

class _BotaoSair extends StatelessWidget {
  const _BotaoSair({required this.sessao, this.onSair, this.sairDaConta});

  final SessaoController sessao;
  final VoidCallback? onSair;
  final Future<void> Function()? sairDaConta;

  Future<void> _confirmarSaida(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você vai precisar entrar de novo para ver seus alertas.',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    try {
      if (sairDaConta == null) {
        await AuthService().sair();
      } else {
        await sairDaConta!();
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível sair: $error')),
        );
      }
      return;
    }
    sessao.sair();
    if (onSair != null) {
      onSair!();
    } else {
      navigator.popUntil((rota) => rota.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
      ),
      onPressed: () => _confirmarSaida(context),
      icon: const Icon(Icons.logout),
      label: const Text('Sair da conta', style: TextStyle(fontSize: 18)),
    );
  }
}
