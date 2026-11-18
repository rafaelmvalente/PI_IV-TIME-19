// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 18/11/2026
// Descrição: Liga o NotificacaoService ao Firebase Cloud Messaging (issue #31).
// A configuração do Firebase vem de --dart-define, e não do google-services.json,
// para nenhum arquivo secreto ir para o Git e para quem não configurou o Firebase
// conseguir rodar o app normalmente (nesse caso o push fica desligado).

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notificacao_service.dart';

class ProvedorFirebase implements ProvedorDePush {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  FirebaseMessaging? _mensagens;

  static bool get _configurado =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty;

  // Push só no celular. Na web e no computador o app segue sem notificações.
  static bool get _plataformaSuportada =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> inicializar() async {
    if (!_plataformaSuportada || !_configurado) return false;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _senderId,
          projectId: _projectId,
        ),
      );
      _mensagens = FirebaseMessaging.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> pedirPermissao() async {
    final configuracao = await _mensagens?.requestPermission();
    final situacao = configuracao?.authorizationStatus;
    return situacao == AuthorizationStatus.authorized ||
        situacao == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> obterToken() async {
    try {
      return await _mensagens?.getToken();
    } catch (_) {
      return null; // ex.: emulador sem Google Play Services
    }
  }

  @override
  Stream<String> get tokenRenovado =>
      _mensagens?.onTokenRefresh ?? const Stream<String>.empty();

  @override
  Stream<MensagemDePush> get comAppAberto =>
      FirebaseMessaging.onMessage.map(_converter);

  @override
  Stream<MensagemDePush> get aoAbrirNotificacao =>
      FirebaseMessaging.onMessageOpenedApp.map(_converter);

  @override
  Future<MensagemDePush?> mensagemInicial() async {
    final mensagem = await _mensagens?.getInitialMessage();
    return mensagem == null ? null : _converter(mensagem);
  }

  // O backend manda o alertaId dentro de "data" (veja backend/src/services/push.js).
  static MensagemDePush _converter(RemoteMessage mensagem) {
    return MensagemDePush(
      alertaId: mensagem.data['alertaId'] as String?,
      titulo: mensagem.notification?.title,
      corpo: mensagem.notification?.body,
    );
  }
}
