// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Testes do serviço que gera e salva os alertas (sem duplicar,
// sem rebaixar o nível e avisando quais alertas são novos).

import assert from 'node:assert/strict';
import test from 'node:test';

import { gerarAlertas, inicioDoDia, refreshAlerts } from '../src/services/alertas.js';
import { criarBancoFalso } from '../suporte-de-testes/bancoFalso.js';

const propriedade = {
  _id: 'prop1',
  usuarioId: 'user1',
  cultivo: 'milho',
  estagio: 'crescimento',
  localizacao: { latitude: -22.9, longitude: -47.06 },
};

// Regra só com geada, para os testes olharem um tipo de alerta por vez.
const regraDeGeada = {
  cultura: 'milho',
  estagio: 'crescimento',
  temp_min_c: { medio: 2, alto: 0 },
};

function previsaoComMinima(minima) {
  return {
    daily: [{ date: '2026-11-12', maxima: 25, minima, precipitation: 10 }],
  };
}

function prepararBanco() {
  const banco = criarBancoFalso();
  banco.collection('risco_cultura').docs.push({ ...regraDeGeada });
  return banco;
}

// Fingimos a consulta ao provedor de clima e contamos quantas vezes ela foi usada.
function previsaoFalsa(minima) {
  const funcao = async () => {
    funcao.chamadas += 1;
    return previsaoComMinima(minima);
  };
  funcao.chamadas = 0;
  return funcao;
}

// Histórico de chuva e SMS falsos: os testes não usam internet nem Twilio.
const semRede = { obterHistorico: async () => [], notificar: async () => {} };

test('manda para o SMS só os alertas de nível alto', async () => {
  const banco = prepararBanco();
  const enviados = [];
  await gerarAlertas(banco, propriedade, {
    obterPrevisao: async () => ({
      daily: [
        { date: '2026-11-12', maxima: 25, minima: 1, precipitation: 10 }, // médio
        { date: '2026-11-13', maxima: 25, minima: -1, precipitation: 10 }, // alto
      ],
    }),
    obterHistorico: async () => [],
    notificar: async (_banco, _prop, alertas) => enviados.push(...alertas),
  });
  assert.deepEqual(enviados.map((a) => a.nivel), ['alto']);
});

test('falha no SMS não impede a geração dos alertas', async () => {
  const banco = prepararBanco();
  const erroOriginal = console.error;
  console.error = () => {};
  try {
    const { alertas } = await gerarAlertas(banco, propriedade, {
      ...semRede,
      obterPrevisao: previsaoFalsa(-1),
      notificar: async () => { throw new Error('Twilio fora do ar'); },
    });
    assert.equal(alertas.length, 1);
  } finally {
    console.error = erroOriginal;
  }
});

test('cria o alerta novo e avisa que ele é novo', async () => {
  const banco = prepararBanco();

  const { alertas, novos, elevados } = await gerarAlertas(banco, propriedade, {
    ...semRede, obterPrevisao: previsaoFalsa(1),
  });

  assert.equal(alertas.length, 1);
  assert.equal(novos.length, 1);
  assert.equal(elevados.length, 0);
  assert.equal(novos[0].tipo, 'geada');
  assert.equal(novos[0].nivel, 'medio');
  assert.equal(novos[0].status, 'emAndamento');
  assert.equal(novos[0].notificadoEm, null);
  assert.ok(novos[0].criadoEm instanceof Date);
  assert.ok(novos[0]._id);
});

test('rodar de novo não duplica nem repete o aviso', async () => {
  const banco = prepararBanco();
  const previsao = previsaoFalsa(1);

  await gerarAlertas(banco, propriedade, { ...semRede, obterPrevisao: previsao });
  const segunda = await gerarAlertas(banco, propriedade, { ...semRede, obterPrevisao: previsao });

  assert.equal(banco.collection('alertas').docs.length, 1);
  assert.equal(segunda.novos.length, 0);
  assert.equal(segunda.elevados.length, 0);
});

test('reaproveita a previsão guardada em vez de consultar o clima de novo', async () => {
  const banco = prepararBanco();
  const previsao = previsaoFalsa(1);

  await gerarAlertas(banco, propriedade, { ...semRede, obterPrevisao: previsao });
  await gerarAlertas(banco, propriedade, { ...semRede, obterPrevisao: previsao });

  assert.equal(previsao.chamadas, 1);
});

