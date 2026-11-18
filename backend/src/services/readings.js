// Nome: Rodrigo Gabi - RA: 25001714
// Data: 11/11/2026
// Descrição: Grava e consulta as leituras diárias de clima da propriedade (coleção leituras_clima).

import { inicioDoDia } from './alertas.js';
import { getPastDays } from './weather.js';

export const HISTORY_DAYS = 30;
const DAY_MS = 24 * 60 * 60 * 1000;

// Mesmo horário usado em previstoPara (12:00 UTC): um documento por dia.
export function dayToDate(day) {
  return new Date(`${day}T12:00:00.000Z`);
}

export async function saveReadings(database, propertyId, readings, fonte = 'open-meteo') {
  if (!readings.length) return 0;
  const now = new Date();
  const result = await database.collection('leituras_clima').bulkWrite(
    readings.map((reading) => ({
      updateOne: {
        filter: { propriedadeId: propertyId, data: dayToDate(reading.date) },
        update: {
          $set: {
            chuvaMm: reading.chuvaMm,
            ...(Number.isFinite(reading.tempMin) ? { tempMin: reading.tempMin } : {}),
            ...(Number.isFinite(reading.tempMax) ? { tempMax: reading.tempMax } : {}),
            fonte,
            atualizadoEm: now,
          },
        },
        upsert: true,
      },
    })),
    { ordered: false },
  );
  return result.upsertedCount + result.modifiedCount;
}

export function getReadings(database, propertyId, days = HISTORY_DAYS) {
  return database.collection('leituras_clima')
    .find({ propriedadeId: propertyId, data: { $gte: new Date(Date.now() - days * DAY_MS) } })
    .sort({ data: 1 })
    .toArray();
}

// Busca no provedor só quando falta a leitura de ontem, para não consultar a
// API a cada atualização de alertas. Se o provedor falhar, usa o que já está salvo.
// "Ontem" é calculado no fuso do produtor (#75): em UTC, depois das 21h de
// Brasília, "ontem" já seria o dia de hoje, que nunca é salvo, e a API seria
// consultada de novo a cada atualização. (agora: para os testes.)
export async function syncReadings(database, property, { fetchPastDays = getPastDays, logger = console, agora = new Date() } = {}) {
  const yesterday = new Date(inicioDoDia(agora).getTime() - DAY_MS).toISOString().slice(0, 10);
  const hasYesterday = await database.collection('leituras_clima').findOne(
    { propriedadeId: property._id, data: dayToDate(yesterday) },
    { projection: { _id: 1 } },
  );

  if (!hasYesterday) {
    try {
      const readings = await fetchPastDays(
        property.localizacao.latitude,
        property.localizacao.longitude,
      );
      await saveReadings(database, property._id, readings);
    } catch (error) {
      logger.warn(`Não foi possível atualizar as leituras da propriedade ${property._id}: ${error.message}`);
    }
  }

  return getReadings(database, property._id);
}
