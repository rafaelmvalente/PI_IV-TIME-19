// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 18/11/2026
// Descrição: Testa o envio de push dos alertas (issue #72): preferência do
// produtor, aviso uma vez só, alertas que sobem de nível e tokens inválidos.

import test from 'node:test';
import assert from 'node:assert/strict';

process.env.JWT_SECRET ??= 'segredo-de-teste-com-pelo-menos-32-caracteres';
const { notifyAlertsByPush, pushMessage, sendPush } = await import('../src/services/push.js');

const previstoPara = new Date('2026-11-12T12:00:00.000Z');
const property = { _id: 'p1', usuarioId: 'u1', nome: 'Sítio Boa Vista' };
const silent = { error() {}, warn() {}, log() {} };

function alert(overrides = {}) {
  return {
    _id: 'a1',
    propriedadeId: 'p1',
    tipo: 'geada',
    nivel: 'alto',
    status: 'emAndamento',
    previstoPara,
    notificadoEm: null,
    recomendacao: { acao: 'Proteja as plantas mais sensíveis' },
    ...overrides,
  };
}

function user(overrides = {}) {
  return {
    pushTokens: ['token-aparelho-1-com-mais-de-vinte-caracteres'],
    preferencias: { texto: true, voz: false },
    ...overrides,
  };
}

// Banco falso com só o que notifyAlertsByPush usa.
function fakeDb({ usuario, alerts }) {
  const nulo = (valor) => valor === null || valor === undefined;
  const matches = (doc, filtro) => {
    if (filtro._id !== undefined && doc._id !== filtro._id) return false;
    if (filtro.status !== undefined && doc.status !== filtro.status) return false;
    if (filtro.notificadoEm === null && !nulo(doc.notificadoEm)) return false;
    const naoIgual = filtro['notificacoes.push.status']?.$ne;
    if (naoIgual !== undefined && doc.notificacoes?.push?.status === naoIgual) return false;
    return true;
  };
  const aplicar = (doc, set) => {
    for (const [campo, valor] of Object.entries(set)) {
      if (campo === 'notificacoes.push') doc.notificacoes = { ...doc.notificacoes, push: valor };
      else doc[campo] = valor;
    }
  };
  return {
    usuario,
    alerts,
    collection(nome) {
      if (nome === 'usuarios') {
        return {
          findOne: async () => usuario,
          async updateOne(_filtro, update) {
            const remover = update.$pull.pushTokens.$in;
            usuario.pushTokens = usuario.pushTokens.filter((token) => !remover.includes(token));
          },
        };
      }
      return {
        async findOneAndUpdate(filtro, update) {
          const doc = alerts.find((item) => matches(item, filtro));
          if (!doc) return null;
          aplicar(doc, update.$set);
          return doc;
        },
        async updateOne({ _id }, update) {
          aplicar(alerts.find((item) => item._id === _id), update.$set);
        },
      };
    },
  };
}

const configurado = () => true;

test('avisa uma única vez e marca notificadoEm depois de enviar', async () => {
  const db = fakeDb({ usuario: user(), alerts: [alert()] });
  const enviados = [];
  const deps = {
    send: async (tokens, mensagem) => {
      enviados.push({ tokens, mensagem });
      return { enviados: 1, invalidos: [] };
    },
    isConfigured: configurado,
    logger: silent,
  };

  const primeira = await notifyAlertsByPush(db, property, [alert()], deps);
  const segunda = await notifyAlertsByPush(db, property, [alert()], deps);

  assert.equal(primeira.enviados, 1);
  assert.equal(segunda.enviados, 0);
  assert.equal(enviados.length, 1);
  assert.deepEqual(enviados[0].tokens, ['token-aparelho-1-com-mais-de-vinte-caracteres']);
  assert.equal(enviados[0].mensagem.data.alertaId, 'a1');
  assert.ok(db.alerts[0].notificadoEm instanceof Date);
  assert.equal(db.alerts[0].notificacoes.push.status, 'enviado');
});

test('respeita a preferência: quem desligou texto e voz não recebe push', async () => {
  const db = fakeDb({
    usuario: user({ preferencias: { texto: false, voz: false } }),
    alerts: [alert()],
  });
  let chamadas = 0;
  const result = await notifyAlertsByPush(db, property, [alert()], {
    send: async () => {
      chamadas += 1;
    },
    isConfigured: configurado,
  });

  assert.equal(result.ignorado, 'PUSH_DESATIVADO');
  assert.equal(chamadas, 0);
});

test('quem escolheu só voz também recebe a notificação', async () => {
  const db = fakeDb({
    usuario: user({ preferencias: { texto: false, voz: true } }),
    alerts: [alert()],
  });
  const result = await notifyAlertsByPush(db, property, [alert()], {
    send: async () => ({ enviados: 1, invalidos: [] }),
    isConfigured: configurado,
  });
  assert.equal(result.enviados, 1);
});

