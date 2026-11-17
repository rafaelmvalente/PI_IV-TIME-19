// Caique Vasconcelos Naimi - 25004208
// Data: 17/11/2026
// Descrição: Cria alertas de demonstração para a apresentação, caso o clima do
// dia não gere nenhum alerta de verdade. Grava uma geada (alto) para hoje e uma
// chuva forte (médio) para amanhã nas propriedades da conta informada, no mesmo
// formato das regras de risco. Os alertas ficam marcados com demo: true.
//
// Criar:   npm run demo:alerta -- email@exemplo.com
// Remover: npm run demo:alerta -- email@exemplo.com --remover

import { pathToFileURL } from 'node:url';
import { inicioDoDia } from '../src/services/alertas.js';
import { recommendationFor } from '../src/services/recommendations.js';

const UM_DIA = 24 * 60 * 60_000;

async function propriedadesDaConta(database, login) {
  const usuarios = database.collection('usuarios');
  const usuario = login.includes('@')
    ? await usuarios.findOne({ email: login.toLowerCase() })
    : await usuarios.findOne({ telefone: login });
  if (!usuario) throw new Error(`Nenhuma conta encontrada com "${login}".`);

  const propriedades = await database.collection('propriedades')
    .find({ usuarioId: usuario._id })
    .toArray();
  if (!propriedades.length) throw new Error(`A conta "${login}" ainda não tem propriedade cadastrada.`);
  return propriedades;
}

function alertasDe(propriedade, agora) {
  // Mesmo horário das regras (12:00 UTC do dia), para aparecer em "próximos".
  const hoje = new Date(inicioDoDia(agora).getTime() + 12 * 60 * 60_000);
  const amanha = new Date(hoje.getTime() + UM_DIA);
  const contexto = { estagio: propriedade.estagio };

  return [
    {
      tipo: 'geada',
      nivel: 'alto',
      previstoPara: hoje,
      descricao: 'A temperatura mínima prevista é de 0°C.',
      recomendacao: recommendationFor('geada', 'alto', contexto),
    },
    {
      tipo: 'chuvaForte',
      nivel: 'medio',
      previstoPara: amanha,
      descricao: 'A previsão indica 62 mm de chuva no dia.',
      recomendacao: recommendationFor('chuvaForte', 'medio', contexto),
    },
  ];
}

export async function criarAlertasDemo(database, login, agora = new Date()) {
  const propriedades = await propriedadesDaConta(database, login);
  let total = 0;

  for (const propriedade of propriedades) {
    for (const alerta of alertasDe(propriedade, agora)) {
      // upsert pela mesma chave do índice único: rodar de novo não duplica.
      await database.collection('alertas').updateOne(
        { propriedadeId: propriedade._id, tipo: alerta.tipo, previstoPara: alerta.previstoPara },
        {
          $set: {
            ...alerta,
            status: 'emAndamento',
            demo: true,
            criadoEm: agora,
            atualizadoEm: agora,
            notificadoEm: null,
          },
        },
        { upsert: true },
      );
      total++;
    }
  }
  return total;
}

export async function removerAlertasDemo(database, login) {
  const propriedades = await propriedadesDaConta(database, login);
  const { deletedCount } = await database.collection('alertas').deleteMany({
    demo: true,
    propriedadeId: { $in: propriedades.map((propriedade) => propriedade._id) },
  });
  return deletedCount;
}

async function main() {
  const [login, opcao] = process.argv.slice(2);
  if (!login) {
    console.error('Uso: npm run demo:alerta -- <e-mail ou telefone da conta> [--remover]');
    process.exitCode = 1;
    return;
  }

  const { connectDatabase, closeDatabase } = await import('../src/config/database.js');
  const database = await connectDatabase();
  try {
    if (opcao === '--remover') {
      const removidos = await removerAlertasDemo(database, login);
      console.log(`${removidos} alerta(s) de demonstração removido(s).`);
    } else {
      const criados = await criarAlertasDemo(database, login);
      console.log(`${criados} alerta(s) de demonstração prontos. Abra o app e atualize os alertas.`);
    }
  } catch (erro) {
    console.error(erro.message);
    process.exitCode = 1;
  } finally {
    await closeDatabase();
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) await main();
