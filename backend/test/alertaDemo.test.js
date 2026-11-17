// Caique Vasconcelos Naimi - 25004208
// Data: 17/11/2026
// Descrição: Testes do script de alertas de demonstração para a apresentação.

import assert from 'node:assert/strict';
import test from 'node:test';

import { criarAlertasDemo } from '../scripts/alerta-demo.js';
import { inicioDoDia } from '../src/services/alertas.js';
import { criarBancoFalso } from '../suporte-de-testes/bancoFalso.js';

async function bancoComConta() {
  const database = criarBancoFalso();
  await database.collection('usuarios').insertOne({ _id: 'user1', email: 'produtor@exemplo.com' });
  await database.collection('propriedades').insertOne({
    _id: 'prop1',
    usuarioId: 'user1',
    cultivo: 'milho',
    estagio: 'crescimento',
  });
  return database;
}

test('cria geada de hoje e chuva forte de amanhã na propriedade da conta', async () => {
  const database = await bancoComConta();
  const agora = new Date('2026-11-24T13:00:00.000Z');

  const total = await criarAlertasDemo(database, 'Produtor@Exemplo.com', agora);
  const alertas = await database.collection('alertas').find({ propriedadeId: 'prop1' }).toArray();

  assert.equal(total, 2);
  const geada = alertas.find((alerta) => alerta.tipo === 'geada');
  assert.equal(geada.nivel, 'alto');
  assert.equal(geada.status, 'emAndamento');
  assert.equal(geada.demo, true);
  assert.ok(geada.previstoPara >= inicioDoDia(agora), 'precisa aparecer em "próximos"');
  assert.ok(geada.recomendacao.acao);
  assert.equal(alertas.find((alerta) => alerta.tipo === 'chuvaForte').nivel, 'medio');
});

test('rodar de novo não duplica os alertas', async () => {
  const database = await bancoComConta();
  const agora = new Date('2026-11-24T13:00:00.000Z');

  await criarAlertasDemo(database, 'produtor@exemplo.com', agora);
  await criarAlertasDemo(database, 'produtor@exemplo.com', agora);

  assert.equal((await database.collection('alertas').find({}).toArray()).length, 2);
});

test('avisa quando a conta não existe', async () => {
  const database = await bancoComConta();

  await assert.rejects(criarAlertasDemo(database, 'outra@exemplo.com'), /Nenhuma conta encontrada/);
});
