import 'package:app/models/coordenada.dart';
import 'package:app/models/preferencias_alerta.dart';
import 'package:app/models/propriedade.dart';
import 'package:app/session/sessao.dart';
import 'package:flutter_test/flutter_test.dart';

const _propriedade = Propriedade(
  nome: 'Sítio Boa Vista',
  cultivo: TipoCultivo.milho,
  localizacao: Coordenada(latitude: -22.9056, longitude: -47.0608),
);

void main() {
  group('SessaoController', () {
    test('começa sem ninguém logado', () {
      final sessao = SessaoController();

      expect(sessao.logado, isFalse);
      expect(sessao.login, isNull);
      expect(sessao.propriedade, isNull);
      expect(sessao.preferencias.texto, isTrue);
    });

    test('entrar guarda login e propriedade e avisa os ouvintes', () {
      final sessao = SessaoController();
      var avisos = 0;
      sessao.addListener(() => avisos++);

      sessao.entrar(login: 'antonio@exemplo.com', propriedade: _propriedade);

      expect(sessao.logado, isTrue);
      expect(sessao.login, 'antonio@exemplo.com');
      expect(sessao.propriedade?.cultivo, TipoCultivo.milho);
      expect(avisos, 1);
    });

    test('atualizarPreferencias troca os canais de alerta', () {
      final sessao = SessaoController();

      sessao.atualizarPreferencias(
        sessao.preferencias.copyWith(voz: true, sms: true),
      );

      expect(sessao.preferencias.texto, isTrue);
      expect(sessao.preferencias.voz, isTrue);
      expect(sessao.preferencias.sms, isTrue);
    });

    test('sair limpa login, propriedade e preferências', () {
      final sessao = SessaoController();
      sessao.entrar(login: 'antonio@exemplo.com', propriedade: _propriedade);
      sessao.atualizarPreferencias(
        const PreferenciasAlerta(texto: true, voz: true, sms: false),
      );

      sessao.sair();

      expect(sessao.logado, isFalse);
      expect(sessao.propriedade, isNull);
      expect(sessao.preferencias.voz, isFalse);
    });
  });
}