test('quando o nível sobe, atualiza o alerta e avisa de novo', async () => {
  const banco = prepararBanco();
  await gerarAlertas(banco, propriedade, { ...semRede, obterPrevisao: previsaoFalsa(1) }); // médio
  banco.collection('alertas').docs[0].notificadoEm = new Date(); // já avisado
  banco.collection('climaCache').docs.length = 0; // previsão nova

  const { novos, elevados } = await gerarAlertas(banco, propriedade, {
    ...semRede, obterPrevisao: previsaoFalsa(-1), // alto
  });

  assert.equal(novos.length, 0);
  assert.equal(elevados.length, 1);
  assert.equal(elevados[0].nivel, 'alto');
  const salvo = banco.collection('alertas').docs[0];
  assert.equal(salvo.nivel, 'alto');
  assert.equal(salvo.notificadoEm, null);
  assert.match(salvo.descricao, /-1°C/);
});

test('uma previsão mais branda não rebaixa o alerta', async () => {
  const banco = prepararBanco();
  await gerarAlertas(banco, propriedade, { ...semRede, obterPrevisao: previsaoFalsa(-1) }); // alto
  banco.collection('climaCache').docs.length = 0;

  const { novos, elevados } = await gerarAlertas(banco, propriedade, {
    ...semRede, obterPrevisao: previsaoFalsa(1), // médio
  });

  const salvo = banco.collection('alertas').docs[0];
  assert.equal(salvo.nivel, 'alto');
  assert.match(salvo.descricao, /-1°C/);
  assert.equal(novos.length + elevados.length, 0);
});

test('não mexe no status nem no aviso já enviado quando o nível é o mesmo', async () => {
  const banco = prepararBanco();
  await gerarAlertas(banco, propriedade, { ...semRede, obterPrevisao: previsaoFalsa(1) });
  const enviadoEm = new Date('2026-11-11T10:00:00Z');
  Object.assign(banco.collection('alertas').docs[0], {
    status: 'acaoRealizada',
    notificadoEm: enviadoEm,
  });
  banco.collection('climaCache').docs.length = 0;

  const { novos, elevados } = await gerarAlertas(banco, propriedade, {
    ...semRede, obterPrevisao: previsaoFalsa(1.5),
  });

  const salvo = banco.collection('alertas').docs[0];
  assert.equal(salvo.status, 'acaoRealizada');
  assert.equal(salvo.notificadoEm, enviadoEm);
  assert.match(salvo.descricao, /1\.5°C/);
  assert.equal(novos.length + elevados.length, 0);
});

test('se outra execução criou o mesmo alerta ao mesmo tempo, ignora o erro de duplicado', async () => {
  const banco = prepararBanco();
  banco.collection('alertas').erroNoInsert = Object.assign(new Error('duplicado'), { code: 11000 });

  const { novos } = await gerarAlertas(banco, propriedade, { ...semRede, obterPrevisao: previsaoFalsa(1) });

  assert.equal(novos.length, 0);
});

test('outros erros ao salvar continuam subindo', async () => {
  const banco = prepararBanco();
  banco.collection('alertas').erroNoInsert = new Error('banco caiu');

  await assert.rejects(
    () => gerarAlertas(banco, propriedade, { ...semRede, obterPrevisao: previsaoFalsa(1) }),
    /banco caiu/,
  );
});

test('sem regra cadastrada para a cultura, avisa com erro 503', async () => {
  const banco = criarBancoFalso();

  await assert.rejects(
    () => gerarAlertas(banco, propriedade, { ...semRede, obterPrevisao: previsaoFalsa(1) }),
    { status: 503, code: 'RISK_RULE_NOT_FOUND' },
  );
});

test('refreshAlerts continua devolvendo a lista de alertas da propriedade', async () => {
  const banco = prepararBanco();

  const lista = await refreshAlerts(banco, propriedade, { ...semRede, obterPrevisao: previsaoFalsa(1) });

  assert.ok(Array.isArray(lista));
  assert.equal(lista.length, 1);
  assert.equal(lista[0].tipo, 'geada');
});

test('inicioDoDia usa o dia de Brasília, não o do servidor', () => {
  // 02:00 UTC ainda é "ontem" à noite em Brasília.
  assert.equal(inicioDoDia(new Date('2026-11-11T02:00:00Z')).toISOString(), '2026-11-10T00:00:00.000Z');
  assert.equal(inicioDoDia(new Date('2026-11-11T15:00:00Z')).toISOString(), '2026-11-11T00:00:00.000Z');
});

test('o alerta de hoje (12:00 UTC) continua depois do início do dia, mesmo à tarde', () => {
  const alertaDeHoje = new Date('2026-11-11T12:00:00.000Z');
  const tarde = new Date('2026-11-11T20:00:00Z'); // 17h em Brasília
  assert.ok(alertaDeHoje >= inicioDoDia(tarde));
  assert.ok(!(alertaDeHoje >= tarde)); // o filtro antigo (>= agora) perdia o alerta
});
