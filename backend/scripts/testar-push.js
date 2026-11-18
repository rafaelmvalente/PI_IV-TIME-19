// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 18/11/2026
// Descrição: Manda uma notificação de teste para os aparelhos de um produtor,
// para conferir o push (issues #72 e #31) sem esperar um alerta de verdade.
// Uso: node scripts/testar-push.js <e-mail ou telefone> [alertaId]
// Com o alertaId, tocar na notificação abre aquele alerta no app.

import { MongoClient } from 'mongodb';
import { env } from '../src/config/env.js';
import { firebaseConfigurado, sendPush } from '../src/services/push.js';

const [login, alertaId] = process.argv.slice(2);
if (!login) {
  console.error('Uso: node scripts/testar-push.js <e-mail ou telefone> [alertaId]');
  process.exit(1);
}
if (!firebaseConfigurado()) {
  console.error('Defina FIREBASE_SERVICE_ACCOUNT_BASE64 no .env antes de testar.');
  process.exit(1);
}

const client = new MongoClient(env.mongoUri);
try {
  await client.connect();
  const normalizado = login.includes('@') ? login.toLowerCase() : login;
  const usuario = await client
    .db(env.mongoDatabase)
    .collection('usuarios')
    .findOne({ $or: [{ email: normalizado }, { telefone: normalizado }] });
  if (!usuario) throw new Error('Usuário não encontrado.');

  const tokens = usuario.pushTokens ?? [];
  if (!tokens.length) {
    throw new Error('Esse usuário ainda não registrou nenhum aparelho. Entre no app com ele primeiro.');
  }

  const resultado = await sendPush(tokens, {
    notification: {
      title: 'ClimAlerta: teste',
      body: 'Se você está vendo isto, o push está funcionando.',
    },
    data: alertaId ? { alertaId } : {},
    android: { priority: 'high' },
  });
  console.log(`Aparelhos: ${tokens.length} | receberam: ${resultado.enviados} | falhas: ${resultado.falhas}`);
} catch (erro) {
  console.error(erro.message);
  process.exitCode = 1;
} finally {
  await client.close();
}
