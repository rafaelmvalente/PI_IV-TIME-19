// Nome: Rafael Mendes Valente - RA: 25002875
// Data: 11/11/2026
// Descrição: Consulta e normaliza a previsão do tempo fornecida pelo Open-Meteo.

import { env } from '../config/env.js';

// Converte códigos meteorológicos do provedor em descrições para o aplicativo.
const weatherCodeDescriptions = new Map([
  [0, 'Céu limpo'],
  [1, 'Predominantemente limpo'],
  [2, 'Parcialmente nublado'],
  [3, 'Nublado'],
  [45, 'Neblina'],
  [48, 'Neblina com geada'],
  [51, 'Garoa fraca'],
  [53, 'Garoa moderada'],
  [55, 'Garoa intensa'],
  [61, 'Chuva fraca'],
  [63, 'Chuva moderada'],
  [65, 'Chuva forte'],
  [71, 'Neve fraca'],
  [73, 'Neve moderada'],
  [75, 'Neve forte'],
  [80, 'Pancadas de chuva fracas'],
  [81, 'Pancadas de chuva moderadas'],
  [82, 'Pancadas de chuva fortes'],
  [95, 'Trovoadas'],
]);

export async function getForecast(latitude, longitude) {
  const url = new URL(env.weatherApiUrl);
  url.search = new URLSearchParams({
    latitude: String(latitude),
    longitude: String(longitude),
    current: 'temperature_2m,weather_code',
    daily: 'temperature_2m_max,temperature_2m_min,precipitation_sum',
    timezone: 'auto',
    forecast_days: '7',
  });

  let response;
  try {
    response = await fetch(url, { signal: AbortSignal.timeout(10_000) });
  } catch {
    throw Object.assign(new Error('O serviço de previsão do tempo está indisponível.'), {
      status: 502,
      code: 'WEATHER_PROVIDER_UNAVAILABLE',
    });
  }
  if (!response.ok) {
    throw Object.assign(new Error('Não foi possível consultar a previsão do tempo.'), {
      status: 502,
      code: 'WEATHER_PROVIDER_ERROR',
    });
  }

  let forecast;
  try {
    forecast = await response.json();
  } catch {
    throw Object.assign(new Error('O provedor retornou uma previsão inválida.'), {
      status: 502,
      code: 'INVALID_WEATHER_RESPONSE',
    });
  }
  const hasValidDailyForecast =
    Array.isArray(forecast.daily?.time) &&
    forecast.daily.time.length > 0 &&
    ['temperature_2m_max', 'temperature_2m_min', 'precipitation_sum'].every((key) =>
      Array.isArray(forecast.daily[key]) &&
      forecast.daily[key].length === forecast.daily.time.length &&
      forecast.daily[key].every((value) => Number.isFinite(value)),
    );
  if (!Number.isFinite(forecast.current?.temperature_2m) || !hasValidDailyForecast) {
    throw Object.assign(new Error('O provedor retornou uma previsão inválida.'), {
      status: 502,
      code: 'INVALID_WEATHER_RESPONSE',
    });
  }

  return {
    fetchedAt: new Date(),
    current: {
      temperatura: forecast.current.temperature_2m,
      descricao:
        weatherCodeDescriptions.get(forecast.current.weather_code) ??
        'Condição climática não identificada',
    },
    daily: forecast.daily.time.map((date, index) => ({
      date,
      maxima: forecast.daily.temperature_2m_max[index],
      minima: forecast.daily.temperature_2m_min[index],
      precipitation: forecast.daily.precipitation_sum[index],
    })),
  };
}

export function toTodayWeather(forecast) {
  const today = forecast.daily[0];
  return {
    temperatura: forecast.current.temperatura,
    maxima: today.maxima,
    minima: today.minima,
    descricao: forecast.current.descricao,
  };
}

// Chuva e temperatura observadas nos últimos dias, para guardar em leituras_clima
// e calcular a seca prolongada (issue #11). Hoje fica de fora: o dia ainda não terminou.
export async function getPastDays(latitude, longitude, days = 14) {
  const url = new URL(env.weatherApiUrl);
  url.search = new URLSearchParams({
    latitude: String(latitude),
    longitude: String(longitude),
    daily: 'temperature_2m_max,temperature_2m_min,precipitation_sum',
    timezone: 'auto',
    past_days: String(days),
    forecast_days: '1',
  });

  let response;
  try {
    response = await fetch(url, { signal: AbortSignal.timeout(10_000) });
  } catch {
    throw Object.assign(new Error('O serviço de previsão do tempo está indisponível.'), {
      status: 502,
      code: 'WEATHER_PROVIDER_UNAVAILABLE',
    });
  }
  if (!response.ok) {
    throw Object.assign(new Error('Não foi possível consultar o histórico do tempo.'), {
      status: 502,
      code: 'WEATHER_PROVIDER_ERROR',
    });
  }

  const data = await response.json();
  const time = data.daily?.time;
  if (!Array.isArray(time) || time.length < 2) return [];

  // O último dia da resposta é hoje (forecast_days = 1).
  return time.slice(0, -1).flatMap((date, index) => {
    const reading = {
      date,
      chuvaMm: data.daily.precipitation_sum?.[index],
      tempMin: data.daily.temperature_2m_min?.[index],
      tempMax: data.daily.temperature_2m_max?.[index],
    };
    return Number.isFinite(reading.chuvaMm) ? [reading] : [];
  });
}
