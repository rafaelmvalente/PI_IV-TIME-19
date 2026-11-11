// Nome: Rodrigo Gabi - RA: 25001714
// Data: 11/11/2026
// Descrição: Testa o envio de SMS dos alertas críticos e a preferência do produtor (issues #16 e #18).

import test from 'node:test';
import assert from 'node:assert/strict';

process.env.JWT_SECRET ??= 'segredo-de-teste-com-pelo-menos-32-caracteres';
const { notifyCriticalAlerts, smsText } = await import('../src/services/notifications.js');
const { sendSms, toE164 } = await import('../src/services/sms.js');

const previstoPara = new Date('2026-11-12T12:00:00.000Z');
const property = { _id: 'p1', usuarioId: 'u1', nome: 'Sítio Boa Vista' };
const key = { tipo: 'geada', previstoPara };
const silent = { error() {}, warn() {}, log() {} };

// Banco falso com só o que notifyCriticalAlerts usa.
function fakeDb({ user, alerts }) {
  const matches = (doc, filter) =>
    Object.entries(filter).every(([field, value]) => {
      if (field === 'notificacoes.sms') return doc.notificacoes?.sms === undefined;
      return value instanceof Date ? doc[field]?.getTime() === value.getTime() : doc[field] === value;
    });
  return {
    alerts,
    collection(name) {
      if (name === 'usuarios') return { findOne: async () => user };
      return {
        async findOneAndUpdate(filter, update) {
          const doc = alerts.find((alert) => matches(alert, filter));
          if (!doc) return null;
          doc.notificacoes = { sms: update.$set['notificacoes.sms'] };
          return doc;
        },
        async updateOne({ _id }, update) {
          alerts.find((alert) => alert._id === _id).notificacoes = { sms: update.$set['notificacoes.sms'] };
        },
      };
    },
  };
}

function alert(overrides = {}) {
  return {
    _id: 'a1',
    propriedadeId: 'p1',
    tipo: 'geada',
    nivel: 'alto',
    status: 'emAndamento',
    previstoPara,
    recomendacao: { acao: 'Proteja as plantas mais sensíveis' },
    ...overrides,
  };
}

test('envia SMS uma única vez para alerta crítico quando o produtor escolheu SMS', async () => {
  const db = fakeDb({
    user: { telefone: '(19) 98765-4321', preferencias: { texto: true, voz: false, sms: true } },
    alerts: [alert()],
  });
  const sent = [];
  const deps = {
    send: async (to, body) => {
      sent.push({ to, body });
      return { sid: 'SM1' };
    },
    isConfigured: () => true,
    logger: silent,
  };

  const first = await notifyCriticalAlerts(db, property, [key], deps);
  const second = await notifyCriticalAlerts(db, property, [key], deps);

  assert.equal(first.enviados, 1);
  assert.equal(second.enviados, 0);
  assert.equal(sent.length, 1);
  assert.equal(sent[0].to, '+5519987654321');
  assert.match(sent[0].body, /Geada em Sítio Boa Vista \(12\/11\)/);
  assert.equal(db.alerts[0].notificacoes.sms.status, 'enviado');
});

test('respeita a preferência: sem SMS escolhido, nada é enviado', async () => {
  const db = fakeDb({
    user: { telefone: '19987654321', preferencias: { texto: true, voz: false, sms: false } },
    alerts: [alert()],
  });
  let calls = 0;
  const result = await notifyCriticalAlerts(db, property, [key], {
    send: async () => {
      calls += 1;
    },
    isConfigured: () => true,
  });
  assert.equal(result.ignorado, 'SMS_DESATIVADO');
  assert.equal(calls, 0);
});

test('não envia alerta de nível médio', async () => {
  const db = fakeDb({
    user: { telefone: '19987654321', preferencias: { sms: true } },
    alerts: [alert({ nivel: 'medio' })],
  });
  const result = await notifyCriticalAlerts(db, property, [key], { send: async () => ({}), isConfigured: () => true });
  assert.equal(result.enviados, 0);
});

test('sem telefone válido ou sem Twilio configurado, não envia', async () => {
  const semTelefone = fakeDb({ user: { preferencias: { sms: true } }, alerts: [alert()] });
  const r1 = await notifyCriticalAlerts(semTelefone, property, [key], { isConfigured: () => true });
  assert.equal(r1.ignorado, 'SEM_TELEFONE');

  const semTwilio = fakeDb({ user: { telefone: '19987654321', preferencias: { sms: true } }, alerts: [alert()] });
  const r2 = await notifyCriticalAlerts(semTwilio, property, [key], { isConfigured: () => false });
  assert.equal(r2.ignorado, 'SMS_NAO_CONFIGURADO');
});

test('falha do Twilio fica registrada e não é reenviada', async () => {
  const db = fakeDb({ user: { telefone: '19987654321', preferencias: { sms: true } }, alerts: [alert()] });
  const deps = {
    send: async () => {
      throw new Error('número inválido');
    },
    isConfigured: () => true,
    logger: silent,
  };
  const result = await notifyCriticalAlerts(db, property, [key], deps);
  assert.equal(result.falhas, 1);
  assert.equal(db.alerts[0].notificacoes.sms.status, 'falhou');
  assert.equal((await notifyCriticalAlerts(db, property, [key], deps)).falhas, 0);
});

test('converte telefones para E.164', () => {
  assert.equal(toE164('(19) 98765-4321'), '+5519987654321');
  assert.equal(toE164('1932541234'), '+551932541234');
  assert.equal(toE164('5519987654321'), '+5519987654321');
  assert.equal(toE164('+1 555 123 4567'), '+15551234567');
  assert.equal(toE164('12345'), null);
  assert.equal(toE164(undefined), null);
});

test('sendSms chama a API do Twilio com autenticação e formulário', async () => {
  let request;
  const fetchFn = async (url, options) => {
    request = { url, options };
    return { ok: true, json: async () => ({ sid: 'SM123' }) };
  };
  const config = { accountSid: 'AC1', authToken: 'token', from: '+15550001111' };
  const result = await sendSms('+5519987654321', 'Olá', { config, fetchFn });

  assert.equal(result.sid, 'SM123');
  assert.equal(request.url, 'https://api.twilio.com/2010-04-01/Accounts/AC1/Messages.json');
  assert.equal(request.options.headers.authorization, `Basic ${Buffer.from('AC1:token').toString('base64')}`);
  assert.equal(request.options.body.get('To'), '+5519987654321');
  assert.equal(request.options.body.get('From'), '+15550001111');
});

test('sendSms sem configuração gera erro claro', async () => {
  await assert.rejects(sendSms('+5519987654321', 'Olá', { config: {} }), { code: 'SMS_NOT_CONFIGURED' });
});

test('texto do SMS é curto', () => {
  assert.ok(smsText(alert(), property).length <= 300);
});
