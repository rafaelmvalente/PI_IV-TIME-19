// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Gera, consulta e atualiza alertas climáticos das propriedades.

import { Router } from 'express';
import { ObjectId } from 'mongodb';
import { z } from 'zod';
import { authenticate } from '../middleware/authenticate.js';
import { generateRiskAlerts } from '../services/risk.js';
import { getForecast } from '../services/weather.js';

const router = Router();
const statuses = ['emAndamento', 'acaoRealizada', 'resolvido'];
const types = ['geada', 'seca', 'chuvaForte'];

export async function refreshAlerts(database, property) {
  const cacheCollection = database.collection('climaCache');
  // Reaproveita a previsão recente para limitar consultas ao provedor climático.
  const cached = await cacheCollection.findOne({
    _id: property._id,
    atualizadoEm: { $gt: new Date(Date.now() - 3 * 60 * 60_000) },
  });
  const forecast = cached?.forecast ?? await getForecast(
    property.localizacao.latitude,
    property.localizacao.longitude,
  );
  if (!cached) {
    await cacheCollection.updateOne(
      { _id: property._id },
      { $set: { propriedadeId: property._id, forecast, atualizadoEm: new Date() } },
      { upsert: true },
    );
  }

  const rule = await database.collection('risco_cultura').findOne({
    cultura: property.cultivo,
    estagio: property.estagio ?? 'crescimento',
  });
  if (!rule) {
    throw Object.assign(
      new Error('Não há regra de risco cadastrada para a cultura e estágio desta propriedade.'),
      { status: 503, code: 'RISK_RULE_NOT_FOUND' },
    );
  }

  const alerts = generateRiskAlerts(property, forecast, rule);
  const collection = database.collection('alertas');
  for (const alert of alerts) {
    await collection.updateOne(
      {
        propriedadeId: property._id,
        tipo: alert.tipo,
        previstoPara: alert.previstoPara,
      },
      {
        $setOnInsert: { ...alert, criadoEm: new Date() },
        $set: {
          nivel: alert.nivel,
          descricao: alert.descricao,
          recomendacao: alert.recomendacao,
          atualizadoEm: alert.atualizadoEm,
        },
      },
      { upsert: true },
    );
  }

  return collection
    .find({ propriedadeId: property._id })
    .sort({ previstoPara: 1 })
    .toArray();
}

export function serializeAlert(alert) {
  return {
    id: String(alert._id),
    propriedadeId: String(alert.propriedadeId),
    tipo: alert.tipo,
    nivel: alert.nivel,
    previstoPara: alert.previstoPara.toISOString(),
    descricao: alert.descricao,
    status: alert.status,
    recomendacao: alert.recomendacao,
  };
}

router.use(authenticate);

router.get('/', async (req, res) => {
  const query = z
    .object({
      propriedadeId: z.string().refine(ObjectId.isValid),
      periodo: z.enum(['proximos', 'historico']).default('proximos'),
      tipo: z.enum(types).optional(),
    })
    .parse(req.query);

  const propertyId = new ObjectId(query.propriedadeId);
  const property = await req.db.collection('propriedades').findOne({
    _id: propertyId,
    usuarioId: req.userId,
  });
  if (!property) {
    return res.status(404).json({ error: { code: 'PROPERTY_NOT_FOUND', message: 'Propriedade não encontrada.' } });
  }

  if (query.periodo === 'proximos') await refreshAlerts(req.db, property);
  const filter = { propriedadeId: propertyId };
  if (query.tipo) filter.tipo = query.tipo;
  filter.previstoPara = query.periodo === 'historico' ? { $lt: new Date() } : { $gte: new Date() };
  const alerts = await req.db.collection('alertas')
    .find(filter)
    .sort({ previstoPara: query.periodo === 'historico' ? -1 : 1 })
    .toArray();
  return res.json(alerts.map(serializeAlert));
});

router.patch('/:id/status', async (req, res) => {
  if (!ObjectId.isValid(req.params.id)) {
    return res.status(404).json({ error: { code: 'ALERT_NOT_FOUND', message: 'Alerta não encontrado.' } });
  }
  const { status } = z.object({ status: z.enum(statuses) }).parse(req.body);
  const collection = req.db.collection('alertas');
  const alert = await collection.findOne({ _id: new ObjectId(req.params.id) });
  if (!alert) {
    return res.status(404).json({ error: { code: 'ALERT_NOT_FOUND', message: 'Alerta não encontrado.' } });
  }
  const property = await req.db.collection('propriedades').findOne({
    _id: alert.propriedadeId,
    usuarioId: req.userId,
  });
  if (!property) {
    return res.status(404).json({ error: { code: 'ALERT_NOT_FOUND', message: 'Alerta não encontrado.' } });
  }

  await collection.updateOne(
    { _id: alert._id },
    { $set: { status, atualizadoEm: new Date() } },
  );
  return res.json(serializeAlert({ ...alert, status }));
});

export default router;
