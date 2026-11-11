// Nome: Rodrigo Gabi - RA: 25001714
// Data: 11/11/2026
// Descrição: Gera a ação sugerida e as dicas extras de cada tipo de alerta (issue #12).

// Texto principal por tipo e nível de risco. O nível alto pede ação imediata.
const baseRecommendations = {
  geada: {
    medio: {
      acao: 'Prepare a proteção contra geada',
      detalhe: 'Separe lona ou plástico agrícola e acompanhe a previsão da madrugada.',
      dicas: ['Evite irrigar no fim do dia.', 'Mantenha o solo limpo e úmido pela manhã para reter calor.'],
    },
    alto: {
      acao: 'Proteja as plantas mais sensíveis',
      detalhe: 'Cubra as plantas com lona ou plástico agrícola antes da queda de temperatura.',
      dicas: [
        'Evite irrigar no fim do dia.',
        'Retire a cobertura quando a temperatura subir.',
        'Recolha mudas e vasos para locais protegidos.',
      ],
    },
  },
  seca: {
    medio: {
      acao: 'Economize e planeje a irrigação',
      detalhe: 'Priorize as áreas mais sensíveis e acompanhe a umidade do solo.',
      dicas: ['Irrigue nos horários mais frescos.', 'Verifique vazamentos no sistema.'],
    },
    alto: {
      acao: 'Irrigue as áreas prioritárias',
      detalhe: 'A falta de chuva já compromete a lavoura: concentre a água nas plantas mais sensíveis.',
      dicas: [
        'Irrigue nos horários mais frescos.',
        'Use cobertura morta (palha) para segurar a umidade do solo.',
        'Adie adubações, que exigem solo úmido.',
      ],
    },
  },
  chuvaForte: {
    medio: {
      acao: 'Prepare a drenagem da lavoura',
      detalhe: 'Desobstrua valetas e canais para facilitar o escoamento da água.',
      dicas: ['Evite aplicar insumos antes da chuva.', 'Observe as áreas mais baixas.'],
    },
    alto: {
      acao: 'Proteja a lavoura do excesso de água',
      detalhe: 'Desobstrua valetas e canais e retire equipamentos e insumos das áreas baixas.',
      dicas: [
        'Evite aplicar insumos antes da chuva.',
        'Não entre com máquinas no solo encharcado.',
        'Confira a erosão nas áreas inclinadas depois da chuva.',
      ],
    },
  },
};

// Dica extra conforme o estágio da lavoura, que muda o que está em risco.
const stageTips = {
  geada: {
    plantio: 'Mudas recém-plantadas são as mais sensíveis: priorize a cobertura delas.',
    floracao: 'As flores queimam com a geada: proteja primeiro as áreas em floração.',
  },
  seca: {
    plantio: 'Sem umidade a semente não germina: considere adiar o plantio.',
    floracao: 'Na floração a falta de água derruba flores e reduz a produção: priorize essas áreas.',
  },
  chuvaForte: {
    plantio: 'Chuva forte pode arrastar sementes e adubo: reforce curvas de nível.',
    colheita: 'Antecipe a colheita do que já estiver maduro para evitar perdas.',
  },
};

export function recommendationFor(tipo, nivel, context = {}) {
  const base = baseRecommendations[tipo]?.[nivel] ?? baseRecommendations[tipo]?.medio;
  if (!base) {
    throw new Error(`Não há recomendação para o tipo de alerta "${tipo}".`);
  }

  const dicas = [...base.dicas];
  const stageTip = context.estagio ? stageTips[tipo]?.[context.estagio] : undefined;
  if (stageTip) dicas.push(stageTip);

  let detalhe = base.detalhe;
  if (tipo === 'seca' && context.diasSemChuva) {
    detalhe = `São ${context.diasSemChuva} dias seguidos sem chuva relevante. ${detalhe}`;
  }

  return { acao: base.acao, detalhe, dicas };
}
