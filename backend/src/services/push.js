// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 18/11/2026
// Descrição: Envia push (Firebase Cloud Messaging) dos alertas novos ou que
// subiram de nível (issue #72):
// - respeita a preferência do produtor (push é o canal de "texto" e "voz");
// - marca cada alerta de forma atômica antes de enviar, para não avisar duas
//   vezes se o agendamento e o app atualizarem os alertas ao mesmo tempo;
// - grava notificadoEm só depois que algum aparelho recebeu;
// - sem o Firebase configurado, o backend continua funcionando e só pula o push.

import { env } from '../config/env.js';

const DEFAULT_PREFERENCES = { texto: true, voz: false };
const typeNames = { geada: 'geada', seca: 'seca prolongada', chuvaForte: 'chuva forte' };
const levelNames = { medio: 'médio', alto: 'alto' };
// Códigos do Firebase para um token que não vale mais (app desinstalado, token trocado).
const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

function formatDay(date) {
  return new Date(date).toISOString().slice(0, 10).split('-').reverse().slice(0, 2).join('/');
}

// Texto curto da notificação. O alertaId vai em "data" para o app abrir o
// detalhe do alerta quando o produtor tocar nela.
export function pushMessage(alert, property) {
  const tipo = typeNames[alert.tipo] ?? alert.tipo;
  const nivel = levelNames[alert.nivel] ?? alert.nivel;
  const acao = alert.recomendacao?.acao;
  return {
    notification: {
      title: `Risco ${nivel} de ${tipo}`,
      body: `${property.nome} (${formatDay(alert.previstoPara)}).${acao ? ` ${acao}.` : ''}`,
    },
    data: {
      alertaId: String(alert._id),
      propriedadeId: String(property._id),
      tipo: alert.tipo,
      nivel: alert.nivel,
    },
    // Prioridade alta: a notificação chega mesmo com o celular parado.
    android: { priority: 'high' },
  };
}

export function firebaseConfigurado(config = env.firebase) {
  return Boolean(config?.serviceAccountBase64);
}

let firebaseApp;

// O firebase-admin só é carregado quando existe um push para enviar.
async function obterMensageria(config) {
  const { initializeApp, cert } = await import('firebase-admin/app');
  const { getMessaging } = await import('firebase-admin/messaging');
  if (!firebaseApp) {
    const chave = JSON.parse(Buffer.from(config.serviceAccountBase64, 'base64').toString('utf8'));
    firebaseApp = initializeApp({ credential: cert(chave) });
  }
  return getMessaging(firebaseApp);
}

// Envia a mesma notificação para todos os aparelhos do produtor.
// Devolve quantos receberam e quais tokens não valem mais.
export async function sendPush(tokens, message, deps = {}) {
  const { config = env.firebase, obterMensageria: obter = obterMensageria } = deps;
  if (!firebaseConfigurado(config)) {
    throw Object.assign(new Error('Push não configurado.'), { code: 'PUSH_NOT_CONFIGURED' });
  }
  const mensageria = await obter(config);
  const resposta = await mensageria.sendEachForMulticast({ ...message, tokens });
  const invalidos = tokens.filter((_, i) =>
    INVALID_TOKEN_CODES.has(resposta.responses[i]?.error?.code),
  );
  return { enviados: resposta.successCount, falhas: resposta.failureCount, invalidos };
}

// alertas: documentos completos (com _id) dos alertas novos ou que subiram de nível.
export async function notifyAlertsByPush(database, property, alertas, deps = {}) {
  const {
    send = sendPush,
    isConfigured = firebaseConfigurado,
    logger = console,
  } = deps;
  const summary = { enviados: 0, falhas: 0, ignorado: null };
  if (!alertas.length) return summary;

  const users = database.collection('usuarios');
  const user = await users.findOne(
    { _id: property.usuarioId },
    { projection: { pushTokens: 1, preferencias: 1 } },
  );
  const preferences = { ...DEFAULT_PREFERENCES, ...user?.preferencias };

  // Push é o canal do texto e da voz. Quem desligou os dois não recebe push.
  if (!preferences.texto && !preferences.voz) return { ...summary, ignorado: 'PUSH_DESATIVADO' };
  const tokens = user?.pushTokens ?? [];
  if (!tokens.length) return { ...summary, ignorado: 'SEM_TOKEN' };
  if (!isConfigured()) return { ...summary, ignorado: 'PUSH_NAO_CONFIGURADO' };

  const alerts = database.collection('alertas');
  for (const alerta of alertas) {
    // Marca o alerta como "enviando" antes de mandar. Só quem conseguir marcar envia.
    // notificadoEm nulo = ainda não avisamos (alertas que subiram de nível voltam a nulo).
    const claimed = await alerts.findOneAndUpdate(
      {
        _id: alerta._id,
        status: 'emAndamento',
        notificadoEm: null,
        'notificacoes.push.status': { $ne: 'enviando' },
      },
      { $set: { 'notificacoes.push': { status: 'enviando', em: new Date() } } },
      { returnDocument: 'after' },
    );
    if (!claimed) continue;

    try {
      const resultado = await send(tokens, pushMessage(claimed, property));

      if (resultado.invalidos?.length) {
        await users.updateOne(
          { _id: property.usuarioId },
          { $pull: { pushTokens: { $in: resultado.invalidos } } },
        );
      }

      if (resultado.enviados > 0) {
        await alerts.updateOne(
          { _id: claimed._id },
          {
            $set: {
              notificadoEm: new Date(),
              'notificacoes.push': { status: 'enviado', em: new Date(), aparelhos: resultado.enviados },
            },
          },
        );
        summary.enviados += 1;
      } else {
        // Nenhum aparelho recebeu: notificadoEm continua nulo. Esta função aceitaria
        // uma nova tentativa, mas o gerarAlertas só manda alertas novos ou que subiram
        // de nível, então o mesmo alerta não é reenviado sozinho.
        await alerts.updateOne(
          { _id: claimed._id },
          { $set: { 'notificacoes.push': { status: 'falhou', em: new Date(), erro: 'Nenhum aparelho recebeu.' } } },
        );
        summary.falhas += 1;
      }
    } catch (error) {
      await alerts.updateOne(
        { _id: claimed._id },
        { $set: { 'notificacoes.push': { status: 'falhou', em: new Date(), erro: error.message } } },
      );
      summary.falhas += 1;
      logger.error(`Falha ao enviar push do alerta ${claimed._id}: ${error.message}`);
    }
  }
  return summary;
}