test('sem token do aparelho ou sem Firebase configurado, não envia nem dá erro', async () => {
  const semToken = fakeDb({ usuario: user({ pushTokens: [] }), alerts: [alert()] });
  const r1 = await notifyAlertsByPush(semToken, property, [alert()], { isConfigured: configurado });
  assert.equal(r1.ignorado, 'SEM_TOKEN');

  const semFirebase = fakeDb({ usuario: user(), alerts: [alert()] });
  const r2 = await notifyAlertsByPush(semFirebase, property, [alert()], { isConfigured: () => false });
  assert.equal(r2.ignorado, 'PUSH_NAO_CONFIGURADO');
  assert.equal(semFirebase.alerts[0].notificadoEm, null);
});

test('alerta que subiu de nível (notificadoEm voltou a nulo) é avisado de novo', async () => {
  const jaAvisado = alert({ notificacoes: { push: { status: 'enviado' } }, notificadoEm: null });
  const db = fakeDb({ usuario: user(), alerts: [jaAvisado] });

  const result = await notifyAlertsByPush(db, property, [alert()], {
    send: async () => ({ enviados: 1, invalidos: [] }),
    isConfigured: configurado,
  });

  assert.equal(result.enviados, 1);
  assert.ok(db.alerts[0].notificadoEm instanceof Date);
});

test('alerta já resolvido pelo produtor não gera notificação', async () => {
  const db = fakeDb({ usuario: user(), alerts: [alert({ status: 'resolvido' })] });
  let chamadas = 0;
  const result = await notifyAlertsByPush(db, property, [alert()], {
    send: async () => {
      chamadas += 1;
      return { enviados: 1, invalidos: [] };
    },
    isConfigured: configurado,
  });
  assert.equal(result.enviados, 0);
  assert.equal(chamadas, 0);
});

test('falha no envio fica registrada e a próxima atualização tenta de novo', async () => {
  const db = fakeDb({ usuario: user(), alerts: [alert()] });

  const falha = await notifyAlertsByPush(db, property, [alert()], {
    send: async () => {
      throw new Error('Firebase fora do ar');
    },
    isConfigured: configurado,
    logger: silent,
  });
  assert.equal(falha.falhas, 1);
  assert.equal(db.alerts[0].notificadoEm, null);
  assert.equal(db.alerts[0].notificacoes.push.status, 'falhou');

  const retry = await notifyAlertsByPush(db, property, [alert()], {
    send: async () => ({ enviados: 1, invalidos: [] }),
    isConfigured: configurado,
  });
  assert.equal(retry.enviados, 1);
  assert.ok(db.alerts[0].notificadoEm instanceof Date);
});

test('quando nenhum aparelho recebe, notificadoEm continua nulo', async () => {
  const db = fakeDb({ usuario: user(), alerts: [alert()] });
  const result = await notifyAlertsByPush(db, property, [alert()], {
    send: async () => ({ enviados: 0, invalidos: [] }),
    isConfigured: configurado,
  });
  assert.equal(result.falhas, 1);
  assert.equal(db.alerts[0].notificadoEm, null);
});

test('tokens que o Firebase marcou como inválidos saem da conta do produtor', async () => {
  const usuario = user({ pushTokens: ['token-bom-com-mais-de-vinte-caracteres', 'token-velho-com-mais-de-vinte-caracteres'] });
  const db = fakeDb({ usuario, alerts: [alert()] });

  await notifyAlertsByPush(db, property, [alert()], {
    send: async () => ({ enviados: 1, invalidos: ['token-velho-com-mais-de-vinte-caracteres'] }),
    isConfigured: configurado,
  });

  assert.deepEqual(usuario.pushTokens, ['token-bom-com-mais-de-vinte-caracteres']);
});

test('texto da notificação é curto e leva o alertaId', () => {
  const mensagem = pushMessage(alert(), property);

  assert.equal(mensagem.notification.title, 'Risco alto de geada');
  assert.equal(mensagem.notification.body, 'Sítio Boa Vista (12/11). Proteja as plantas mais sensíveis.');
  assert.equal(mensagem.data.alertaId, 'a1');
  assert.equal(mensagem.data.propriedadeId, 'p1');
  // Todos os valores de "data" precisam ser texto, exigência do Firebase.
  assert.ok(Object.values(mensagem.data).every((valor) => typeof valor === 'string'));
});

test('sendPush devolve quantos receberam e quais tokens não valem mais', async () => {
  const mensageria = {
    async sendEachForMulticast({ tokens }) {
      assert.equal(tokens.length, 3);
      return {
        successCount: 1,
        failureCount: 2,
        responses: [
          { success: true },
          { success: false, error: { code: 'messaging/registration-token-not-registered' } },
          { success: false, error: { code: 'messaging/internal-error' } },
        ],
      };
    },
  };

  const result = await sendPush(['a', 'b', 'c'], { notification: {} }, {
    config: { serviceAccountBase64: 'qualquer-coisa' },
    obterMensageria: async () => mensageria,
  });

  assert.deepEqual(result, { enviados: 1, falhas: 2, invalidos: ['b'] });
});

test('sendPush sem configuração gera erro claro', async () => {
  await assert.rejects(sendPush(['a'], {}, { config: {} }), { code: 'PUSH_NOT_CONFIGURED' });
});
