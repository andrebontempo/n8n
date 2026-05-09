#!/bin/bash
# ==============================
# 📦 Criação da stack n8n-000
# ==============================

# 1️⃣ Cria diretório base
mkdir -p /opt/docker/n8n-000/data/{n8n,postgres,qdrant,waha}
cd /opt/docker/n8n-000

# 2️⃣ Cria arquivo .env
cat << 'EOF' > .env
POSTGRES_USER=bontech
POSTGRES_PASSWORD=SenhaSegura123
POSTGRES_DB=n8n_db
POSTGRES_LOG_DB=logs_db

N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=SenhaMuitoForte!
N8N_HOST=n8n000.bontech.com.br
WEBHOOK_URL=https://n8n000.bontech.com.br/

QDRANT_PORT=6333

WAHA_WEBHOOK_URL=https://n8n000.bontech.com.br/webhook/waha
WAHA_API_PORT=3000
EOF

# 3️⃣ Cria docker-compose.yml
cat << 'EOF' > docker-compose.yml
version: "3.8"

services:
  # =====================
  # PostgreSQL (compartilhado)
  # =====================
  postgres:
    image: postgres:16
    container_name: postgres-n8n000
    restart: always
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    networks:
      - proxy
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # =====================
  # Qdrant (IA, embeddings, vetores)
  # =====================
  qdrant:
    image: qdrant/qdrant:latest
    container_name: qdrant-n8n000
    restart: always
    volumes:
      - ./data/qdrant:/qdrant/storage
    networks:
      - proxy
    ports:
      - "${QDRANT_PORT}:6333"

  # =====================
  # n8n principal
  # =====================
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n-000
    restart: always
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=${N8N_BASIC_AUTH_ACTIVE}
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - N8N_HOST=${N8N_HOST}
      - WEBHOOK_URL=${WEBHOOK_URL}
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - EXECUTIONS_PROCESS=main
    volumes:
      - ./data/n8n:/home/node/.n8n
    networks:
      - proxy
    depends_on:
      - postgres
      - qdrant

  # =====================
  # WAHA (WhatsApp HTTP API)
  # =====================
  waha:
    image: devlikeapro/waha:latest
    container_name: waha-n8n000
    restart: always
    environment:
      - WAHA_API_PORT=${WAHA_API_PORT}
      - WAHA_LOG_LEVEL=info
      - WAHA_WEBHOOK_URL=${WAHA_WEBHOOK_URL}
      - WAHA_POSTGRES_HOST=postgres
      - WAHA_POSTGRES_USER=${POSTGRES_USER}
      - WAHA_POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - WAHA_POSTGRES_DB=${POSTGRES_LOG_DB}
    ports:
      - "3000:3000"
    networks:
      - proxy
    depends_on:
      - postgres

networks:
  proxy:
    external: true
EOF

# 4️⃣ Sobe o stack
docker compose up -d

# 5️⃣ Mostra status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "✅ Stack n8n-000 criada com sucesso!"
echo "Acesse: https://n8n000.bontech.com.br (após configurar proxy no Nginx Proxy Manager)"
