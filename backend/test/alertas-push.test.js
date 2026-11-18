// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 18/11/2026
// Descrição: Testa que o gerarAlertas manda para o push só os alertas novos ou
// que subiram de nível (issue #72), e que falha no push não derruba a resposta.

import assert from 'node:assert/strict';
import test from 'node:test';

import { gerarAlertas } from '../src/services/alertas.js';
import { criarBancoFalso } from '../suporte-de-testes/bancoFalso.js';

const propriedade = {
  _id: 'prop1',
  usuarioId: 'user1',
  cultivo: 'milho',
  estagio: 'crescimento',
  localizacao: { latitude: -22.9, longitude: -47.06 },
};

function prepararBanco() {
  const banco = criarBancoFalso();
  banco.collection('risco_cultura').docs.push({
    cultura: 'milho',
    estagio: 'crescimento',
    temp_min_c: { medio: 2, alto: 0 },
  });
  return banco;
}

function previsaoComMinima(minima) {
  return async () => ({
    daily: [{ date: '2026-11-18', maxima: 25, minima, precipitation: 10 }],
  });
}

// Só o push é de verdade nestes testes: clima, histórico e SMS são simulados.
function opcoes(minima, enviarPush) {
  return {
    obterPrevisao: previsaoComMinima(minima),
    obterHistorico: async () => [],
    notificar: async () => {},
    enviarPush,
  };
}

test('alerta novo vai para o push, e rodar de novo não repete', async () => {
  const banco = prepararBanco();
  const chamadas = [];
  const enviarPush = async (_db, _propriedade, alertas) => chamadas.push(alertas);

  await gerarAlertas(banco, propriedade, opcoes(1, enviarPush));
  await gerarAlertas(banco, propriedade, opcoes(1, enviarPush));

  assert.equal(chamadas.length, 1);
  assert.equal(chamadas[0].length, 1);
  assert.equal(chamadas[0][0].tipo, 'geada');
  assert.ok(chamadas[0][0]._id);
});

test('alerta que sobe de nível vai para o push de novo', async () => {
  const banco = prepararBanco();
  const chamadas = [];
  const enviarPush = async (_db, _propriedade, alertas) => chamadas.push(alertas);

  await gerarAlertas(banco, propriedade, opcoes(1, enviarPush)); // médio
  banco.collection('climaCache').docs.length = 0;
  await gerarAlertas(banco, propriedade, opcoes(-1, enviarPush)); // alto

  assert.equal(chamadas.length, 2);
  assert.equal(chamadas[1][0].nivel, 'alto');
});

test('falha no push não impede a resposta com os alertas', async () => {
  const banco = prepararBanco();
  const erroOriginal = console.error;
  console.error = () => {};
  try {
    const { alertas } = await gerarAlertas(
      banco,
      propriedade,
      opcoes(1, async () => {
        throw new Error('Firebase fora do ar');
      }),
    );
    assert.equal(alertas.length, 1);
  } finally {
    console.error = erroOriginal;
  }
});
