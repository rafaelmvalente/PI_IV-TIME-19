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
- Integrações: Open-Meteo (clima), Firebase Cloud Messaging (push), Twilio (SMS) e SMTP (e-mail de recuperação de senha)
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
- As senhas ficam nas variáveis de ambiente do Render, fora do Git: `MONGODB_URI`, `MONGODB_DATABASE`, `JWT_SECRET`, `CORS_ORIGIN` e `COLETA_INTERVALO_MINUTOS`. Os recursos opcionais só funcionam com as suas variáveis: recuperação de senha (`SMTP_*` e `APP_RESET_PASSWORD_URL`), push (`FIREBASE_SERVICE_ACCOUNT_BASE64`) e SMS (`TWILIO_*`)
- O plano gratuito do Render desliga o serviço depois de 15 minutos sem acesso. Uma tarefa no cron-job.org acessa o `/api/v1/health` a cada 10 minutos para mantê-lo ligado e a coleta agendada rodando
- **O Render não atualiza sozinho:** depois de um merge no `main` que mexa no backend ou no servidor Java, é preciso entrar no Render e clicar em **Manual Deploy → Deploy latest commit**

## Rodar no computador

### Backend (Node.js)

Precisa do Node.js 20 ou mais novo e de um MongoDB (local ou Atlas) com os scripts de `banco-de-dados/` já rodados.

```
cd backend
cp .env.example .env    # preencha MONGODB_URI e JWT_SECRET (mínimo 32 caracteres)
npm install
npm run dev             # API em http://localhost:3000/api/v1
```

Sem as variáveis de SMTP, Firebase, Twilio ou do servidor Java, o backend sobe normalmente e só o recurso correspondente fica desligado. A recuperação de senha responde 503 até o SMTP ser configurado (com Gmail: `smtp.gmail.com`, porta 587 e uma senha de app).

### Servidor Java (validação de telefone)

Precisa do Java 21. O servidor usa a porta 3001.

```
cd servidor-java/Servidor && javac *.java && java Servidor
cd servidor-java/Cliente && javac *.java && java Cliente
```

O `Cliente` é interativo e serve para testar. O backend usa o `ValidaTelefone` (`java ValidaTelefone localhost 3001 "(19) 99999-8888"`) quando `JAVA_VALIDADOR_CLASSPATH` está preenchido no `.env`. Para desligar o servidor, digite `desativar` no terminal dele.

### Aplicativo (Flutter)

```
cd app
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api/v1
```

No emulador Android, use `http://10.0.2.2:3000/api/v1`. O push só funciona no celular e precisa também de `--dart-define` com `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID` e `FIREBASE_PROJECT_ID`; sem eles, o app roda sem notificações.

### Testes

```
cd backend && npm test
cd app && flutter test
```

Os testes do backend usam um banco falso em memória e não precisam de MongoDB nem de internet.

### Alerta de demonstração

Para a apresentação, quando o clima do dia não gera nenhum alerta, o script cria uma geada (alto) para hoje e uma chuva forte (médio) para amanhã nas propriedades da conta:

```
cd backend
npm run demo:alerta -- email-da-conta@exemplo.com
npm run demo:alerta -- email-da-conta@exemplo.com --remover
```
