// Nome: Caique Vasconcelos Naimi - RA: 25004208
// Data: 12/11/2026
// Descrição: Valida o telefone no servidor Java (servidor-java/, issue #73).
// O servidor troca objetos Java serializados (modelo do professor), que o Node
// não lê. Por isso o backend roda o cliente Java ValidaTelefone, que conversa
// com o servidor e imprime "VALIDO|mensagem" ou "INVALIDO|mensagem".

import { execFile } from 'node:child_process';
import { env } from '../config/env.js';

export function validadorConfigurado(config = env.validadorJava) {
  return Boolean(config?.classpath);
}

function indisponivel() {
  return Object.assign(new Error('O servidor de validação de telefone está indisponível. Tente novamente.'), {
    status: 503,
    code: 'PHONE_VALIDATOR_UNAVAILABLE',
  });
}

export function validarNoServidorJava(telefone, { config = env.validadorJava, run = execFile } = {}) {
  return new Promise((resolve, reject) => {
    run(
      'java',
      ['-cp', config.classpath, 'ValidaTelefone', config.host, String(config.porta), telefone],
      { timeout: 10_000 },
      // Telefone inválido sai com código 1 (vem como erro), mas com o Resultado no stdout.
      (_erro, stdout) => {
        const [status, mensagem] = String(stdout ?? '').trim().split('|');
        if (status === 'VALIDO' || status === 'INVALIDO') {
          resolve({ valido: status === 'VALIDO', mensagem });
        } else {
          reject(indisponivel());
        }
      },
    );
  });
}

// Recusa o telefone que o servidor Java considerar inválido. Sem o validador
// configurado (JAVA_VALIDADOR_CLASSPATH vazio), não faz nada.
export async function confirmarTelefone(telefone, opcoes = {}) {
  if (!validadorConfigurado(opcoes.config)) return;
  const { valido, mensagem } = await validarNoServidorJava(telefone, opcoes);
  if (!valido) {
    throw Object.assign(new Error(mensagem), { status: 400, code: 'INVALID_PHONE' });
  }
}
