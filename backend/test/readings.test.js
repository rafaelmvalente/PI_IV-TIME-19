// Nome: Rodrigo Gabi - RA: 25001714
// Data: 17/11/2026
// Descrição: Testes da sincronização das leituras de clima (syncReadings): "ontem" no fuso do produtor (issue #75).

import assert from 'node:assert/strict';
import test from 'node:test';

import { criarBancoFalso } from '../suporte-de-testes/bancoFalso.js';

// readings.js carrega weather.js, que lê o .env: basta um JWT_SECRET de teste.
process.env.JWT_SECRET ??= 'segredo-de-teste-com-pelo-menos-32-caracteres';
const { dayToDate, syncReadings } = await import('../src/services/readings.js');

const propriedade = {
  _id: 'prop1',
  localizacao: { latitude: -22.9, longitude: -47.06 },
};

// 22h de 17/11 em Brasília = 01h de 18/11 em UTC.
const as22hDeBrasilia = new Date('2026-11-18T01:00:00Z');
const silencioso = { warn() {} };

// Fingimos o provedor de clima e contamos quantas vezes ele foi consultado.
function buscaFalsa() {
  const funcao = async () => {
    funcao.chamadas += 1;
    return [];
  };
  funcao.chamadas = 0;
  return funcao;
}

test('às 22h de Brasília, com a leitura de ontem já salva, não consulta o provedor', async () => {
  const banco = criarBancoFalso();
  // Ontem em Brasília é 16/11. Em UTC, "ontem" já seria 17/11 (hoje), que nunca é salvo.
  banco.collection('leituras_clima').docs.push({
    propriedadeId: propriedade._id,
    data: dayToDate('2026-11-16'),
    chuvaMm: 0,
  });
  const fetchPastDays = buscaFalsa();

  await syncReadings(banco, propriedade, { fetchPastDays, logger: silencioso, agora: as22hDeBrasilia });

  assert.equal(fetchPastDays.chamadas, 0);
});

test('sem a leitura de ontem, consulta o provedor uma vez', async () => {
  const banco = criarBancoFalso();
  const fetchPastDays = buscaFalsa();

  await syncReadings(banco, propriedade, { fetchPastDays, logger: silencioso, agora: as22hDeBrasilia });

  assert.equal(fetchPastDays.chamadas, 1);
});
