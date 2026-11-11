// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Cria, consulta, edita e remove propriedades do usuário autenticado.

import { Router } from 'express';
import { ObjectId } from 'mongodb';
import { z } from 'zod';
import { authenticate } from '../middleware/authenticate.js';
import { getForecast, toTodayWeather } from '../services/weather.js';
import { refreshAlerts, serializeAlert } from './alerts.js';

const router = Router();
const crops = ['milho', 'feijao', 'soja', 'cafe', 'hortalicas', 'frutas', 'outro'];
const stages = ['plantio', 'crescimento', 'floracao', 'colheita'];

const propertySchema = z.object({
  nome: z.string().trim().min(2).max(100),
  cultivo: z.enum(crops),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  areaHectares: z.number().positive().max(1_000_000).optional(),
  estagio: z.enum(stages).optional(),
});
const propertyPatchSchema = propertySchema.partial().extend({
  areaHectares: z.number().positive().max(1_000_000).nullable().optional(),
  estagio: z.enum(stages).nullable().optional(),
});

function serializeProperty(property) {
  return {
    id: String(property._id),
    nome: property.nome,
    cultivo: property.cultivo,
    latitude: property.localizacao.latitude,
    longitude: property.localizacao.longitude,
    areaHectares: property.areaHectares ?? null,
    estagio: property.estagio ?? null,
  };
}

async function findOwnedProperty(req, res) {
  // Restringe a busca às propriedades pertencentes ao usuário autenticado.
  if (!ObjectId.isValid(req.params.id)) {
    res.status(404).json({ error: { code: 'PROPERTY_NOT_FOUND', message: 'Propriedade não encontrada.' } });
    return null;
  }
  const property = await req.db.collection('propriedades').findOne({
    _id: new ObjectId(req.params.id),
    usuarioId: req.userId,
  });
  if (!property) {
    res.status(404).json({ error: { code: 'PROPERTY_NOT_FOUND', message: 'Propriedade não encontrada.' } });
    return null;
  }
  return property;
}

async function getPropertyForecast(database, property) {
  const cacheCollection = database.collection('climaCache');
  const cached = await cacheCollection.findOne({
    _id: property._id,
    atualizadoEm: { $gt: new Date(Date.now() - 3 * 60 * 60_000) },
  });
  if (cached) return cached.forecast;

  const forecast = await getForecast(
    property.localizacao.latitude,
    property.localizacao.longitude,
  );
  await cacheCollection.updateOne(
    { _id: property._id },
    { $set: { propriedadeId: property._id, forecast, atualizadoEm: new Date() } },
    { upsert: true },
  );
  return forecast;
}

router.use(authenticate);

router.get('/', async (req, res) => {
  const properties = await req.db.collection('propriedades')
    .find({ usuarioId: req.userId })
    .sort({ criadoEm: 1 })
    .toArray();
  return res.json(properties.map(serializeProperty));
});

router.post('/', async (req, res) => {
  const body = propertySchema.parse(req.body);
  const property = {
    usuarioId: req.userId,
    nome: body.nome,
    cultivo: body.cultivo,
    localizacao: { latitude: body.latitude, longitude: body.longitude },
    ...(body.areaHectares === undefined ? {} : { areaHectares: body.areaHectares }),
    ...(body.estagio === undefined ? {} : { estagio: body.estagio }),
    criadoEm: new Date(),
    atualizadoEm: new Date(),
  };
  const result = await req.db.collection('propriedades').insertOne(property);
  return res.status(201).json(serializeProperty({ ...property, _id: result.insertedId }));
});

router.patch('/:id', async (req, res) => {
  const property = await findOwnedProperty(req, res);
  if (!property) return;
  const body = propertyPatchSchema.parse(req.body);
  const updated = {
    ...property,
    nome: body.nome ?? property.nome,
    cultivo: body.cultivo ?? property.cultivo,
    localizacao: {
      latitude: body.latitude ?? property.localizacao.latitude,
      longitude: body.longitude ?? property.localizacao.longitude,
    },
    atualizadoEm: new Date(),
  };
  if (Object.hasOwn(body, 'areaHectares')) {
    if (body.areaHectares == null) delete updated.areaHectares;
    else updated.areaHectares = body.areaHectares;
  }
  if (Object.hasOwn(body, 'estagio')) {
    if (body.estagio == null) delete updated.estagio;
    else updated.estagio = body.estagio;
  }

  await req.db.collection('propriedades').replaceOne({ _id: property._id }, updated);
  if (body.latitude !== undefined || body.longitude !== undefined) {
    // Descarta a previsão armazenada quando a localização é alterada.
    await req.db.collection('climaCache').deleteOne({ _id: property._id });
  }
  return res.json(serializeProperty(updated));
});

router.delete('/:id', async (req, res) => {
  const property = await findOwnedProperty(req, res);
  if (!property) return;
  await Promise.all([
    req.db.collection('propriedades').deleteOne({ _id: property._id }),
    req.db.collection('alertas').deleteMany({ propriedadeId: property._id }),
    req.db.collection('climaCache').deleteOne({ _id: property._id }),
  ]);
  return res.status(204).end();
});

router.get('/:id/weather/forecast', async (req, res) => {
  const property = await findOwnedProperty(req, res);
  if (!property) return;
  const forecast = await getPropertyForecast(req.db, property);
  return res.json(forecast);
});

router.get('/:id/weather/today', async (req, res) => {
  const property = await findOwnedProperty(req, res);
  if (!property) return;
  const forecast = await getPropertyForecast(req.db, property);
  return res.json(toTodayWeather(forecast));
});

router.post('/:id/alerts/refresh', async (req, res) => {
  const property = await findOwnedProperty(req, res);
  if (!property) return;
  const alerts = await refreshAlerts(req.db, property);
  return res.json(alerts.map(serializeAlert));
});

export default router;
