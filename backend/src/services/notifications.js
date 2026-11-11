// Nome: Rodrigo Gabi - RA: 25001714
// Data: 11/11/2026
// Descrição: Envia os alertas críticos pelos canais que o produtor escolheu (issues #16 e #18).

import { sendSms, smsConfigured, toE164 } from './sms.js';

const DEFAULT_PREFERENCES = { texto: true, voz: false, sms: false };
const typeNames = { geada: 'Geada', seca: 'Seca prolongada', chuvaForte: 'Chuva forte' };

function formatDay(date) {
  return date.toISOString().slice(0, 10).split('-').reverse().slice(0, 2).join('/');
}

// Curto de propósito: cabe em poucos segmentos de SMS.
export function smsText(alert, property) {
  const text =
    `ClimAlerta: risco ALTO de ${typeNames[alert.tipo] ?? alert.tipo} em ${property.nome} ` +
    `(${formatDay(alert.previstoPara)}). ${alert.recomendacao?.acao ?? ''}.`;
  return text.length > 300 ? `${text.slice(0, 297)}...` : text;
}

// Só alertas de nível alto são críticos. Cada canal é marcado em
// notificacoes.<canal> antes do envio, de forma atômica: se o agendamento e o
// app atualizarem os alertas ao mesmo tempo, só um deles envia.
export async function notifyCriticalAlerts(database, property, alertKeys, deps = {}) {
  const {
    send = sendSms,
    isConfigured = smsConfigured,
    logger = console,
  } = deps;
  const summary = { enviados: 0, falhas: 0, ignorado: null };
  if (!alertKeys.length) return summary;

  const user = await database.collection('usuarios').findOne(
    { _id: property.usuarioId },
    { projection: { telefone: 1, preferencias: 1 } },
  );
  const preferences = { ...DEFAULT_PREFERENCES, ...user?.preferencias };

  // Texto e voz chegam pelo app (push, #31, e áudio, #17). Aqui o backend
  // trata o SMS, que é o canal de quem está sem internet estável.
  if (!preferences.sms) return { ...summary, ignorado: 'SMS_DESATIVADO' };
  const to = toE164(user?.telefone);
  if (!to) return { ...summary, ignorado: 'SEM_TELEFONE' };
  if (!isConfigured()) return { ...summary, ignorado: 'SMS_NAO_CONFIGURADO' };

  const alerts = database.collection('alertas');
  for (const key of alertKeys) {
    const claimed = await alerts.findOneAndUpdate(
      {
        propriedadeId: property._id,
        tipo: key.tipo,
        previstoPara: key.previstoPara,
        nivel: 'alto',
        status: 'emAndamento',
        'notificacoes.sms': { $exists: false },
      },
      { $set: { 'notificacoes.sms': { status: 'enviando', em: new Date() } } },
      { returnDocument: 'after' },
    );
    if (!claimed) continue;

    try {
      const { sid } = await send(to, smsText(claimed, property));
      await alerts.updateOne(
        { _id: claimed._id },
        { $set: { 'notificacoes.sms': { status: 'enviado', em: new Date(), sid } } },
      );
      summary.enviados += 1;
    } catch (error) {
      // Mantém o registro da falha: não reenvia sozinho para não mandar SMS repetido.
      await alerts.updateOne(
        { _id: claimed._id },
        { $set: { 'notificacoes.sms': { status: 'falhou', em: new Date(), erro: error.message } } },
      );
      summary.falhas += 1;
      logger.error(`Falha ao enviar SMS do alerta ${claimed._id}: ${error.message}`);
    }
  }
  return summary;
}
