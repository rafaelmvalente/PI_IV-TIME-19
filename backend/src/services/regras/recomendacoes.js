// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Textos de recomendação de cada tipo de alerta, em linguagem
// simples para o produtor. Ficam aqui para as regras não precisarem conhecê-los.

export const recomendacoes = {
  geada: {
    acao: 'Proteja as plantas mais sensíveis',
    detalhe: 'Cubra as plantas com lona ou plástico agrícola antes da queda de temperatura.',
    dicas: ['Evite irrigar no fim do dia.', 'Retire a cobertura quando a temperatura subir.'],
  },
  seca: {
    acao: 'Economize e planeje a irrigação',
    detalhe: 'Priorize as áreas mais sensíveis e acompanhe a umidade do solo.',
    dicas: ['Irrigue nos horários mais frescos.', 'Verifique vazamentos no sistema.'],
  },
  chuvaForte: {
    acao: 'Prepare a drenagem da lavoura',
    detalhe: 'Desobstrua valetas e canais para facilitar o escoamento da água.',
    dicas: ['Evite aplicar insumos antes da chuva.', 'Observe as áreas mais baixas.'],
  },
};
