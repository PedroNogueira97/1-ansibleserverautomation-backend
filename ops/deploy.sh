#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting deploy..."

if [ ! -f docker-compose.prod.yml ] && [ ! -f docker-compose.yml ]; then
  echo "No docker compose file found."
  exit 1
fi

COMPOSE_FILE="docker-compose.yml"
if [ -f docker-compose.prod.yml ]; then
  COMPOSE_FILE="docker-compose.prod.yml"
fi

docker compose -f "$COMPOSE_FILE" pull || true
docker compose -f "$COMPOSE_FILE" up -d --build --remove-orphans

docker image prune -f || true

echo "==> Deploy finished."