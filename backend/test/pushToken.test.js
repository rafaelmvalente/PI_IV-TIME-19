// Caique Vasconcelos Naimi - 25004208
// Data: 19/11/2026
// Descrição: Testa a rota que tira o token do aparelho ao sair da conta.

import test from 'node:test';
import assert from 'node:assert/strict';
import jwt from 'jsonwebtoken';
import { ObjectId } from 'mongodb';

const jwtSecret = 'test-secret-with-at-least-thirty-two-characters';
process.env.JWT_SECRET = jwtSecret;

const { createApp } = await import('../src/app.js');

test('DELETE /me/push-token tira o token do aparelho da conta', async (t) => {
  const userId = new ObjectId('64a000000000000000000001');
  const token = 'token-do-aparelho-com-mais-de-vinte-letras';
  const user = { _id: userId, pushTokens: [token, 'token-de-outro-aparelho-da-mesma-conta'] };
  const database = {
    collection: () => ({
      updateOne: async (filter, update) => {
        assert.equal(String(filter._id), String(userId));
        user.pushTokens = user.pushTokens.filter((t) => t !== update.$pull.pushTokens);
        return { matchedCount: 1 };
      },
    }),
  };

  const server = createApp(database).listen(0);
  t.after(() => new Promise((resolve) => server.close(resolve)));
  await new Promise((resolve) => server.once('listening', resolve));
  const url = `http://127.0.0.1:${server.address().port}/api/v1/auth/me/push-token`;
  const authorization = `Bearer ${jwt.sign({}, jwtSecret, { subject: String(userId), expiresIn: '1h' })}`;
  const apagar = (body, headers = { authorization }) =>
    fetch(url, {
      method: 'DELETE',
      headers: { ...headers, 'content-type': 'application/json' },
      body: JSON.stringify(body),
    });

  assert.equal((await apagar({ token })).status, 204);
  assert.deepEqual(user.pushTokens, ['token-de-outro-aparelho-da-mesma-conta']);

  assert.equal((await apagar({ token: 'curto' })).status, 400);
  assert.equal((await apagar({ token }, {})).status, 401);
});
