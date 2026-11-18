# ClimAlerta — Alertas Climáticos Hiperlocais para Pequenos Produtores Rurais

## Sobre o projeto

O ClimAlerta é uma aplicação que avisa pequenos produtores rurais sobre riscos climáticos para a sua lavoura antes que eles aconteçam.

O sistema cruza dados meteorológicos públicos (Open-Meteo) com a localização da propriedade, a cultura plantada e o estágio da lavoura, e transforma a previsão do tempo em um alerta simples, acompanhado de uma recomendação prática.

Em vez de apenas informar a temperatura, o sistema avisa o risco real e o que fazer. Exemplo:

> Risco de geada (alto) — amanhã, 06:00. Cubra as plantas mais sensíveis com lonas ou plástico agrícola.

Os alertas chegam por notificação, em texto ou voz e, quando a propriedade está sem internet estável, os alertas críticos chegam por SMS. Cada alerta fica registrado em um histórico, com o status do que foi feito.

## Equipe

| Nome | RA |
|------|----|
| Caio Ávila Marchi | 25008101 |
| Caique Vasconcelos Naimi | 25004208 |
| Rafael Mendes Valente | 25002875 |
| Rodrigo Gabi | 25001714 |
| Vinicius Santuci Virgolino | 25000294 |

## Funcionalidades

### Conta e propriedade

- Cadastro e login do produtor, com recuperação de senha
- Cadastro da propriedade com nome, tipo de cultivo, tamanho da área (opcional) e localização, por GPS automático ou informada manualmente
- Edição dos dados da propriedade e das preferências de recebimento de alertas

### Alertas de risco climático

- Coleta automática da previsão do tempo para a localização de cada propriedade
- Detecção de três tipos de evento: geada, seca prolongada e chuva forte
- Classificação do alerta por nível de risco (Médio, Alto), conforme a cultura e o estágio da lavoura (plantio, crescimento, floração, colheita)
- Prevenção de alertas duplicados, priorizando o mais grave

### Recomendações práticas

- Cada alerta vem com uma ação sugerida e dicas extras (ex.: "proteja as mudas", "adie a irrigação")
- Linguagem simples, sem jargão técnico

### Canais de alerta

- Notificação push no aplicativo
- Texto e voz: o produtor escolhe receber o alerta escrito e/ou em áudio
- Modo offline / SMS: sem internet estável, os alertas críticos chegam por SMS

### Histórico e acompanhamento

- Lista de alertas recebidos, agrupada por mês
- Status de cada alerta: Em andamento, Ação realizada e Resolvido
- Filtro de alertas por tipo: Todos, Geada, Seca e Chuva

### Dashboard

A tela inicial apresenta:

- Clima de hoje da propriedade
- Alerta em destaque
- Próximos alertas previstos

## Status acompanhados

| Status | Descrição |
|--------|-----------|
| Em andamento | Alerta recebido e situação ainda em curso |
| Ação realizada | Produtor executou a ação recomendada |
| Resolvido | Risco encerrado |

## Tecnologias utilizadas

- Aplicativo (cliente): Flutter (Dart)
- Backend: Node.js (API REST)
- Servidor: Java 21 puro, com threads e sockets (validação de telefone, em `servidor-java/`)
- Banco de dados: MongoDB (usuários, propriedades, alertas, tabela de risco por cultura, cache do clima e leituras diárias de chuva)
- Testes automatizados: JUnit 5, Mockito
- Integrações: Open-Meteo (clima), Firebase Cloud Messaging (push)
- Controle de versão: Git, GitHub e GitHub Projects
- Hospedagem: Render (backend e servidor Java, com Docker) e MongoDB Atlas (banco)

## Preparar o banco de dados

Os scripts ficam em `banco-de-dados/` e rodam no `mongosh` (ou na aba MongoSH do Compass), com um usuário que tenha permissão de administrador do banco. Podem rodar mais de uma vez. A ordem é:

1. `validadores.js`: regras de validação de `usuarios`, `propriedades`, `alertas` e `climaCache`
2. `indices.js`: índices das consultas e expiração do cache
3. `risco_cultura.js`: tabela de risco por cultura e estágio da lavoura

## Backend publicado

O backend e o servidor Java estão no ar no Render, ligados ao banco no MongoDB Atlas:

- API: `https://pi-iv-time-19.onrender.com/api/v1`
- Conferir se está no ar: [`/api/v1/health`](https://pi-iv-time-19.onrender.com/api/v1/health) responde `{"status":"ok"}`

Para abrir o app usando o backend publicado (sem precisar rodar o backend no computador):

```
cd app
flutter run -d chrome --dart-define=API_URL=https://pi-iv-time-19.onrender.com/api/v1
```

Como funciona a publicação:

- O `Dockerfile` (na raiz) monta o Node e o Java no mesmo serviço: compila o `servidor-java/`, sobe o servidor Java na porta 3001 (interna) e depois o backend na porta pública
- As senhas ficam nas variáveis de ambiente do Render, fora do Git: `MONGODB_URI`, `MONGODB_DATABASE`, `JWT_SECRET`, `CORS_ORIGIN` e `COLETA_INTERVALO_MINUTOS`
- O plano gratuito do Render desliga o serviço depois de 15 minutos sem acesso. Uma tarefa no cron-job.org acessa o `/api/v1/health` a cada 10 minutos para mantê-lo ligado e a coleta agendada rodando
- **O Render não atualiza sozinho:** depois de um merge no `main` que mexa no backend ou no servidor Java, é preciso entrar no Render e clicar em **Manual Deploy → Deploy latest commit**
