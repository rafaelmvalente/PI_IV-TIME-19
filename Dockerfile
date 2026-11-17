# Nome: Vinicius Santuci Virgolino - RA: 25000294
# Data: 17/11/2026
# Descrição: Monta o backend Node e o servidor Java de validação de telefone
# no mesmo serviço, para publicar no Render (issue #64). Ao ligar, sobe o
# servidor Java na porta 3001 (interna) e depois o backend na porta pública.

# 1) Compila o servidor Java e o cliente ValidaTelefone, que o backend executa.
FROM eclipse-temurin:21-jdk AS java
WORKDIR /java
COPY servidor-java/ ./
RUN javac Servidor/*.java && javac Cliente/*.java

# 2) Imagem final: Node com o Java (só o necessário para rodar, sem o javac).
FROM node:22-slim
COPY --from=eclipse-temurin:21-jre /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

WORKDIR /app/backend
COPY backend/package.json backend/package-lock.json ./
RUN npm ci --omit=dev
COPY backend/ ./
COPY --from=java /java /app/servidor-java

# O backend encontra o servidor Java por aqui. O plano gratuito do Render tem
# 512 MB, por isso cada Java fica limitado a 64 MB.
ENV NODE_ENV=production
ENV JAVA_VALIDADOR_CLASSPATH=/app/servidor-java/Cliente
ENV JAVA_VALIDADOR_HOST=127.0.0.1
ENV JAVA_VALIDADOR_PORTA=3001
ENV JAVA_TOOL_OPTIONS="-Xmx64m -XX:+UseSerialGC"

# O Servidor.java fica esperando o comando "desativar" pelo teclado. No Render
# não há teclado: o "tail -f /dev/null" é uma entrada que nunca termina, então
# o servidor fica esperando para sempre. Depois, o backend sobe.
CMD ["sh", "-c", "tail -f /dev/null | java -cp /app/servidor-java/Servidor Servidor 3001 & exec node src/server.js"]
