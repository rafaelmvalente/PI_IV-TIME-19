// Data: 11/11/2026
// Descrição: Testa o cadastro do telefone da conta, usado no SMS dos alertas.

import test from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';
import { ObjectId } from 'mongodb';

const jwtSecret = 'test-secret-with-at-least-thirty-two-characters';
process.env.JWT_SECRET = jwtSecret;

const { createApp } = await import('../src/app.js');

test('salva o telefone da conta e recusa número sem DDD', async (t) => {
  const userId = new ObjectId('64a000000000000000000001');
  const user = {
    _id: userId,
    nome: 'Ana',
    email: 'ana@exemplo.com',
    preferencias: { texto: true, voz: false, sms: true },
  };
  const database = {
    collection(name) {
      assert.equal(name, 'usuarios');
      return {
        findOneAndUpdate: async (filter, update) => {
          if (String(filter._id) !== String(userId)) return null;
          Object.assign(user, update.$set);
          return user;
        },
      };
    },
  };

  const server = createApp(database).listen(0);
  t.after(() => new Promise((resolve) => server.close(resolve)));
  await new Promise((resolve) => server.once('listening', resolve));
  const { port } = server.address();
  const token = jwt.sign({}, jwtSecret, { subject: String(userId), expiresIn: '1h' });
  const enviar = (telefone) =>
    fetch(`http://127.0.0.1:${port}/api/v1/auth/me/telefone`, {
      method: 'PATCH',
      headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
      body: JSON.stringify({ telefone }),
    });

  const ok = await enviar(' (19) 98765-4321 ');
  assert.equal(ok.status, 200);
  assert.equal((await ok.json()).telefone, '(19) 98765-4321');

  const semDdd = await enviar('98765-4321');
  assert.equal(semDdd.status, 400);
  assert.equal(user.telefone, '(19) 98765-4321');
});
