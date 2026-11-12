// Nome: Caio Ávila Marchi - RA: 25008101
// Data: 11/11/2026
// Descrição: Banco de dados falso, em memória, só para os testes. Imita o
// básico do driver do MongoDB (find, findOne, insertOne, updateOne), assim os
// testes não precisam de um MongoDB rodando.

function igual(a, b) {
  if (a instanceof Date && b instanceof Date) return a.getTime() === b.getTime();
  return String(a) === String(b);
}

function ehOperador(condicao) {
  return condicao !== null && typeof condicao === 'object' && !(condicao instanceof Date);
}

function confere(valor, condicao) {
  if (!ehOperador(condicao)) return igual(valor, condicao);
  return Object.entries(condicao).every(([operador, esperado]) => {
    if (operador === '$gt') return valor > esperado;
    if (operador === '$gte') return valor >= esperado;
    if (operador === '$in') return esperado.some((item) => igual(valor, item));
    throw new Error(`Operador não suportado no banco falso: ${operador}`);
  });
}

class ColecaoFalsa {
  constructor() {
    this.docs = [];
    this.proximoId = 1;
    // Os testes podem colocar um erro aqui para simular falha no insertOne.
    this.erroNoInsert = null;
  }

  filtrar(filtro = {}) {
    return this.docs.filter((doc) =>
      Object.entries(filtro).every(([campo, condicao]) => confere(doc[campo], condicao)),
    );
  }

  async findOne(filtro) {
    const achado = this.filtrar(filtro)[0];
    return achado ? { ...achado } : null;
  }

  find(filtro) {
    const achados = this.filtrar(filtro).map((doc) => ({ ...doc }));
    return {
      sort(ordem) {
        const [campo, sentido] = Object.entries(ordem)[0];
        achados.sort((a, b) => (a[campo] - b[campo]) * sentido);
        return this;
      },
      async toArray() {
        return achados;
      },
    };
  }

  async insertOne(doc) {
    if (this.erroNoInsert) throw this.erroNoInsert;
    const _id = doc._id ?? `id${this.proximoId++}`;
    this.docs.push({ ...doc, _id });
    return { insertedId: _id };
  }

  async updateOne(filtro, atualizacao, opcoes = {}) {
    const alvo = this.filtrar(filtro)[0];
    if (alvo) {
      Object.assign(alvo, atualizacao.$set);
      return { matchedCount: 1 };
    }
    if (!opcoes.upsert) return { matchedCount: 0 };
    const novo = {};
    for (const [campo, condicao] of Object.entries(filtro)) {
      if (!ehOperador(condicao)) novo[campo] = condicao;
    }
    this.docs.push({ ...novo, ...atualizacao.$set });
    return { matchedCount: 0, upsertedId: novo._id };
  }
}

export function criarBancoFalso() {
  const colecoes = new Map();
  return {
    collection(nome) {
      if (!colecoes.has(nome)) colecoes.set(nome, new ColecaoFalsa());
      return colecoes.get(nome);
    },
  };
}
