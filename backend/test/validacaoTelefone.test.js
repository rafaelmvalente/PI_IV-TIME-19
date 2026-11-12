// Nome: Caique Vasconcelos Naimi - RA: 25004208
// Data: 12/11/2026
// Descrição: Testa a validação de telefone pelo servidor Java (issue #73):
// com a saída do cliente Java simulada e, se houver Java na máquina, com o
// servidor de verdade.

import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync, spawn } from 'node:child_process';
import { mkdtempSync, readdirSync, rmSync } from 'node:fs';
import { connect } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

process.env.JWT_SECRET ??= 'test-secret-with-at-least-thirty-two-characters';
const { confirmarTelefone, validarNoServidorJava } = await import('../src/services/validacaoTelefone.js');

const config = { classpath: 'qualquer', host: 'localhost', porta: 3001 };
// Simula o execFile: devolve o stdout do cliente Java.
const javaRespondendo = (stdout, erro = null) => (_cmd, _args, _opts, callback) => callback(erro, stdout);

test('telefone válido passa', async () => {
  await confirmarTelefone('(19) 98765-4321', { config, run: javaRespondendo('VALIDO|Telefone valido\n') });
});

test('telefone inválido vira erro 400 com a mensagem do servidor Java', async () => {
  await assert.rejects(
    confirmarTelefone('(00) 98765-4321', {
      config,
      run: javaRespondendo('INVALIDO|DDD invalido\n', new Error('exit 1')),
    }),
    { status: 400, code: 'INVALID_PHONE', message: 'DDD invalido' },
  );
});

test('servidor Java fora do ar vira erro 503', async () => {
  await assert.rejects(
    confirmarTelefone('19987654321', { config, run: javaRespondendo('', new Error('exit 2')) }),
    { status: 503, code: 'PHONE_VALIDATOR_UNAVAILABLE' },
  );
});

test('sem o validador configurado, não chama o Java', async () => {
  await confirmarTelefone('qualquer coisa', {
    config: { ...config, classpath: undefined },
    run: () => assert.fail('não deveria chamar o Java'),
  });
});

function temJava() {
  try {
    execFileSync('javac', ['-version'], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

async function esperarPorta(porta) {
  for (let tentativa = 0; tentativa < 50; tentativa++) {
    const aberta = await new Promise((resolve) => {
      const socket = connect(porta, '127.0.0.1', () => {
        socket.destroy();
        resolve(true);
      });
      socket.on('error', () => resolve(false));
    });
    if (aberta) return;
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  throw new Error(`Servidor Java não abriu a porta ${porta}`);
}

test('com o servidor Java de verdade', { skip: !temJava() && 'Java não instalado' }, async (t) => {
  const raiz = fileURLToPath(new URL('../../servidor-java/', import.meta.url));
  const pasta = mkdtempSync(join(tmpdir(), 'climalerta-java-'));
  t.after(() => rmSync(pasta, { recursive: true, force: true }));
  for (const lado of ['Servidor', 'Cliente']) {
    const fontes = join(raiz, lado);
    const arquivos = readdirSync(fontes).filter((nome) => nome.endsWith('.java')).map((nome) => join(fontes, nome));
    execFileSync('javac', ['-encoding', 'UTF-8', '-d', join(pasta, lado), ...arquivos]);
  }

  const porta = 3100 + Math.floor(Math.random() * 800);
  // stdin fica aberto: o servidor espera o comando "desativar" pelo teclado.
  const servidor = spawn('java', ['-cp', join(pasta, 'Servidor'), 'Servidor', String(porta)], { stdio: 'pipe' });
  t.after(() => servidor.kill());
  await esperarPorta(porta);

  const real = { classpath: join(pasta, 'Cliente'), host: '127.0.0.1', porta };
  assert.deepEqual(await validarNoServidorJava('(19) 98765-4321', { config: real }), {
    valido: true,
    mensagem: 'Telefone valido',
  });
  await assert.rejects(confirmarTelefone('(00) 98765-4321', { config: real }), { status: 400, message: 'DDD invalido' });
  await assert.rejects(
    confirmarTelefone('19987654321', { config: { ...real, porta: porta + 1 } }),
    { status: 503 },
  );
});
