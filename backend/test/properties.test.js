// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Testa a previsão protegida por usuário e o cache da propriedade.

import test from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';
import { ObjectId } from 'mongodb';

const jwtSecret = 'test-secret-with-at-least-thirty-two-characters';
process.env.JWT_SECRET = jwtSecret;

const { createApp } = await import('../src/app.js');

test('retorna a previsão semanal em cache apenas à conta dona da propriedade', async (t) => {
  const userId = new ObjectId('64a000000000000000000001');
  const propertyId = new ObjectId('64a000000000000000000002');
  const forecast = {
    fetchedAt: new Date('2026-11-11T12:00:00.000Z'),
    current: { temperatura: 21, descricao: 'Céu limpo' },
    daily: [
      {
        date: '2026-11-11',
        maxima: 27,
        minima: 15,
        precipitation: 0,
      },
    ],
  };
  let forecastReads = 0;
  const property = {
    _id: propertyId,
    usuarioId: userId,
    localizacao: { latitude: -23.5, longitude: -46.6 },
  };
  const database = {
    collection(name) {
      if (name === 'propriedades') {
        return {
          findOne: async (filter) =>
            String(filter._id) === String(propertyId) &&
            String(filter.usuarioId) === String(userId)
              ? property
              : null,
        };
      }
      if (name === 'climaCache') {
        return {
          findOne: async () => {
            forecastReads += 1;
            return { forecast, atualizadoEm: new Date() };
          },
          updateOne: async () => {
            throw new Error('Uma previsão válida em cache não deve ser gravada novamente.');
          },
        };
      }
      throw new Error(`Coleção inesperada: ${name}`);
    },
  };

  const server = createApp(database).listen(0);
  t.after(() => new Promise((resolve) => server.close(resolve)));
  await new Promise((resolve) => server.once('listening', resolve));
  const { port } = server.address();
  const token = jwt.sign({}, jwtSecret, {
    subject: String(userId),
    expiresIn: '1h',
  });

  const response = await fetch(
    `http://127.0.0.1:${port}/api/v1/properties/${propertyId}/weather/forecast`,
    { headers: { authorization: `Bearer ${token}` } },
  );
  const result = await response.json();

  assert.equal(response.status, 200);
  assert.equal(result.current.temperatura, 21);
  assert.equal(result.daily[0].date, '2026-11-11');
  assert.equal(forecastReads, 1);

  const strangerToken = jwt.sign({}, jwtSecret, {
    subject: '64a000000000000000000003',
    expiresIn: '1h',
  });
  const forbiddenResponse = await fetch(
    `http://127.0.0.1:${port}/api/v1/properties/${propertyId}/weather/forecast`,
    { headers: { authorization: `Bearer ${strangerToken}` } },
  );
  assert.equal(forbiddenResponse.status, 404);
  assert.equal(forecastReads, 1);
});
