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

import 'package:flutter/widgets.dart';

import '../models/preferencias_alerta.dart';
import '../models/propriedade.dart';

class SessaoController extends ChangeNotifier {
  String? _login;
  Propriedade? _propriedade;
  PreferenciasAlerta _preferencias = PreferenciasAlerta.padrao;
  bool _carregando = false;
  String? _erro;

  String? get login => _login;
  Propriedade? get propriedade => _propriedade;
  PreferenciasAlerta get preferencias => _preferencias;
  bool get carregando => _carregando;
  String? get erro => _erro;
  bool get logado => _login != null;

  /// Chamar quando o login der certo.
  void entrar({required String login, Propriedade? propriedade}) {
    _login = login;
    _propriedade = propriedade;
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
