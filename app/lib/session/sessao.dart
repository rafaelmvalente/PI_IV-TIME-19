// Caio Ávila Marchi - 25008101
// Data: 28/10/2026
// Descrição: Sessão do usuário. Guarda quem está logado (e-mail ou telefone),
// a propriedade atual e as preferências de alerta, para que qualquer tela
// consiga ler esses dados. Fica só na memória do app por enquanto.
//
// Como usar em qualquer tela:
//   final sessao = SessaoScope.of(context);
//   sessao.login          // e-mail ou telefone de quem entrou
//   sessao.propriedade    // Propriedade atual (pode ser null)
//   sessao.preferencias   // texto / voz / SMS
// Data: 11/11/2026
// Descrição: Mantém na sessão os dados retornados pela API autenticada.

import 'package:flutter/widgets.dart';

import '../models/preferencias_alerta.dart';
import '../models/propriedade.dart';
import '../models/usuario.dart';

class SessaoController extends ChangeNotifier {
  String? _login;
  String? _nome;
  Usuario? _usuario;
  String? _token;
  Propriedade? _propriedade;
  PreferenciasAlerta _preferencias = PreferenciasAlerta.padrao;
  bool _carregando = false;
  String? _erro;

  String? get login => _login;
  String? get nome => _usuario?.nome ?? _nome;
  Usuario? get usuario => _usuario;
  String? get token => _token;
  Propriedade? get propriedade => _propriedade;
  PreferenciasAlerta get preferencias => _preferencias;
  bool get carregando => _carregando;
  String? get erro => _erro;
  bool get logado => _login != null;

  /// Chamar quando o login der certo.
  void entrar({
    required String login,
    String? nome,
    Usuario? usuario,
    String? token,
    Propriedade? propriedade,
    PreferenciasAlerta? preferencias,
  }) {
    _login = login;
    _nome = nome ?? usuario?.nome;
    _usuario = usuario;
    _token = token;
    _propriedade = propriedade;
    _preferencias =
        preferencias ?? _usuario?.preferencias ?? PreferenciasAlerta.padrao;
    _carregando = false;
    _erro = null;
    notifyListeners();
  }

  /// Chamar quando a propriedade for cadastrada ou editada.
  void definirPropriedade(Propriedade propriedade) {
    _propriedade = propriedade;
    notifyListeners();
  }

  void atualizarPreferencias(PreferenciasAlerta preferencias) {
    _preferencias = preferencias;
    notifyListeners();
  }

  void definirCarregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }

  void definirErro(String? mensagem) {
    _erro = mensagem;
    notifyListeners();
  }

  /// Limpa tudo, inclusive as preferências.
  void sair() {
    _login = null;
    _nome = null;
    _usuario = null;
    _token = null;
    _propriedade = null;
    _preferencias = PreferenciasAlerta.padrao;
    _carregando = false;
    _erro = null;
    notifyListeners();
  }
}

/// Deixa o [SessaoController] disponível para todas as telas.
/// Fica acima do MaterialApp, em main.dart.
class SessaoScope extends InheritedNotifier<SessaoController> {
  const SessaoScope({
    super.key,
    required SessaoController controller,
    required super.child,
  }) : super(notifier: controller);

  static SessaoController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessaoScope>();
    assert(
      scope != null,
      'SessaoScope não encontrado. Envolva o app com SessaoScope em main.dart.',
    );
    return scope!.notifier!;
  }
}
