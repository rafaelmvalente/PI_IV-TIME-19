// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Gera os alertas de uma propriedade e salva no banco, sem duplicar.
// - Reaproveita a previsão guardada por 3 horas (climaCache).
// - Nunca cria o mesmo alerta duas vezes (mesma propriedade, tipo e dia).
// - Nunca rebaixa o nível: se já existe um alerta "alto", ele continua "alto".
// - Informa quais alertas são novos ou subiram de nível, para o envio de push
//   avisar o produtor uma vez só (campo notificadoEm).
// - Usa o histórico de chuva (leituras_clima) na seca prolongada (#11).
// - Manda SMS dos alertas de nível alto para quem escolheu SMS (#16, #18).

import { generateRiskAlerts } from './risk.js';

const TRES_HORAS = 3 * 60 * 60_000;
const GRAVIDADE = { medio: 1, alto: 2 };
const FUSO_DO_PRODUTOR = 'America/Sao_Paulo';

// Meia-noite (UTC) do dia de hoje no Brasil. Os alertas são gravados às 12:00 UTC
// do dia previsto, então um filtro "a partir daqui" mantém o alerta de hoje
// na lista de próximos o dia inteiro.
export function inicioDoDia(agora = new Date()) {
  const dia = new Intl.DateTimeFormat('en-CA', { timeZone: FUSO_DO_PRODUTOR }).format(agora);
  return new Date(`${dia}T00:00:00.000Z`);
}

// O weather.js só é carregado na hora de consultar o clima. Assim, os testes
// (que passam uma previsão falsa) não dependem de .env nem de internet.
async function previsaoDoProvedor(latitude, longitude) {
  const { getForecast } = await import('./weather.js');
  return getForecast(latitude, longitude);
}

// Mesmo motivo: readings.js e notifications.js dependem do .env (clima e Twilio).
async function historicoDoProvedor(database, property) {
  const { syncReadings } = await import('./readings.js');
  return syncReadings(database, property);
}

async function notificarPorSms(database, property, alertas) {
  const { notifyCriticalAlerts } = await import('./notifications.js');
  return notifyCriticalAlerts(database, property, alertas);
}

async function buscarPrevisao(database, property, obterPrevisao) {
  const cache = database.collection('climaCache');
  // Reaproveita a previsão recente para limitar consultas ao provedor climático.
  const guardada = await cache.findOne({
    _id: property._id,
    atualizadoEm: { $gt: new Date(Date.now() - TRES_HORAS) },
  });
  if (guardada?.forecast) return guardada.forecast;

  const forecast = await obterPrevisao(
    property.localizacao.latitude,
    property.localizacao.longitude,
  );
  await cache.updateOne(
    { _id: property._id },
    { $set: { propriedadeId: property._id, forecast, atualizadoEm: new Date() } },
    { upsert: true },
  );
  return forecast;
}

async function buscarRegraDaCultura(database, property) {
  const regra = await database.collection('risco_cultura').findOne({
    cultura: property.cultivo,
    estagio: property.estagio ?? 'crescimento',
  });
  if (!regra) {
    throw Object.assign(
      new Error('Não há regra de risco cadastrada para a cultura e estágio desta propriedade.'),
      { status: 503, code: 'RISK_RULE_NOT_FOUND' },
    );
  }
  return regra;
}

// Salva um alerta que ainda não existe. Devolve o alerta salvo, ou null se
// outra execução criou o mesmo alerta ao mesmo tempo (índice único do banco).
async function salvarNovoAlerta(colecao, alerta) {
  const documento = { ...alerta, criadoEm: new Date(), notificadoEm: null };
  try {
    const { insertedId } = await colecao.insertOne({ ...documento });
    return { ...documento, _id: insertedId };
  } catch (erro) {
    if (erro?.code === 11000) return null;
    throw erro;
  }
}

// Gera os alertas e devolve:
//   alertas  -> todos os alertas da propriedade, do mais próximo ao mais distante
//   novos    -> alertas criados agora
//   elevados -> alertas que já existiam e subiram de nível (ex.: médio -> alto)
export async function gerarAlertas(database, property, {
  obterPrevisao = previsaoDoProvedor,
  obterHistorico = historicoDoProvedor,
  notificar = notificarPorSms,
} = {}) {
  const forecast = await buscarPrevisao(database, property, obterPrevisao);
  const regra = await buscarRegraDaCultura(database, property);
  const historico = await obterHistorico(database, property);
  const gerados = generateRiskAlerts(property, forecast, regra, { historico });

  const colecao = database.collection('alertas');
  const chave = (alerta) => `${alerta.tipo}|${new Date(alerta.previstoPara).getTime()}`;

  const existentes = new Map();
  if (gerados.length) {
    const achados = await colecao
      .find({
        propriedadeId: property._id,
        previstoPara: { $in: gerados.map((alerta) => alerta.previstoPara) },
      })
      .toArray();
    for (const alerta of achados) existentes.set(chave(alerta), alerta);
  }

  const novos = [];
  const elevados = [];

  for (const alerta of gerados) {
    const atual = existentes.get(chave(alerta));

    if (!atual) {
      const salvo = await salvarNovoAlerta(colecao, alerta);
      if (salvo) novos.push(salvo);
      continue;
    }

    const gravidadeNova = GRAVIDADE[alerta.nivel] ?? 0;
    const gravidadeAtual = GRAVIDADE[atual.nivel] ?? 0;
    // Priorizar o mais grave: uma previsão mais branda não rebaixa o alerta.
    if (gravidadeNova < gravidadeAtual) continue;

    const subiu = gravidadeNova > gravidadeAtual;
    const campos = {
      nivel: alerta.nivel,
      descricao: alerta.descricao,
      recomendacao: alerta.recomendacao,
      atualizadoEm: alerta.atualizadoEm,
    };
    // Ao subir de nível, o produtor precisa ser avisado de novo.
    if (subiu) campos.notificadoEm = null;

    // O status (ação realizada, resolvido) é do produtor: não mexemos nele.
    await colecao.updateOne({ _id: atual._id }, { $set: campos });
    if (subiu) elevados.push({ ...atual, ...campos });
  }

  // SMS dos alertas críticos. Falha no envio não impede a resposta com os alertas.
  try {
    await notificar(database, property, gerados.filter((alerta) => alerta.nivel === 'alto'));
  } catch (erro) {
    console.error(`Falha ao notificar os alertas da propriedade ${property._id}:`, erro);
  }

  const alertas = await colecao
    .find({ propriedadeId: property._id })
    .sort({ previstoPara: 1 })
    .toArray();

  return { alertas, novos, elevados };
}

// Mesmo nome e mesmo retorno de antes (lista de alertas da propriedade),
// para as rotas atuais continuarem funcionando sem mudança.
export async function refreshAlerts(database, property, opcoes) {
  const { alertas } = await gerarAlertas(database, property, opcoes);
  return alertas;
}
